#!/usr/bin/env bash
# Reference solution: network policy for shuttle plus a gateway policy with the dedicated address.
set -euo pipefail
partner_ip="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.PARTNER_IP}')"
gateway_ip="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.GATEWAY_IP}')"
gateway_node="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.GATEWAY_NODE}')"
kubectl apply -f - <<YAML
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: shuttle-egress
  namespace: starfleet
spec:
  endpointSelector:
    matchLabels:
      app: shuttle
  egress:
  - toEndpoints:
    - matchLabels:
        "k8s:io.kubernetes.pod.namespace": kube-system
        "k8s:k8s-app": kube-dns
    toPorts:
    - ports:
      - port: "53"
        protocol: ANY
      rules:
        dns:
        - matchPattern: "*"
  - toCIDR:
    - ${partner_ip}/32
    toPorts:
    - ports:
      - port: "8080"
        protocol: TCP
---
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
