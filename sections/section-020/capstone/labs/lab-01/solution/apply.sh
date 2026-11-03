#!/usr/bin/env bash
# Reference solution: peering, advertisements and the LoadBalancer Service.
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
  gracefulRestart:
    enabled: true
    restartTimeSeconds: 15
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
---
apiVersion: cilium.io/v2
kind: CiliumBGPAdvertisement
metadata:
  name: pod-prefixes
  labels:
    advertise: bgp
spec:
  advertisements:
  - advertisementType: PodCIDR
---
apiVersion: cilium.io/v2
kind: CiliumBGPAdvertisement
metadata:
  name: service-addresses
  labels:
    advertise: bgp
spec:
  advertisements:
  - advertisementType: Service
    service:
      addresses:
      - LoadBalancerIP
    selector:
      matchExpressions:
      - key: bgp
        operator: In
        values:
        - advertise
---
apiVersion: v1
kind: Service
metadata:
  name: probe-public
  namespace: starfleet
  labels:
    bgp: advertise
spec:
  type: LoadBalancer
  selector:
    app: probe
  ports:
  - port: 80
    targetPort: 8080
YAML
