#!/usr/bin/env bash
set -uo pipefail
router_container="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.ROUTER_CONTAINER}')"
lb_ip="$(kubectl -n starfleet get service probe-public -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)"
count="$(kubectl get ciliumbgpadvertisements -o json 2>/dev/null | jq '[.items[].spec.advertisements[] | select(.advertisementType == "Service") | select(any(.attributes.communities.standard[]?; . == "64513:100"))] | length')"
if [ "${count:-0}" -ge 1 ]; then
  echo "PASS: a Service advertisement sets the community 64513:100"
  exit 0
fi
echo "FAIL: no Service advertisement sets the standard community 64513:100"
exit 1
