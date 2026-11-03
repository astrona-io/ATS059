#!/usr/bin/env bash
set -uo pipefail
router_ip="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.ROUTER_IP}')"
router_asn="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.BGP_ROUTER_ASN}')"
local_asn="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.BGP_LOCAL_ASN}')"
workers="$(kubectl get nodes -l '!node-role.kubernetes.io/control-plane' -o jsonpath='{.items[*].metadata.name}')"
# One cluster configuration must peer with the router using the right ASNs.
rows="$(kubectl get ciliumbgpclusterconfigs -o jsonpath='{range .items[*]}{range .spec.bgpInstances[*]}{.localASN}{"|"}{range .peers[*]}{.peerASN}{"|"}{.peerAddress}{" "}{end}{"\n"}{end}{end}' 2>/dev/null)"
if printf '%s\n' "$rows" | grep -q "^${local_asn}|.*${router_asn}|${router_ip} "; then
  echo "PASS: a cluster configuration peers ${local_asn} with ${router_asn} at ${router_ip}"
  exit 0
fi
echo "FAIL: no CiliumBGPClusterConfig with localASN ${local_asn}, peerASN ${router_asn} and peerAddress ${router_ip}"
exit 1
