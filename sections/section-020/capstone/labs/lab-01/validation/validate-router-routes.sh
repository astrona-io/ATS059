#!/usr/bin/env bash
set -uo pipefail
router_container="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.ROUTER_CONTAINER}')"
workers="$(kubectl get nodes -l '!node-role.kubernetes.io/control-plane' -o jsonpath='{.items[*].metadata.name}')"
lb_ip="$(kubectl -n starfleet get service probe-public -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)"
if [ -z "$lb_ip" ]; then
  echo "FAIL: probe-public has no address yet"
  exit 1
fi
routes="$(docker exec "$router_container" vtysh -c 'show ip route bgp' 2>/dev/null)"
if ! printf '%s\n' "$routes" | grep -q "${lb_ip}/32"; then
  echo "FAIL: the router has no BGP route for ${lb_ip}/32"
  exit 1
fi
for prefix in $(kubectl get nodes -l '!node-role.kubernetes.io/control-plane' -o jsonpath='{.items[*].spec.podCIDR}'); do
  if ! printf '%s\n' "$routes" | grep -q "$prefix"; then
    echo "FAIL: the router has no BGP route for ${prefix}"
    exit 1
  fi
done
echo "PASS: the router has routes for ${lb_ip}/32 and the worker pod prefixes"
exit 0
