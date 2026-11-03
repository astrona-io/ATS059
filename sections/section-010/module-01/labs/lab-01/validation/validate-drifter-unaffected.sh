#!/usr/bin/env bash
# The policy must be scoped to shuttle: drifter still reaches the decoy.
set -uo pipefail
decoy_ip="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.DECOY_IP}')"
status="$(kubectl -n outpost exec drifter -- curl -s -o /dev/null -w '%{http_code}' --max-time 8 "http://${decoy_ip}:8080/ip" 2>/dev/null)"
if [ "$status" = "200" ]; then
  echo "PASS: drifter still reaches external services"
  exit 0
fi
echo "FAIL: drifter lost external access (HTTP status '${status}'); scope the policy to app=shuttle in starfleet"
exit 1
