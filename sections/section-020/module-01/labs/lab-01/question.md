---
draft: true
exam_objectives:
- BGP Control Plane
---
# Peer The Worker Nodes With The External Router

The network team runs a router outside the cluster. The two worker nodes of the cluster must open BGP sessions with it. Configure the peering with the Cilium BGP Control Plane resources and make both sessions reach the state `established`. The control plane node must not run BGP.

## Starting state

A three-node `kind` cluster runs Cilium with the BGP Control Plane enabled. An FRR router runs in a Docker container on the same Docker network. It accepts sessions from the node network when the peer uses the ASN of the nodes. No BGP resource exists yet.

The ConfigMap `lab-env` in `starfleet` holds the facts:

```sh
kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.ROUTER_IP}'
kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.BGP_ROUTER_ASN}'
kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.BGP_LOCAL_ASN}'
```

## Required result

- Both worker nodes carry a label, and the control plane node does not.
- A `CiliumBGPClusterConfig` selects the labeled nodes. Its instance uses `BGP_LOCAL_ASN` as `localASN`, and one peer uses `BGP_ROUTER_ASN` as `peerASN` and `ROUTER_IP` as `peerAddress`.
- The peer references an existing `CiliumBGPPeerConfig` with an `ipv4` `unicast` family.
- The `CiliumBGPNodeConfig` of each worker shows the peering state `established`.

Submit when you are done:

```sh
astrona submit -c .
```
