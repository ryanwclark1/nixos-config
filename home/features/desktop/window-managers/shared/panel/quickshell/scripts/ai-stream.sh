# ai-stream.sh — Streaming curl wrapper for AI providers
# Usage: qs-ai-stream <provider> <model> <endpoint> <api-key> <messages-file> [max-tokens] [temperature] [image-path] [timeout]
# Output protocol: CONTENT:<text>, ERROR:<message>, USAGE:<json>, DONE

set -euo pipefail

PROVIDER="${1:-}"
MODEL="${2:-}"
ENDPOINT="${3:-}"
API_KEY="${4:-}"
MESSAGES_FILE="${5:-}"
MAX_TOKENS="${6:-4096}"
TEMPERATURE="${7:-0.7}"
IMAGE_PATH="${8:-}"
TIMEOUT="${9:-120}"

# Base64 image data if provided
IMAGE_B64=""
if [[ -n "$IMAGE_PATH" && -f "$IMAGE_PATH" ]]; then
    IMAGE_B64=$(base64 -w0 "$IMAGE_PATH")
fi

cleanup() {
    rm -f "$MESSAGES_FILE" 2>/dev/null || true
}
trap cleanup EXIT
trap 'exit 0' TERM INT

if [[ -z "$PROVIDER" || -z "$MESSAGES_FILE" ]]; then
    echo "ERROR:Missing required arguments"
    echo "DONE"
    exit 1
fi

if [[ ! -f "$MESSAGES_FILE" ]]; then
    echo "ERROR:Messages file not found: $MESSAGES_FILE"
    echo "DONE"
    exit 1
fi

MESSAGES=$(cat "$MESSAGES_FILE")

