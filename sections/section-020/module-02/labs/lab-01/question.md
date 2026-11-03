---
draft: true
exam_objectives:
- BGP Control Plane
---
# Advertise The probe Service And The Pod Prefixes

The network team wants to reach the `probe` pods from the external router through a stable address. Create a Service of type `LoadBalancer` for them, announce its address with BGP, and announce the pod prefixes of the worker nodes too. Do not announce cluster IP addresses.

## Starting state

A three-node `kind` cluster runs Cilium with the BGP Control Plane. The two worker nodes already have established sessions with an FRR router in a Docker container. The peer configuration selects advertisements with the label `advertise: bgp`. A pool named `starfleet-pool` holds the block `198.51.100.0/28`. The Deployment `probe` in `starfleet` has pods with the label `app: probe` that listen on port 8080. The Service `probe` is of type `ClusterIP`.

No advertisement exists. Check the router at any time with:

```sh
ROUTER_CONTAINER=$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.ROUTER_CONTAINER}')
docker exec $ROUTER_CONTAINER vtysh -c 'show ip route bgp'
```

## Required result

- A Service `probe-public` in `starfleet` is of type `LoadBalancer`, selects `app: probe`, exposes port 80 to target port 8080, and receives an address from the pool.
- A `CiliumBGPAdvertisement` of type `Service` announces the `LoadBalancerIP` of Services that have the label `bgp=advertise`. It has the label `advertise: bgp`. The Service `probe-public` has the label `bgp=advertise`.
- A `CiliumBGPAdvertisement` of type `PodCIDR` with the label `advertise: bgp` announces the pod prefixes.
- The router has BGP routes for the Service address and for the pod prefix of each worker.
- No advertisement announces `ClusterIP` addresses.

Submit when you are done:

```sh
astrona submit -c .
```
