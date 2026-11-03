#!/usr/bin/env bash
set -uo pipefail
partner_name="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.PARTNER_NAME}')"
partner_ip="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.PARTNER_IP}')"
decoy_ip="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.DECOY_IP}')"
policies="$(kubectl -n starfleet get ciliumnetworkpolicies -o json 2>/dev/null)"
# drifter has no policy and must still reach the decoy.
body="$(kubectl -n outpost exec drifter -- curl -s --max-time 8 "http://${decoy_ip}:8080/ip" 2>/dev/null | tr -d '\n ')"
if printf '%s' "$body" | grep -q '"origin"'; then
  echo "PASS: drifter still reaches the decoy"
  exit 0
fi
echo "FAIL: drifter cannot reach the decoy, the policy selects too much"
exit 1
