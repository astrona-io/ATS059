#!/usr/bin/env bash
set -uo pipefail
worker="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.WORKER_NODE}')"
pool_base="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.POOL_BASE}')"
lb_ip="$(kubectl -n starfleet get service probe-public -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)"
if [ -z "$lb_ip" ]; then
  echo "FAIL: probe-public has no address yet"
  exit 1
fi
body="$(docker exec "$worker" curl -s --max-time 8 "http://${lb_ip}/ip" 2>/dev/null | tr -d '\n ')"
if printf '%s' "$body" | grep -q '"origin"'; then
  echo "PASS: ${lb_ip} answers from the node network"
  exit 0
fi
echo "FAIL: ${lb_ip} does not answer from the node network"
exit 1
