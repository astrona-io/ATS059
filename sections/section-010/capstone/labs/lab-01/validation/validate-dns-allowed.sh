#!/usr/bin/env bash
set -uo pipefail
partner_ip="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.PARTNER_IP}')"
gateway_ip="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.GATEWAY_IP}')"
router_ip="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.ROUTER_IP}')"
if kubectl -n starfleet exec shuttle -- nslookup kubernetes.default.svc.cluster.local >/dev/null 2>&1; then
  echo "PASS: shuttle resolves cluster names"
  exit 0
fi
echo "FAIL: shuttle cannot resolve kubernetes.default.svc.cluster.local"
exit 1
