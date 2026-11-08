#!/usr/bin/env bash
set -euo pipefail

herdr="${HERDR_BIN_PATH:-herdr}"
# Shell keybindings capture this ID when invoked; never resolve focus again.
pane="${HERDR_ACTIVE_PANE_ID:-}"
if [[ -z $pane ]]; then
  echo "herdr-smart-quit: no target pane; refusing to close" >&2
  exit 1
fi

if ! process_info=$("$herdr" pane process-info --pane "$pane"); then
  echo "herdr-smart-quit: process query failed; refusing to close" >&2
  exit 1
fi

# Include Nix-wrapped editor process names as well as Vim variants.
vim_pattern='^\.?g?(view|l?n?vim?x?)(diff)?(-wrapped)?$'
if ! action=$(jq -er --arg pane "$pane" --arg vim "$vim_pattern" '
  .result.process_info as $info
  | if $info.pane_id != $pane then
      error("pane mismatch")
    elif ($info.foreground_processes | type) != "array" then
      error("missing foreground processes")
    elif ($info.foreground_processes | length) == 0 then
      error("empty foreground processes")
    elif (all($info.foreground_processes[]; (.name | type) == "string" and (.name | length) > 0) | not) then
      error("invalid process name")
    elif any($info.foreground_processes[]; .name | split("/") | last | ascii_downcase | test($vim)) then
      "forward"
    else
      "close"
    end
' <<<"$process_info"); then
  echo "herdr-smart-quit: cannot identify foreground processes; refusing to close" >&2
  exit 1
fi

case "$action" in
forward) exec "$herdr" pane send-keys "$pane" ctrl+q ;;
close) exec "$herdr" pane close "$pane" ;;
*)
  echo "herdr-smart-quit: unexpected action; refusing to close" >&2
  exit 1
  ;;
esac
