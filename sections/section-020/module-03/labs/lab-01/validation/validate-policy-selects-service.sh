#!/usr/bin/env bash
set -uo pipefail
worker="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.WORKER_NODE}')"
pool_base="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.POOL_BASE}')"
lb_ip="$(kubectl -n starfleet get service probe-public -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)"
label="$(kubectl -n starfleet get service probe-public -o jsonpath='{.metadata.labels.announce}' 2>/dev/null)"
policies="$(kubectl get ciliuml2announcementpolicies -o json 2>/dev/null)"
count="$(printf '%s' "$policies" | jq --arg l "$label" '[.items[] | select(.spec.serviceSelector.matchLabels.announce == $l) | select(.spec.loadBalancerIPs == true)] | length' 2>/dev/null)"
if [ -n "$label" ] && [ "${count:-0}" -ge 1 ]; then
  echo "PASS: a policy selects announce=${label} and announces load balancer addresses"
  exit 0
fi
echo "FAIL: no CiliumL2AnnouncementPolicy selects the label of probe-public with loadBalancerIPs true"
exit 1
