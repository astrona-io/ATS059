#!/usr/bin/env bash
set -uo pipefail
worker="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.WORKER_NODE}')"
pool_base="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.POOL_BASE}')"
lb_ip="$(kubectl -n starfleet get service probe-public -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)"
policies="$(kubectl get ciliuml2announcementpolicies -o json 2>/dev/null)"
total="$(printf '%s' "$policies" | jq '.items | length' 2>/dev/null)"
open="$(printf '%s' "$policies" | jq '[.items[] | select((.spec.serviceSelector // null) == null)] | length' 2>/dev/null)"
if [ "${total:-0}" -ge 1 ] && [ "${open:-1}" -eq 0 ]; then
  echo "PASS: every announcement policy has a serviceSelector"
  exit 0
fi
echo "FAIL: a policy has no serviceSelector, or no policy exists"
exit 1
