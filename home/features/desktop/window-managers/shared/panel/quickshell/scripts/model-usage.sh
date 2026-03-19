#!/usr/bin/env bash
# qs-model-usage — reads local Claude Code / Codex CLI data files, outputs JSON
# Usage: qs-model-usage claude | qs-model-usage codex
set -euo pipefail

provider="${1:-claude}"
today=$(date +%Y-%m-%d)

# ── Helpers ──────────────────────────────────────────────────────
json_fallback='{"error":"no data"}'

format_tokens() {
  local n="$1"
  if [ "$n" -ge 1000000000 ]; then
    printf "%.1fB" "$(echo "$n / 1000000000" | bc -l)"
  elif [ "$n" -ge 1000000 ]; then
    printf "%.1fM" "$(echo "$n / 1000000" | bc -l)"
  elif [ "$n" -ge 1000 ]; then
    printf "%.1fK" "$(echo "$n / 1000" | bc -l)"
  else
    printf "%d" "$n"
  fi
}

# ── Claude ───────────────────────────────────────────────────────
if [ "$provider" = "claude" ]; then
  stats_file="$HOME/.claude/stats-cache.json"
  if [ ! -f "$stats_file" ]; then
    echo "$json_fallback"
    exit 0
  fi

  # Live counts from history.jsonl (stats-cache may be stale)
  history_file="$HOME/.claude/history.jsonl"
  live_today=0
  live_recent='[]'
  if [ -f "$history_file" ]; then
    today_start=$(date -d "$today 00:00:00" +%s)000
    today_end=$(date -d "$today 23:59:59" +%s)999
    seven_days_ago=$(date -d "$today -6 days" +%s)000

    live_data=$(tail -c 3000000 "$history_file" | tail -n +2 \
      | jq -s --argjson ts "$today_start" --argjson te "$today_end" --argjson week "$seven_days_ago" '
        {
          today: [.[] | select(.timestamp >= $ts and .timestamp <= $te)] | length,
          recent: [.[] | select(.timestamp >= $week) |
            { date: (.timestamp / 1000 | strftime("%Y-%m-%d")) }
          ] | group_by(.date) | map({date: .[0].date, messageCount: length})
        }' 2>/dev/null || echo '{"today":0,"recent":[]}')

    live_today=$(echo "$live_data" | jq -r '.today // 0')
    live_recent=$(echo "$live_data" | jq -c '.recent // []')
    live_today="${live_today:-0}"
  fi

  jq --arg today "$today" --argjson liveToday "$live_today" --argjson liveRecent "$live_recent" '
    # Today stats from dailyActivity
    (.dailyActivity // []) as $daily |
    ($daily | map(select(.date == $today)) | first // {messageCount:0, sessionCount:0, toolCallCount:0}) as $todayStats |

    # Today tokens by model from dailyModelTokens
    (.dailyModelTokens // []) as $dmt |
    ($dmt | map(select(.date == $today)) | first // {tokensByModel:{}}) as $todayTokens |

    # Recent 7 days: merge cached + live, take max per date
    ($daily | sort_by(.date) | reverse | .[0:7] | reverse) as $cachedDays |
    ([$cachedDays[], $liveRecent[]] | group_by(.date) |
      map({date: .[0].date, messageCount: [.[].messageCount] | max}) |
      sort_by(.date) | .[-7:]
    ) as $recentDays |

    # All-time model usage
    (.modelUsage // {}) as $modelUsage |

    # Compute total tokens across all models
    ([$modelUsage | to_entries[] | .value.inputTokens + .value.outputTokens] | add // 0) as $totalTokens |

    # Use whichever today count is higher (live vs cached)
    ([($todayStats.messageCount // 0), $liveToday] | max) as $todayPrompts |

    {
      todayPrompts: $todayPrompts,
      todaySessions: ($todayStats.sessionCount // 0),
      todayToolCalls: ($todayStats.toolCallCount // 0),
      todayTokensByModel: ($todayTokens.tokensByModel // {}),
      totalPrompts: (.totalMessages // 0),
      totalSessions: (.totalSessions // 0),
      totalTokens: $totalTokens,
      modelUsage: $modelUsage,
      recentDays: [$recentDays[] | {date: .date, messageCount: .messageCount}],
      firstSessionDate: (.firstSessionDate // ""),
      version: (.version // 0)
    }
  ' "$stats_file" 2>/dev/null || echo "$json_fallback"

# ── Claude rate limit probe ──────────────────────────────────────
elif [ "$provider" = "claude-rate-limit" ]; then
  creds_file="$HOME/.claude/.credentials.json"
  if [ ! -f "$creds_file" ]; then
    echo '{"available":false,"reason":"no credentials"}'
    exit 0
  fi

  token=$(jq -r '.claudeAiOauth.accessToken // empty' "$creds_file" 2>/dev/null || true)
  if [ -z "$token" ]; then
    echo '{"available":false,"reason":"no token"}'
    exit 0
  fi

  # Check token expiry
  expires_at=$(jq -r '.claudeAiOauth.expiresAt // "0"' "$creds_file" 2>/dev/null || echo "0")
  now_ms=$(date +%s%3N 2>/dev/null || echo "0")
  if [ "$expires_at" != "0" ] && [ "$now_ms" -gt "$expires_at" ] 2>/dev/null; then
    echo '{"available":false,"reason":"token expired"}'
    exit 0
  fi

  # Probe the rate limit API
  response=$(curl -s --max-time 10 \
    -H "Authorization: Bearer $token" \
    -H "Content-Type: application/json" \
    "https://api.anthropic.com/api/oauth/usage" 2>/dev/null || echo "")

  if [ -z "$response" ] || ! echo "$response" | jq empty 2>/dev/null; then
    echo '{"available":false,"reason":"api error"}'
    exit 0
  fi

  # Only mark available if there's no error field
  if echo "$response" | jq -e '.error' >/dev/null 2>&1; then
    echo "$response" | jq '{available: false, reason: "api_error"} + .'
  else
    echo "$response" | jq '{available: true} + .'
  fi

# ── Codex ────────────────────────────────────────────────────────
elif [ "$provider" = "codex" ]; then
  codex_dir="$HOME/.codex"

  # Check if codex history exists
  history_file="$codex_dir/history.jsonl"
  if [ ! -f "$history_file" ]; then
    echo "$json_fallback"
    exit 0
  fi

  # Count today's entries from history.jsonl (Codex uses Unix seconds in .ts)
  today_start_sec=$(date -d "$today 00:00:00" +%s)
  today_end_sec=$(date -d "$today 23:59:59" +%s)
  today_count=$(tail -c 3000000 "$history_file" | tail -n +2 \
    | jq -s "[.[] | select(.ts >= $today_start_sec and .ts <= $today_end_sec)] | length" 2>/dev/null || echo "0")
  today_count="${today_count:-0}"

  # Try to read latest session for token info
  sessions_dir="$codex_dir/sessions"
  latest_tokens='{"inputTokens":0,"outputTokens":0,"model":"unknown"}'
  if [ -d "$sessions_dir" ]; then
    latest_session=$(ls -t "$sessions_dir"/*.json 2>/dev/null | head -1 || true)
    if [ -n "$latest_session" ] && [ -f "$latest_session" ]; then
      latest_tokens=$(jq '{
        inputTokens: (.usage.input_tokens // 0),
        outputTokens: (.usage.output_tokens // 0),
        model: (.model // "unknown")
      }' "$latest_session" 2>/dev/null || echo '{"inputTokens":0,"outputTokens":0,"model":"unknown"}')
    fi
  fi

  # Read config for model info
  config_file="$codex_dir/config.toml"
  model="unknown"
  if [ -f "$config_file" ]; then
    model=$(grep -oP 'model\s*=\s*"\K[^"]+' "$config_file" 2>/dev/null || echo "unknown")
  fi

  jq -n --argjson todayCount "$today_count" \
        --argjson tokens "$latest_tokens" \
        --arg model "$model" \
    '{
      todayPrompts: $todayCount,
      todaySessions: 0,
      model: $model,
      latestSession: $tokens
    }'
else
  echo '{"error":"unknown provider: '"$provider"'"}'
  exit 1
fi
