#!/usr/bin/env bash
set -uo pipefail
partner_ip="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.PARTNER_IP}')"
gateway_ip="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.GATEWAY_IP}')"
gateway_node="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.GATEWAY_NODE}')"
# The partner must report the gateway address as the caller of shuttle.
body="$(kubectl -n starfleet exec shuttle -- curl -s --max-time 8 "http://${partner_ip}:8080/ip" 2>/dev/null | tr -d '\n ')"
origin="$(printf '%s' "$body" | sed -n 's/.*"origin":"\([^"]*\)".*/\1/p')"
if [ "$origin" = "$gateway_ip" ]; then
  echo "PASS: the partner sees ${origin} for shuttle"
  exit 0
fi
echo "FAIL: the partner saw '${origin}' for shuttle, expected ${gateway_ip}"
exit 1