case "$PROVIDER" in
    ollama)
        ENDPOINT="${ENDPOINT:-http://localhost:11434}"
        URL="${ENDPOINT}/api/chat"

        if [[ -n "$IMAGE_B64" ]]; then
            # Add images array to the last user message
            MESSAGES=$(echo "$MESSAGES" | jq --arg b64 "$IMAGE_B64" '
                # Find the index of the last user message
                (map(.role == "user") | to_entries | last | .key) as $last_idx |
                .[$last_idx].images = [$b64]
            ')
        fi

        BODY=$(jq -n \
            --arg model "$MODEL" \
            --argjson messages "$MESSAGES" \
            --argjson max_tokens "$MAX_TOKENS" \
            --argjson temperature "$TEMPERATURE" \
            '{model: $model, messages: $messages, stream: true, options: {num_predict: $max_tokens, temperature: $temperature}}')

        curl -s --connect-timeout 5 --max-time "$TIMEOUT" --no-buffer -X POST "$URL" \
            -H "Content-Type: application/json" \
            -d "$BODY" 2>/dev/null | while IFS= read -r line || [[ -n "$line" ]]; do
            line="${line%$'\r'}"
            [[ -z "$line" ]] && continue

            # Ollama NDJSON: each line is a JSON object with .message.content
            content=$(echo "$line" | jq -r '.message.content // empty' 2>/dev/null)
            if [[ -n "$content" ]]; then
                echo "CONTENT:$content"
            fi

            # Check if done — extract usage from final message
            done_flag=$(echo "$line" | jq -r '.done // false' 2>/dev/null)
            if [[ "$done_flag" == "true" ]]; then
                prompt_tokens=$(echo "$line" | jq -r '.prompt_eval_count // 0' 2>/dev/null)
                completion_tokens=$(echo "$line" | jq -r '.eval_count // 0' 2>/dev/null)
                if [[ "$prompt_tokens" != "0" || "$completion_tokens" != "0" ]]; then
                    echo "USAGE:{\"prompt\":$prompt_tokens,\"completion\":$completion_tokens}"
                fi
                break
            fi

            # Check for error
            error=$(echo "$line" | jq -r '.error // empty' 2>/dev/null)
            if [[ -n "$error" ]]; then
                echo "ERROR:$error"
                break
            fi
        done
        ;;

    anthropic)
        ENDPOINT="${ENDPOINT:-https://api.anthropic.com}"
        URL="${ENDPOINT}/v1/messages"

        # Convert simple message list to Anthropic format (with image in last user message)
        if [[ -n "$IMAGE_B64" ]]; then
            CHAT_MSGS=$(echo "$MESSAGES" | jq --arg b64 "$IMAGE_B64" '
                # Filter out system messages
                [.[] | select(.role != "system")] |
                # Find the index of the last user message in the filtered list
                (map(.role == "user") | to_entries | last | .key) as $last_idx |
                # For each message, convert content to array of parts
                map(
                    if .role == "user" and (.[ "content" ] != null) and (to_entries | any(.key == "role" and .value == "user")) then
                        # If this is the last user message, add the image block
                        if (index(.) == $last_idx) then
                            .content = [
                                {type: "text", text: .content},
                                {type: "image", source: {type: "base64", media_type: "image/png", data: $b64}}
                            ]
                        else
                            .content = [{type: "text", text: .content}]
                        end
                    else
                        .content = [{type: "text", text: .content}]
                    end
                )
            ')
        else
            CHAT_MSGS=$(echo "$MESSAGES" | jq '[.[] | select(.role != "system")]')
        fi

        SYSTEM_MSG=$(echo "$MESSAGES" | jq -r '[.[] | select(.role == "system")] | map(.content) | join("\n")' 2>/dev/null)

        BODY=$(jq -n \
            --arg model "$MODEL" \
            --argjson messages "$CHAT_MSGS" \
            --argjson max_tokens "$MAX_TOKENS" \
            --argjson temperature "$TEMPERATURE" \
            --arg system "$SYSTEM_MSG" \
            'if $system != "" then
                {model: $model, messages: $messages, max_tokens: $max_tokens, temperature: $temperature, stream: true, system: $system}
            else
                {model: $model, messages: $messages, max_tokens: $max_tokens, temperature: $temperature, stream: true}
            end')

        curl -s --connect-timeout 5 --max-time "$TIMEOUT" --no-buffer -X POST "$URL" \
            -H "Content-Type: application/json" \
            -H "x-api-key: $API_KEY" \
            -H "anthropic-version: 2023-06-01" \
            -d "$BODY" 2>/dev/null | while IFS= read -r line || [[ -n "$line" ]]; do
            line="${line%$'\r'}"
            # SSE format: lines starting with "data: "
            if [[ "$line" == data:* ]]; then
                data="${line#data: }"
                [[ "$data" == "[DONE]" ]] && break
                [[ -z "$data" ]] && continue

                event_type=$(echo "$data" | jq -r '.type // empty' 2>/dev/null)
                case "$event_type" in
                    content_block_delta)
                        content=$(echo "$data" | jq -r '.delta.text // empty' 2>/dev/null)
                        [[ -n "$content" ]] && echo "CONTENT:$content"
                        ;;
                    message_delta)
                        # Anthropic sends usage in message_delta at end of stream
                        output_tokens=$(echo "$data" | jq -r '.usage.output_tokens // 0' 2>/dev/null)
                        if [[ "$output_tokens" != "0" ]]; then
                            echo "USAGE:{\"completion\":$output_tokens}"
                        fi
                        ;;
                    message_start)
                        # Input tokens in message_start
                        input_tokens=$(echo "$data" | jq -r '.message.usage.input_tokens // 0' 2>/dev/null)
                        if [[ "$input_tokens" != "0" ]]; then
                            echo "USAGE:{\"prompt\":$input_tokens}"
                        fi
                        ;;
                    error)
                        error=$(echo "$data" | jq -r '.error.message // "Unknown error"' 2>/dev/null)
                        echo "ERROR:$error"
                        break
                        ;;
                esac
            fi
        done
        ;;

    openai|custom)
        if [[ "$PROVIDER" == "openai" ]]; then
            ENDPOINT="${ENDPOINT:-https://api.openai.com}"
        fi
        URL="${ENDPOINT}/v1/chat/completions"

        if [[ -n "$IMAGE_B64" ]]; then
            MESSAGES=$(echo "$MESSAGES" | jq --arg b64 "$IMAGE_B64" '
                (map(.role == "user") | to_entries | last | .key) as $last_idx |
                .[$last_idx].content = [
                    {type: "text", text: .[$last_idx].content},
                    {type: "image_url", image_url: {url: ("data:image/png;base64," + $b64)}}
                ]
            ')
        fi

        BODY=$(jq -n \
            --arg model "$MODEL" \
            --argjson messages "$MESSAGES" \
            --argjson max_tokens "$MAX_TOKENS" \
            --argjson temperature "$TEMPERATURE" \
            '{model: $model, messages: $messages, max_completion_tokens: $max_tokens, temperature: $temperature, stream: true, stream_options: {include_usage: true}}')

        curl -s --connect-timeout 5 --max-time "$TIMEOUT" --no-buffer -X POST "$URL" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $API_KEY" \
            -d "$BODY" 2>/dev/null | while IFS= read -r line || [[ -n "$line" ]]; do
            line="${line%$'\r'}"
            if [[ "$line" == data:* ]]; then
                data="${line#data: }"
                [[ "$data" == "[DONE]" ]] && break
                [[ -z "$data" ]] && continue

                content=$(echo "$data" | jq -r '.choices[0].delta.content // empty' 2>/dev/null)
                [[ -n "$content" ]] && echo "CONTENT:$content"

                # OpenAI sends usage in the final chunk when stream_options.include_usage is true
                prompt_tokens=$(echo "$data" | jq -r '.usage.prompt_tokens // empty' 2>/dev/null)
                completion_tokens=$(echo "$data" | jq -r '.usage.completion_tokens // empty' 2>/dev/null)
                if [[ -n "$prompt_tokens" && -n "$completion_tokens" ]]; then
                    echo "USAGE:{\"prompt\":$prompt_tokens,\"completion\":$completion_tokens}"
                fi

                # Check for error in response
                error=$(echo "$data" | jq -r '.error.message // empty' 2>/dev/null)
                if [[ -n "$error" ]]; then
                    echo "ERROR:$error"
                    break
                fi
            fi
        done
        ;;

    gemini)
        ENDPOINT="${ENDPOINT:-https://generativelanguage.googleapis.com}"
        URL="${ENDPOINT}/v1beta/models/${MODEL}:streamGenerateContent?alt=sse&key=${API_KEY}"

        # Convert messages to Gemini format
        SYSTEM_MSG=$(echo "$MESSAGES" | jq -r '[.[] | select(.role == "system")] | map(.content) | join("\n")' 2>/dev/null)
        GEMINI_CONTENTS=$(echo "$MESSAGES" | jq '[.[] | select(.role != "system") | {role: (if .role == "assistant" then "model" else .role end), parts: [{text: .content}]}]' 2>/dev/null)

        if [[ -n "$IMAGE_B64" ]]; then
            GEMINI_CONTENTS=$(echo "$GEMINI_CONTENTS" | jq --arg b64 "$IMAGE_B64" '
                (length - 1) as $last_idx |
                .[$last_idx].parts += [{inline_data: {mime_type: "image/png", data: $b64}}]
            ')
        fi

        BODY=$(jq -n \
            --argjson contents "$GEMINI_CONTENTS" \
            --argjson max_tokens "$MAX_TOKENS" \
            --argjson temperature "$TEMPERATURE" \
            --arg system "$SYSTEM_MSG" \
            'if $system != "" then
                {contents: $contents, generationConfig: {maxOutputTokens: $max_tokens, temperature: $temperature}, systemInstruction: {parts: [{text: $system}]}}
            else
                {contents: $contents, generationConfig: {maxOutputTokens: $max_tokens, temperature: $temperature}}
            end')

        curl -s --connect-timeout 5 --max-time "$TIMEOUT" --no-buffer -X POST "$URL" \
            -H "Content-Type: application/json" \
            -d "$BODY" 2>/dev/null | while IFS= read -r line || [[ -n "$line" ]]; do
            line="${line%$'\r'}"
            if [[ "$line" == data:* ]]; then
                data="${line#data: }"
                [[ -z "$data" ]] && continue

                content=$(echo "$data" | jq -r '.candidates[0].content.parts[0].text // empty' 2>/dev/null)
                [[ -n "$content" ]] && echo "CONTENT:$content"

                # Gemini usage metadata
                prompt_tokens=$(echo "$data" | jq -r '.usageMetadata.promptTokenCount // empty' 2>/dev/null)
                completion_tokens=$(echo "$data" | jq -r '.usageMetadata.candidatesTokenCount // empty' 2>/dev/null)
                if [[ -n "$prompt_tokens" && -n "$completion_tokens" ]]; then
                    echo "USAGE:{\"prompt\":$prompt_tokens,\"completion\":$completion_tokens}"
                fi

                # Check for error
                error=$(echo "$data" | jq -r '.error.message // empty' 2>/dev/null)
                if [[ -n "$error" ]]; then
                    echo "ERROR:$error"
                    break
                fi
            fi
        done
        ;;

    *)
        echo "ERROR:Unknown provider: $PROVIDER"
        ;;
esac

echo "DONE"
