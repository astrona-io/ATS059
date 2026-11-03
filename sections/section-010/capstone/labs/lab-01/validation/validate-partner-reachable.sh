#!/usr/bin/env bash
set -uo pipefail
partner_ip="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.PARTNER_IP}')"
gateway_ip="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.GATEWAY_IP}')"
router_ip="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.ROUTER_IP}')"
status="$(kubectl -n starfleet exec shuttle -- curl -s -o /dev/null -w '%{http_code}' --max-time 8 "http://${partner_ip}:8080/ip" 2>/dev/null)"
if [ "$status" = "200" ]; then
  echo "PASS: shuttle reaches the partner (HTTP 200)"
  exit 0
fi
echo "FAIL: shuttle got HTTP status '${status}' from the partner, expected 200"
exit 1
