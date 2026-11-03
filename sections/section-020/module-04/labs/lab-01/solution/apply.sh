#!/usr/bin/env bash
# Reference solution: label the Service, fix the advertisement label and add the community.
set -euo pipefail
kubectl -n starfleet label service probe-public bgp=advertise --overwrite
kubectl apply -f - <<YAML
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
    attributes:
      communities:
        standard:
        - "64513:100"
YAML
