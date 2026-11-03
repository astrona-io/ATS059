#!/usr/bin/env bash
# shuttle must NOT reach the decoy external service.
set -uo pipefail
decoy_ip="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.DECOY_IP}')"
status="$(kubectl -n starfleet exec shuttle -- curl -s -o /dev/null -w '%{http_code}' --max-time 6 "http://${decoy_ip}:8080/ip" 2>/dev/null)"
if [ "$status" = "200" ]; then
  echo "FAIL: shuttle still reaches the decoy service at ${decoy_ip}; egress is not restricted"
  exit 1
fi
echo "PASS: shuttle cannot reach the decoy service"
