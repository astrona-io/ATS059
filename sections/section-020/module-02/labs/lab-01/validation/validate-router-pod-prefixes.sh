#!/usr/bin/env bash
set -uo pipefail
router_container="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.ROUTER_CONTAINER}')"
lb_ip="$(kubectl -n starfleet get service probe-public -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)"
# The router must have a BGP route for the pod prefix of each worker.
prefixes="$(kubectl get nodes -l '!node-role.kubernetes.io/control-plane' -o jsonpath='{.items[*].spec.podCIDR}')"
if [ -z "$prefixes" ]; then
  echo "FAIL: cannot read the pod prefixes of the worker nodes"
  exit 1
fi
routes="$(docker exec "$router_container" vtysh -c 'show ip route bgp' 2>/dev/null)"
for prefix in $prefixes; do
  if ! printf '%s\n' "$routes" | grep -q "$prefix"; then
    echo "FAIL: the router has no BGP route for ${prefix}"
    exit 1
  fi
done
echo "PASS: the router has BGP routes for ${prefixes}"
exit 0
