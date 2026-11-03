#!/usr/bin/env bash
# Reference solution: DNS rule plus a toFQDNs rule for the partner name.
set -euo pipefail
partner_name="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.PARTNER_NAME}')"
kubectl apply -f - <<YAML
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: shuttle-partner-name
  namespace: starfleet
spec:
  endpointSelector:
    matchLabels:
      app: shuttle
  egress:
  - toEndpoints:
    - matchLabels:
        io.kubernetes.pod.namespace: kube-system
        k8s-app: kube-dns
    toPorts:
    - ports:
      - port: "53"
        protocol: ANY
      rules:
        dns:
        - matchPattern: "*"
  - toFQDNs:
    - matchName: ${partner_name}
    toPorts:
    - ports:
      - port: "8080"
        protocol: TCP
YAML
