#!/usr/bin/env bash
# ai-prompt.sh - Query local Ollama for the launcher

PROMPT="$1"
MODEL="devstral-small-2" # From ollama.json

if [[ -z "$PROMPT" ]]; then
    exit 0
fi

# Use curl to talk to Ollama API
# We use the /v1/chat/completions endpoint for better compatibility
curl -s http://localhost:11434/v1/chat/completions \
    -H "Content-Type: application/json" \
    -d "$(jq -n --arg model "$MODEL" --arg prompt "$PROMPT" '{
        model: $model,
        messages: [{role: "user", content: $prompt}],
        stream: false
    }')" | jq -r '.choices[0].message.content'
