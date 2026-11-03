---
draft: true
exam_objectives:
- Understand Options to Connect Cilium-managed Clusters with External Networks
---
# Announce Service Addresses Without BGP

BGP is the right tool when the network has routers that speak BGP. Many clusters do not have them: a lab, an office network or a small data center often has only switches and a default gateway. A Service of type `LoadBalancer` still needs an address that clients on that network can reach. This module covers the options of Cilium for that case: Layer 2 announcements and Node IPAM, and how to choose between them and BGP.

Cilium is the Container Network Interface (CNI) plugin of the cluster, and its agent runs on every node. The Cilium operator also runs the load balancer IP address management (LB IPAM) that assigns an address from a pool to a Service of type `LoadBalancer`. An address from a pool is not reachable until something announces it to the network. BGP is one way to announce it. Layer 2 announcements are another.

## What you will learn

The four parts of the module build on one example: the `probe` Service in `starfleet` must be reachable from the local network by one address, without a router that speaks BGP.

1. The first part explains Layer 2 announcements: what ARP and NDP are, which node answers for an address, and what the feature needs.
2. The second part covers the `CiliumL2AnnouncementPolicy` resource: selecting Services, nodes and interfaces.
3. The third part covers leases, failover and the limits of Layer 2 announcements.
4. The fourth part covers Node IPAM, which gives a Service the addresses of the nodes, and a decision guide for all the options in this course.

## Learning objectives

After this module you can:

- Explain how a node answers ARP requests for a Service address and why only one node answers at a time.
- Name the Helm values that Layer 2 announcements need.
- Write a `CiliumL2AnnouncementPolicy` with a Service selector, a node selector and an interface list.
- Find which node holds the lease for a Service and explain what happens when that node fails.
- Explain Node IPAM and the `loadBalancerClass` that selects it.
- Choose between BGP, Layer 2 announcements and Node IPAM for a given network.

## Before you start

You need to know what a Service of type `LoadBalancer` is and how a `CiliumLoadBalancerIPPool` assigns an address. The previous module in this section covers the pool.

Your playground is a three-node `kind` cluster (one control plane node and two worker nodes) running Kubernetes 1.35 without kube-proxy. Cilium 1.20.2 is installed with Helm. Layer 2 announcements and external IPs are on. The nodes are Docker containers on the Docker network named `kind`, which is one Layer 2 segment.

The playground starts with a pool named `starfleet-pool` that holds addresses from the Docker network, and no announcement policy.

| Namespace | Object | What it is |
| --- | --- | --- |
| `starfleet` | Deployment and Service `probe` | An HTTP service with a `ClusterIP` Service |
| `starfleet` | pod `shuttle` | A client pod with `curl` |
| `outpost` | pod `drifter` | A second client pod |
| `starfleet` | ConfigMap `lab-env` | The names of the worker nodes and the first pool address |

## Key terms

- ARP: the Address Resolution Protocol, which an IPv4 host uses to ask which hardware (MAC) address owns an IP address.
- NDP: the Neighbor Discovery Protocol, which does the same for IPv6.
- Lease: a Kubernetes object that one node holds for a time and renews, so that only one node acts.
- Node IPAM: the Cilium feature that gives a `LoadBalancer` Service the addresses of the nodes.

## The order of the commands

You create a Service of type `LoadBalancer` and read its address. You check that a client on the network cannot reach it yet. You apply an announcement policy, find the lease holder and reach the address. At the end you read how Node IPAM differs.

## What this module does not cover

The module does not cover BGP sessions or route policies, which the other modules in this section cover. It also does not cover cloud load balancers.

## How to read the parts

Each part has commands that you run in the playground. The text describes the kind of output to expect. Each part ends with a list of common mistakes. The last page is a summary. When you finish it, the playground is destroyed.

## Why this matters for the exam

The certification asks which options connect a cluster to an external network. BGP is one. Layer 2 announcements and Node IPAM are the others for Services. A common mistake is to think that a pool address is reachable without an announcement.

Start the playground now and keep it running while you read:

<!-- astrona:playground -->
