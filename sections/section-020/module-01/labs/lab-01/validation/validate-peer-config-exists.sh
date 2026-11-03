#!/usr/bin/env bash
set -uo pipefail
router_ip="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.ROUTER_IP}')"
router_asn="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.BGP_ROUTER_ASN}')"
local_asn="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.BGP_LOCAL_ASN}')"
workers="$(kubectl get nodes -l '!node-role.kubernetes.io/control-plane' -o jsonpath='{.items[*].metadata.name}')"
# The referenced peer configuration must exist and carry an ipv4 unicast family.
refs="$(kubectl get ciliumbgpclusterconfigs -o jsonpath='{range .items[*]}{range .spec.bgpInstances[*]}{range .peers[*]}{.peerConfigRef.name}{"\n"}{end}{end}{end}' 2>/dev/null | sort -u)"
if [ -z "$refs" ]; then
  echo "FAIL: no peerConfigRef found in any CiliumBGPClusterConfig"
  exit 1
fi
for ref in $refs; do
  families="$(kubectl get ciliumbgppeerconfig "$ref" -o jsonpath='{range .spec.families[*]}{.afi}{"/"}{.safi}{"\n"}{end}' 2>/dev/null)"
  if printf '%s\n' "$families" | grep -q '^ipv4/unicast$'; then
    echo "PASS: peer configuration ${ref} exists with the family ipv4/unicast"
    exit 0
  fi
done
echo "FAIL: no referenced CiliumBGPPeerConfig has the family ipv4/unicast"
exit 1
