---
draft: true
exam_objectives:
- Understand Options to Connect Cilium-managed Clusters with External Networks
---
# Peering Design Choices

A single session between one node and one router is easy to bring up. A real cluster has many nodes, and the network has several routers, so you must decide who peers with whom and with which autonomous system number (ASN). This part covers those design choices: which nodes speak BGP, which routers they peer with, and which ASN each side uses.

## Which nodes peer

The `CiliumBGPClusterConfig` has a `nodeSelector`. Only nodes that match it run a BGP instance. A node that does not match announces nothing and has no session. This is the first design decision.

A common design peers all nodes. Every node announces its own pod prefix, so the router has a direct route to each node. Another design peers only a few nodes, for example the nodes that carry ingress traffic. Then only those nodes announce Service addresses, and the other nodes stay out of the routing table of the router. The label on the node is the switch, so you can change the design with a label.

<!-- astrona:playground:renew -->

To see which nodes would match a selector, list the nodes with the label from the cluster configuration:

```sh
kubectl get nodes -l bgp=enabled
kubectl get ciliumbgpnodeconfigs
```

The first command lists the selected nodes. The second lists the node configurations that the operator created for them. The two lists must contain the same nodes. A node in the first list and not in the second means that the operator has not processed it yet or that the cluster configuration does not select it.

## eBGP and iBGP in a cluster

When the ASN of the cluster differs from the ASN of the router, the session is eBGP. When the ASN is the same, it is iBGP. The two types differ in rules that matter for design.

- An eBGP peer replaces the next hop with its own address when it passes a route on. An iBGP peer keeps the next hop, so the router needs a route to that next hop.
- A router does not pass a route that it learned from an iBGP peer to another iBGP peer. For that, iBGP needs a full mesh of sessions or a route reflector.
- eBGP sessions use a TTL of 1 by default, so the peer must be directly connected.

For nodes and a top-of-rack router, eBGP is the usual choice. It needs no full mesh, and each side has a clear boundary. The nodes of all racks can share one private ASN, and the routers use a different one. Private ASNs are 64512 to 65534 for the two-byte range, and 4200000000 to 4294967294 for the four-byte range. Check that two routers on the path do not use the same ASN, because a router rejects a route whose AS path already contains its own number.

## Peering with more than one router

A node can have several peers in one instance. A node that peers with two top-of-rack routers announces every prefix to both. If one router fails, the other still has the routes. List both in the `peers` of the instance, each with its own address and its own `peerConfigRef`.

The routers see the same prefix from many nodes. They choose a best path, or several equal paths for load balancing (ECMP, equal-cost multipath), depending on their configuration. The cluster does not control this choice, except through route attributes such as local preference that a later module covers.

## IPv6 and address families

A peer configuration lists address families in `families`. Each entry has an `afi` (address family identifier, `ipv4` or `ipv6`) and a `safi` (subsequent address family identifier, `unicast`). To announce IPv6 prefixes, add the family `ipv6` and `unicast` and make sure the cluster has IPv6 enabled. A session over an IPv4 address can carry IPv6 routes when both families are negotiated.

## What you can now do

You can choose which nodes peer, explain why eBGP is the usual choice between nodes and a router, name the rules about next hops and route propagation that make iBGP harder, and describe how several peers and several address families fit into one cluster configuration. The open question is what the nodes announce and where Service addresses come from.

## Common pitfalls

> [!WARNING]
> A `nodeSelector` that matches no node creates no sessions and no error that points to the selector. Two routers on the path with the same ASN reject each other's routes. Do not use iBGP between nodes and a router unless you also plan the route reflector. A family that you do not list in `families` carries no routes.
