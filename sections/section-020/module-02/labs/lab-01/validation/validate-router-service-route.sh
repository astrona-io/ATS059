#!/usr/bin/env bash
set -uo pipefail
router_container="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.ROUTER_CONTAINER}')"
lb_ip="$(kubectl -n starfleet get service probe-public -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)"
# The router must have learned the Service address over BGP.
if [ -z "$lb_ip" ]; then
  echo "FAIL: probe-public has no address yet"
  exit 1
fi
routes="$(docker exec "$router_container" vtysh -c 'show ip route bgp' 2>/dev/null)"
if printf '%s\n' "$routes" | grep -q "${lb_ip}/32"; then
  echo "PASS: the router has a BGP route for ${lb_ip}/32"
  exit 0
fi
echo "FAIL: the router has no BGP route for ${lb_ip}/32"
exit 1
