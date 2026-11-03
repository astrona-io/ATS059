#!/usr/bin/env bash
# Reference solution (applied only by astrona test).
set -euo pipefail
partner_ip="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.PARTNER_IP}')"
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
YAML
sleep 5
