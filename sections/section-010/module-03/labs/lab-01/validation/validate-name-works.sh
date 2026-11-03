#!/usr/bin/env bash
set -uo pipefail
partner_name="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.PARTNER_NAME}')"
partner_ip="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.PARTNER_IP}')"
decoy_ip="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.DECOY_IP}')"
policies="$(kubectl -n starfleet get ciliumnetworkpolicies -o json 2>/dev/null)"
# shuttle must reach the partner by name.
body="$(kubectl -n starfleet exec shuttle -- curl -s --max-time 8 "http://${partner_name}:8080/ip" 2>/dev/null | tr -d '\n ')"
if printf '%s' "$body" | grep -q '"origin"'; then
  echo "PASS: shuttle reached ${partner_name}"
  exit 0
fi
echo "FAIL: shuttle got no answer from ${partner_name}"
exit 1
