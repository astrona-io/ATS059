#!/usr/bin/env bash
set -uo pipefail
router_container="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.ROUTER_CONTAINER}')"
summary="$(docker exec "$router_container" vtysh -c 'show bgp summary' 2>/dev/null)"
# Neighbor lines start with an address (dynamic neighbors have a leading *).
# For an established neighbor the last column is a number of received prefixes.
total="$(printf '%s\n' "$summary" | grep -c -E '^\*?[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+')"
up="$(printf '%s\n' "$summary" | grep -E '^\*?[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | awk '$NF ~ /^[0-9]+$/' | wc -l | tr -d ' ')"
if [ "${total:-0}" -ge 2 ] && [ "$up" = "$total" ]; then
  echo "PASS: the router lists ${up} established neighbors"
  exit 0
fi
echo "FAIL: the router lists ${total} neighbors and ${up} are established"
exit 1
