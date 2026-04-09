#!/usr/bin/env bash
# qs-model-usage — reads local Claude Code / Codex CLI / Gemini CLI data files, outputs JSON
# Usage: qs-model-usage claude | qs-model-usage codex | qs-model-usage gemini
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

find_latest_jsonl_matching() {
  local root="$1"
  local jq_expr="$2"
  if [ ! -d "$root" ]; then
    return 0
  fi

  find "$root" -type f -name '*.jsonl' -printf '%T@ %p\n' 2>/dev/null \
    | sort -nr \
    | head -n 40 \
    | while read -r _ path; do
        if jq -e "$jq_expr" "$path" >/dev/null 2>&1; then
          printf '%s\n' "$path"
          break
        fi
      done
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
  seven_days_ago_sec=$(date -d "$today -6 days" +%s)

  codex_data=$(tail -c 3000000 "$history_file" | tail -n +2 \
    | jq -s --argjson ts "$today_start_sec" --argjson te "$today_end_sec" --argjson week "$seven_days_ago_sec" '
      {
        today: [.[] | select(.ts >= $ts and .ts <= $te)] | length,
        recent: [.[] | select(.ts >= $week) |
          { date: (.ts | strftime("%Y-%m-%d")) }
        ] | group_by(.date) | map({date: .[0].date, messageCount: length}) | sort_by(.date) | .[-7:]
      }' 2>/dev/null || echo '{"today":0,"recent":[]}')

  today_count=$(echo "$codex_data" | jq -r '.today // 0')
  today_count="${today_count:-0}"
  codex_recent=$(echo "$codex_data" | jq -c '.recent // []')

  # Read config for model info
  config_file="$codex_dir/config.toml"
  model="unknown"
  if [ -f "$config_file" ]; then
    model=$(grep -oP 'model\s*=\s*"\K[^"]+' "$config_file" 2>/dev/null || echo "unknown")
  fi

  sessions_dir="$codex_dir/sessions"
  latest_token_event='{}'
  latest_token_file=""
  if [ -d "$sessions_dir" ]; then
    latest_token_file=$(find_latest_jsonl_matching "$sessions_dir" 'select(.type == "event_msg" and .payload.type == "token_count")' || true)
    if [ -n "$latest_token_file" ] && [ -f "$latest_token_file" ]; then
      latest_token_event=$(jq -sc '
        map(select(.type == "event_msg" and .payload.type == "token_count")) | last | .payload // {}
      ' "$latest_token_file" 2>/dev/null || echo '{}')
    fi
  fi

  if [ -z "${latest_token_event:-}" ] || [ "$latest_token_event" = "null" ]; then
    latest_token_event='{}'
  fi

  jq -n --argjson todayCount "$today_count" \
        --argjson tokenEvent "$latest_token_event" \
        --arg model "$model" \
        --argjson recentDays "$codex_recent" \
    '{
      todayPrompts: $todayCount,
      todaySessions: 0,
      model: $model,
      recentDays: $recentDays,
      latestSession: {
        inputTokens: ($tokenEvent.info.last_token_usage.input_tokens // 0),
        cachedInputTokens: ($tokenEvent.info.last_token_usage.cached_input_tokens // 0),
        outputTokens: ($tokenEvent.info.last_token_usage.output_tokens // 0),
        reasoningTokens: ($tokenEvent.info.last_token_usage.reasoning_output_tokens // 0),
        totalTokens: ($tokenEvent.info.last_token_usage.total_tokens // 0),
        model: $model
      },
      totalUsage: {
        inputTokens: ($tokenEvent.info.total_token_usage.input_tokens // 0),
        cachedInputTokens: ($tokenEvent.info.total_token_usage.cached_input_tokens // 0),
        outputTokens: ($tokenEvent.info.total_token_usage.output_tokens // 0),
        reasoningTokens: ($tokenEvent.info.total_token_usage.reasoning_output_tokens // 0),
        totalTokens: ($tokenEvent.info.total_token_usage.total_tokens // 0)
      },
      rateLimits: {
        primary: {
          available: ($tokenEvent.rate_limits.primary != null),
          usedPercent: ($tokenEvent.rate_limits.primary.used_percent // -1),
          windowMinutes: ($tokenEvent.rate_limits.primary.window_minutes // 0),
          resetsAt: ($tokenEvent.rate_limits.primary.resets_at // 0)
        },
        secondary: {
          available: ($tokenEvent.rate_limits.secondary != null),
          usedPercent: ($tokenEvent.rate_limits.secondary.used_percent // -1),
          windowMinutes: ($tokenEvent.rate_limits.secondary.window_minutes // 0),
          resetsAt: ($tokenEvent.rate_limits.secondary.resets_at // 0)
        },
        credits: ($tokenEvent.rate_limits.credits // null),
        planType: ($tokenEvent.rate_limits.plan_type // "")
      }
    }'
# ── Gemini ───────────────────────────────────────────────────────
elif [ "$provider" = "gemini" ]; then
  gemini_dir="$HOME/.gemini/tmp"

  if [ ! -d "$gemini_dir" ]; then
    echo "$json_fallback"
    exit 0
  fi

  # Growth guard: cap at 300 chat session files.
  session_files=$(find "$gemini_dir" -path '*/chats/session-*.json' -type f 2>/dev/null | tail -300)
  if [ -z "$session_files" ]; then
    echo "$json_fallback"
    exit 0
  fi

  # Date threshold for 7-day window (ISO prefix comparison)
  seven_days_ago=$(date -d "$today -6 days" +%Y-%m-%d)
  last_24h_iso=$(date -u -d '24 hours ago' +"%Y-%m-%dT%H:%M:%SZ")

  # Extract lightweight metadata per file (skip content to avoid malformed Unicode)
  # Each file → one JSON line with date, user count, gemini tokens, model
  # Use xargs -P for parallel extraction across files
  jq_filter='select(.startTime != null and (.startTime[:10] >= $ws)) |
    {
      date: .startTime[:10],
      startTime: .startTime,
      userCount: [.messages[]? | select(.type == "user")] | length,
      geminiMsgs: [.messages[]? | select(.type == "gemini" and .tokens != null) |
        { model: (.model // "unknown"), input: (.tokens.input // 0),
          output: (.tokens.output // 0), cached: (.tokens.cached // 0),
          thoughts: (.tokens.thoughts // 0), total: (.tokens.total // 0) }]
    }'
  extracted=$(echo "$session_files" | xargs -P4 -I{} jq -c --arg ws "$seven_days_ago" "$jq_filter" {} 2>/dev/null || true)

  if [ -z "$extracted" ]; then
    echo "$json_fallback"
    exit 0
  fi

  echo "$extracted" | jq -s --arg today "$today" --arg day24 "$last_24h_iso" '
    # Today sessions
    [.[] | select(.date == $today)] as $todaySessions |
    ([$todaySessions[].userCount] | add // 0) as $todayPrompts |
    [$todaySessions[].geminiMsgs[]?] as $todayGmMsgs |
    {
      input: ([$todayGmMsgs[].input] | add // 0),
      output: ([$todayGmMsgs[].output] | add // 0),
      cached: ([$todayGmMsgs[].cached] | add // 0),
      thoughts: ([$todayGmMsgs[].thoughts] | add // 0)
    } as $todayTokens |

    # Last 24 hours
    [.[] | select(.startTime >= $day24)] as $last24hSessions |
    [$last24hSessions[].geminiMsgs[]?] as $last24hMsgs |
    ($last24hMsgs | group_by(.model) | map({
      key: .[0].model,
      value: {
        input: ([.[].input] | add // 0),
        output: ([.[].output] | add // 0),
        cached: ([.[].cached] | add // 0),
        thoughts: ([.[].thoughts] | add // 0),
        total: ([.[].total] | add // 0)
      }
    }) | from_entries) as $last24hTokensByModel |

    # Recent days
    (group_by(.date) | map({
      date: .[0].date,
      messageCount: ([.[].userCount] | add // 0)
    }) | sort_by(.date) | .[-7:]) as $recentDays |

    # All gemini messages
    [.[].geminiMsgs[]?] as $allGm |
    ([$allGm[].total] | add // 0) as $totalTokens |

    # Per-model breakdown
    ($allGm | group_by(.model) | map({
      key: .[0].model,
      value: { input: ([.[].input] | add), output: ([.[].output] | add) }
    }) | from_entries) as $tokensByModel |

    ($tokensByModel | to_entries | sort_by(.value.input + .value.output) | reverse |
      .[0].key // "unknown") as $model |

    {
      todayPrompts: $todayPrompts,
      todaySessions: ($todaySessions | length),
      todayTokens: $todayTokens,
      last24hPrompts: ([$last24hSessions[].userCount] | add // 0),
      last24hSessions: ($last24hSessions | length),
      last24hTokensByModel: $last24hTokensByModel,
      totalSessions: length,
      totalTokens: $totalTokens,
      model: $model,
      recentDays: $recentDays,
      tokensByModel: $tokensByModel
    }
  ' 2>/dev/null || echo "$json_fallback"

else
  echo '{"error":"unknown provider: '"$provider"'"}'
  exit 1
fi
