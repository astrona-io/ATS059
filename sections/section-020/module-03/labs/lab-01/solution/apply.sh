#!/usr/bin/env bash
# Reference solution: LoadBalancer Service plus an announcement policy for workers.
set -euo pipefail
kubectl apply -f - <<YAML
apiVersion: v1
kind: Service
metadata:
  name: probe-public
  namespace: starfleet
  labels:
    announce: l2
spec:
  type: LoadBalancer
  selector:
    app: probe
  ports:
  - port: 80
    targetPort: 8080
---
apiVersion: cilium.io/v2alpha1
kind: CiliumL2AnnouncementPolicy
metadata:
  name: starfleet-l2
spec:
  serviceSelector:
    matchLabels:
      announce: l2
  nodeSelector:
    matchExpressions:
    - key: node-role.kubernetes.io/control-plane
      operator: DoesNotExist
  interfaces:
  - ^eth[0-9]+
  loadBalancerIPs: true
YAML
