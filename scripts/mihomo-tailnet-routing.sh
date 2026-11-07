#!/usr/bin/env bash
set -Eeuo pipefail

# Shared by ymir's mutually exclusive proxy profiles. Priorities sit after tailscaled's
# transport-mark bypass (5210..5250), but before its Tailnet table rule (5270).
apply_rules() {
  local action=$1 family network priority table selector
  for family in -4 -6; do
    if [[ $family == -4 ]]; then
      network=100.64.0.0/10
    else
      network=fd7a:115c:a1e0::/48
    fi
    for priority in 5260 5261; do
      if [[ $priority == 5260 ]]; then
        selector=from
        table=52
      else
        selector=to
        table=2022
      fi
      if [[ $action == del ]] && [[ -z $(ip "$family" rule show pref "$priority") ]]; then
        continue
      fi
      # Local-source replies stay on the system identity; new local connections
      # use the selected proxy's table when its TUN exists, otherwise fall through to tailscaled.
      ip "$family" rule "$action" priority "$priority" "$selector" "$network" iif lo table "$table"
    done
  done
}

case "${1:-}" in
start)
  for family in -4 -6; do
    for priority in 5260 5261; do
      if [[ -n $(ip "$family" rule show pref "$priority") ]]; then
        echo "Refusing to overwrite existing $family routing rule at priority $priority" >&2
        exit 1
      fi
    done
  done
  trap 'trap - ERR; apply_rules del' ERR
  apply_rules add
  trap - ERR
  ;;
stop)
  apply_rules del
  ;;
*)
  echo "Usage: $0 {start|stop}" >&2
  exit 2
  ;;
esac
