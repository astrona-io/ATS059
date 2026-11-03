#!/usr/bin/env bash
# Reference solution: label the workers, then create the peer and cluster configuration.
set -euo pipefail
router_ip="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.ROUTER_IP}')"
router_asn="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.BGP_ROUTER_ASN}')"
local_asn="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.BGP_LOCAL_ASN}')"
for worker in $(kubectl get nodes -l '!node-role.kubernetes.io/control-plane' -o jsonpath='{.items[*].metadata.name}'); do
  kubectl label node "$worker" bgp=enabled --overwrite
done
kubectl apply -f - <<YAML
apiVersion: cilium.io/v2
kind: CiliumBGPPeerConfig
metadata:
  name: cilium-peer
spec:
  timers:
    holdTimeSeconds: 9
    keepAliveTimeSeconds: 3
  families:
  - afi: ipv4
    safi: unicast
    advertisements:
      matchLabels:
        advertise: bgp
---
apiVersion: cilium.io/v2
kind: CiliumBGPClusterConfig
metadata:
  name: cilium-bgp
spec:
  nodeSelector:
    matchLabels:
      bgp: enabled
  bgpInstances:
  - name: instance-nodes
    localASN: ${local_asn}
    peers:
    - name: peer-router
      peerASN: ${router_asn}
      peerAddress: ${router_ip}
      peerConfigRef:
        name: cilium-peer
YAML
