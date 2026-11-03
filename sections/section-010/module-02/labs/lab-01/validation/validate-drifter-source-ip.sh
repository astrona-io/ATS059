#!/usr/bin/env bash
set -uo pipefail
partner_ip="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.PARTNER_IP}')"
gateway_ip="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.GATEWAY_IP}')"
gateway_node="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.GATEWAY_NODE}')"
# drifter must still reach the partner, and the partner must not see the gateway address.
body="$(kubectl -n outpost exec drifter -- curl -s --max-time 8 "http://${partner_ip}:8080/ip" 2>/dev/null | tr -d '\n ')"
origin="$(printf '%s' "$body" | sed -n 's/.*"origin":"\([^"]*\)".*/\1/p')"
if [ -z "$origin" ]; then
  echo "FAIL: drifter got no answer from the partner"
  exit 1
fi
if [ "$origin" = "$gateway_ip" ]; then
  echo "FAIL: the partner sees the gateway address for drifter, the policy selects too much"
  exit 1
fi
echo "PASS: the partner sees ${origin} for drifter, not the gateway address"
exit 0
