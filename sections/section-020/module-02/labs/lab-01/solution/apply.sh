#!/usr/bin/env bash
# Reference solution: LoadBalancer Service, Service advertisement and PodCIDR advertisement.
set -euo pipefail
kubectl apply -f - <<YAML
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
apiVersion: cilium.io/v2
kind: CiliumBGPAdvertisement
metadata:
  name: pod-prefixes
  labels:
    advertise: bgp
spec:
  advertisements:
  - advertisementType: PodCIDR
YAML
