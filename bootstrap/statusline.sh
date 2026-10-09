#!/bin/bash
input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name // .model.id // "Unknown"')
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
branch=""
if [ -n "$cwd" ]; then
  branch=$(git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null)
fi
five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_resets=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
week_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
week_resets=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')
ctx_used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

parts="$model"

if [ -n "$branch" ]; then
  parts="$parts | $branch"
fi

if [ -n "$five_pct" ]; then
  session_str="S: $(printf '%.0f' "$five_pct")%"
  if [ -n "$five_resets" ]; then
    now=$(date +%s)
    diff=$(( five_resets - now ))
    if [ "$diff" -gt 0 ]; then
      mins=$(( diff / 60 ))
      hrs=$(( mins / 60 ))
      remaining_mins=$(( mins % 60 ))
      if [ "$hrs" -gt 0 ]; then
        session_str="$session_str (${hrs}h${remaining_mins}m)"
      else
        session_str="$session_str (${remaining_mins}m)"
      fi
    fi
  fi
  parts="$parts | $session_str"
fi

if [ -n "$week_pct" ]; then
  week_str="W: $(printf '%.0f' "$week_pct")%"
  if [ -n "$week_resets" ]; then
    now=$(date +%s)
    diff=$(( week_resets - now ))
    if [ "$diff" -gt 0 ]; then
      mins=$(( diff / 60 ))
      hrs=$(( mins / 60 ))
      remaining_mins=$(( mins % 60 ))
      days=$(( hrs / 24 ))
      remaining_hrs=$(( hrs % 24 ))
      if [ "$days" -gt 0 ]; then
        week_str="$week_str (${days}d${remaining_hrs}h)"
      elif [ "$hrs" -gt 0 ]; then
        week_str="$week_str (${hrs}h${remaining_mins}m)"
      else
        week_str="$week_str (${remaining_mins}m)"
      fi
    fi
  fi
  parts="$parts | $week_str"
fi

if [ -n "$ctx_used" ]; then
  parts="$parts | C: $(printf '%.0f' "$ctx_used")%"
fi

echo "$parts"
