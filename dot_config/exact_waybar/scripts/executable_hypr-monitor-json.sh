#!/usr/bin/env bash
hyprctl monitors -j | jq -c '
{
  text: (
    .[] | select(.focused==true)
    | "\(.name) [\(.activeWorkspace.name // (.activeWorkspace.id|tostring))]"
  ),
  tooltip: (
    [ .[] |
      "\(.id) \(.name) \(.description)\(if .focused then " *" else "" end)"
    ] | join("\n")
  )
}'
