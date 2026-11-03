---
draft: true
exam_objectives:
- BGP Control Plane
---
# Advertise Pod And Service Addresses With BGP And LB IPAM

A BGP session between the nodes and a router is only the transport. It becomes useful when the nodes announce addresses that the network can then reach. This module covers what a Cilium node announces, where the address of a `LoadBalancer` Service comes from, and which options keep the announcements stable when nodes and agents restart.

Cilium is the Container Network Interface (CNI) plugin of the cluster. Its agent runs on every node, and the BGP Control Plane runs a BGP speaker inside it. A speaker is the part of a router that sends and receives BGP messages. The Cilium operator also runs the load balancer IP address management (LB IPAM) that gives Services an external address.

## What you will learn

The three parts of the module build on one example: the `probe` pods in `starfleet` must be reachable from the external router through a stable address.

1. The first part covers the `CiliumBGPAdvertisement` resource. You announce the pod prefixes of the nodes and the addresses of selected Services, and check the routes on the router.
2. The second part covers LB IPAM. You read a `CiliumLoadBalancerIPPool`, create a Service of type `LoadBalancer`, and trace its address from the pool to a route on the router.
3. The third part covers the connection options: timers, graceful restart, multihop, authentication, node overrides and aggregation. You restart an agent and watch the routes.

## Learning objectives

After this module you can:

- Name the advertisement types and say which one announces pod prefixes and which one announces Service addresses.
- Write a `CiliumBGPAdvertisement` and connect it to a session with a label.
- Define a `CiliumLoadBalancerIPPool` with blocks and a Service selector, and read the address that a Service receives.
- Explain why a pool address is not reachable until an advertisement announces it.
- Explain how `externalTrafficPolicy` changes which nodes announce a Service address.
- Choose timers, graceful restart, multihop and overrides for a given situation.
- Verify the result in order: conditions, session state, router routes and a client request.

## Before you start

You need to know what a Service of type `LoadBalancer` is, and you need to know how a BGP session is set up with a `CiliumBGPClusterConfig` and a `CiliumBGPPeerConfig`. In short: a cluster configuration selects nodes by label and names the peers, and a peer configuration holds the session settings and selects advertisements by label.

Your playground is a three-node `kind` cluster (one control plane node and two worker nodes) running Kubernetes 1.35 without kube-proxy. Cilium 1.20.2 is installed with Helm, and the BGP Control Plane is on. The nodes use the private ASN 64513, and the external router, an FRR container on the same Docker network, uses ASN 64512.

The playground starts with the session already established on both workers, and with one pool named `starfleet-pool` that holds the block `198.51.100.0/28`. No advertisement exists, so the router has learned no prefixes.

| Namespace | Object | What it is |
| --- | --- | --- |
| `starfleet` | Deployment and Service `probe` | An HTTP service with a `ClusterIP` Service |
| `starfleet` | pod `shuttle` | A client pod with `curl` |
| `outpost` | pod `drifter` | A second client pod |
| `starfleet` | ConfigMap `lab-env` | The router address and container name and the two ASNs |

## Key terms

- Advertisement: a message that announces a prefix to a peer.
- PodCIDR: the block of pod addresses that Kubernetes assigns to one node.
- LB IPAM: the Cilium feature that assigns external addresses to Services of type `LoadBalancer`.
- Pool: a list of address blocks from which LB IPAM assigns addresses.
- Graceful restart: a BGP option that keeps routes at the peer while a speaker restarts.

## The order of the commands

You check that the router learned nothing. You apply an advertisement for pod prefixes and read the routes. You create a Service of type `LoadBalancer`, read its address and see the route appear. At the end you restart an agent and watch the routes with and without graceful restart.

## The scenario

The network team asks the cluster team three questions about the `probe` service.

1. Which addresses does the cluster announce to the router, and how do we choose them?
2. Where does the external address of the Service come from?
3. What does the router see when a node or an agent fails?

The three parts answer these questions in this order.

At the end of the module you can answer each of them with a command and its output.

## What this module does not cover

The module does not cover how to configure the session from the start, route policies on the router, or other Cilium features such as Layer 2 announcements. It also does not cover cloud load balancers.

## How to read the parts

Each part has commands that you run in the playground. The text describes the kind of output to expect and does not print exact values, because addresses differ on every machine. Read the output on your screen and compare it with the explanation.

Each part ends with a list of common mistakes.

The last page is a summary. When you finish it, the playground is destroyed.

## Why this matters for the exam

The BGP objectives of the Cilium certification include advertising pod and Service addresses and explaining where a load balancer address comes from. A common mistake is to treat the pool and the advertisement as one step. They are two resources with two jobs, and the router sees an address only when both are in place.

Keep a short checklist in mind: does the Service have an address, does an advertisement select it, does the peer configuration select that advertisement, and does the router list the route.

Start the playground now and keep it running while you read:

<!-- astrona:playground -->
