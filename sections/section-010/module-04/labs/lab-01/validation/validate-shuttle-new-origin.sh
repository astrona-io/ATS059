#!/usr/bin/env bash
set -uo pipefail
partner_ip="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.PARTNER_IP}')"
gateway2_ip="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.GATEWAY2_IP}')"
gateway2_node="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.GATEWAY2_NODE}')"
# The partner must see the second gateway address for shuttle.
body="$(kubectl -n starfleet exec shuttle -- curl -s --max-time 8 "http://${partner_ip}:8080/ip" 2>/dev/null | tr -d '\n ')"
origin="$(printf '%s' "$body" | sed -n 's/.*"origin":"\([^"]*\)".*/\1/p')"
if [ "$origin" = "$gateway2_ip" ]; then
  echo "PASS: the partner sees ${origin} for shuttle"
  exit 0
fi
echo "FAIL: the partner sees '${origin}' for shuttle, expected ${gateway2_ip}"
exit 1
