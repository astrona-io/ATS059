#!/usr/bin/env bash
set -uo pipefail
router_container="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.ROUTER_CONTAINER}')"
lb_ip="$(kubectl -n starfleet get service probe-public -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)"
# One advertisement of type Service must announce LoadBalancerIP and carry the label advertise=bgp.
rows="$(kubectl get ciliumbgpadvertisements -l advertise=bgp -o jsonpath='{range .items[*]}{range .spec.advertisements[*]}{.advertisementType}{"|"}{.service.addresses}{"\n"}{end}{end}' 2>/dev/null)"
if printf '%s\n' "$rows" | grep -q '^Service|.*LoadBalancerIP'; then
  echo "PASS: a Service advertisement with LoadBalancerIP carries the label advertise=bgp"
  exit 0
fi
echo "FAIL: no CiliumBGPAdvertisement with label advertise=bgp has type Service and LoadBalancerIP"
exit 1
