#!/usr/bin/env bash
set -uo pipefail
router_container="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.ROUTER_CONTAINER}')"
lb_ip="$(kubectl -n starfleet get service probe-public -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)"
# No advertisement may announce ClusterIP addresses.
rows="$(kubectl get ciliumbgpadvertisements -o jsonpath='{range .items[*]}{range .spec.advertisements[*]}{.service.addresses}{"\n"}{end}{end}' 2>/dev/null)"
if [ -z "$(kubectl get ciliumbgpadvertisements -o name 2>/dev/null)" ]; then
  echo "FAIL: no CiliumBGPAdvertisement found"
  exit 1
fi
if printf '%s\n' "$rows" | grep -q 'ClusterIP'; then
  echo "FAIL: an advertisement announces ClusterIP addresses"
  exit 1
fi
echo "PASS: no advertisement announces ClusterIP"
exit 0
