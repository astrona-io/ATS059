#!/usr/bin/env bash
set -uo pipefail
worker="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.WORKER_NODE}')"
pool_base="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.POOL_BASE}')"
lb_ip="$(kubectl -n starfleet get service probe-public -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)"
policies="$(kubectl get ciliuml2announcementpolicies -o json 2>/dev/null)"
count="$(printf '%s' "$policies" | jq '[.items[] | select(any(.spec.nodeSelector.matchExpressions[]?; .key == "node-role.kubernetes.io/control-plane" and .operator == "DoesNotExist"))] | length' 2>/dev/null)"
if [ "${count:-0}" -ge 1 ]; then
  echo "PASS: a policy excludes control plane nodes"
  exit 0
fi
echo "FAIL: no policy has a nodeSelector that excludes control plane nodes"
exit 1
