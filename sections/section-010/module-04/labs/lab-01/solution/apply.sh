#!/usr/bin/env bash
# Reference solution: label the second worker and move the policy to it.
set -euo pipefail
partner_ip="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.PARTNER_IP}')"
gateway2_ip="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.GATEWAY2_IP}')"
gateway2_node="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.GATEWAY2_NODE}')"
kubectl label node "$gateway2_node" role=egress-gateway --overwrite
kubectl apply -f - <<YAML
apiVersion: cilium.io/v2
kind: CiliumEgressGatewayPolicy
metadata:
  name: shuttle-to-partner
spec:
  selectors:
  - podSelector:
      matchLabels:
        io.kubernetes.pod.namespace: starfleet
        app: shuttle
  destinationCIDRs:
  - ${partner_ip}/32
  egressGateway:
    nodeSelector:
      matchLabels:
        role: egress-gateway
    egressIP: ${gateway2_ip}
YAML
