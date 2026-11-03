#!/usr/bin/env bash
set -uo pipefail
router_container="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.ROUTER_CONTAINER}')"
lb_ip="$(kubectl -n starfleet get service probe-public -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)"
if [ -z "$lb_ip" ]; then
  echo "FAIL: probe-public has no address"
  exit 1
fi
out="$(docker exec "$router_container" vtysh -c "show bgp ipv4 unicast ${lb_ip}/32" 2>/dev/null)"
if printf '%s\n' "$out" | grep -q '64513:100'; then
  echo "PASS: the router shows the community 64513:100 on ${lb_ip}/32"
  exit 0
fi
echo "FAIL: the router does not show the community 64513:100 on ${lb_ip}/32"
exit 1
