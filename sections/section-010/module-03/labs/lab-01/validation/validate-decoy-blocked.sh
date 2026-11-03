#!/usr/bin/env bash
set -uo pipefail
partner_name="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.PARTNER_NAME}')"
partner_ip="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.PARTNER_IP}')"
decoy_ip="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.DECOY_IP}')"
policies="$(kubectl -n starfleet get ciliumnetworkpolicies -o json 2>/dev/null)"
# shuttle must not reach the decoy.
if kubectl -n starfleet exec shuttle -- curl -s --max-time 6 "http://${decoy_ip}:8080/ip" >/dev/null 2>&1; then
  echo "FAIL: shuttle reached the decoy at ${decoy_ip}"
  exit 1
fi
echo "PASS: shuttle cannot reach the decoy at ${decoy_ip}"
exit 0
