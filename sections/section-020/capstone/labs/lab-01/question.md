---
draft: true
exam_objectives:
- BGP Control Plane
---
# Capstone: Publish The probe Service To The External Router

The network team wants clients behind the external router to reach the `probe` pods through a stable address. Build the whole chain: BGP peering with the router, a load balancer address for the Service, and the announcements. The peering must survive an agent restart.

## Starting state

A three-node `kind` cluster runs Cilium with the BGP Control Plane. An FRR router runs in a Docker container on the same Docker network and accepts sessions from the node network when the peer uses the node ASN. A pool `starfleet-pool` holds the block `198.51.100.0/28`. The Deployment `probe` in `starfleet` has pods with the label `app: probe` that listen on port 8080.

The ConfigMap `lab-env` in `starfleet` holds `ROUTER_IP`, `ROUTER_CONTAINER`, `BGP_ROUTER_ASN` and `BGP_LOCAL_ASN`. No BGP resource exists.

## Required result

- Only the two worker nodes run BGP. They carry a label that a `CiliumBGPClusterConfig` selects. The instance uses `BGP_LOCAL_ASN`, and the peer uses `BGP_ROUTER_ASN` and `ROUTER_IP`.
- The `CiliumBGPNodeConfig` of each worker shows the peering state `established`.
- The referenced `CiliumBGPPeerConfig` enables graceful restart and uses a hold time of 30 seconds or less.
- A Service `probe-public` in `starfleet` is of type `LoadBalancer`, selects `app: probe`, exposes port 80 to target port 8080 and has an address from the pool. It has the label `bgp=advertise`.
- Advertisements with the label `advertise: bgp` announce the `LoadBalancerIP` of Services with the label `bgp=advertise` and the pod prefixes. The peer configuration selects them.
- The router has BGP routes for the Service address and for the pod prefix of each worker.
- No advertisement announces `ClusterIP` addresses.

Submit when you are done:

```sh
astrona submit -c .
```
