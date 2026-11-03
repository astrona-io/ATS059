#!/usr/bin/env bash
# Reference solution: one CiliumEgressGatewayPolicy for shuttle and the partner.
set -euo pipefail
partner_ip="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.PARTNER_IP}')"
gateway_ip="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.GATEWAY_IP}')"
gateway_node="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.GATEWAY_NODE}')"
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
        kubernetes.io/hostname: ${gateway_node}
    egressIP: ${gateway_ip}
YAML
