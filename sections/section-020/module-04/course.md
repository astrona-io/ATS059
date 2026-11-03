---
draft: true
exam_objectives:
- BGP Control Plane
- Understand Options to Connect Cilium-managed Clusters with External Networks
---
# Operate And Troubleshoot BGP

A BGP setup that has been built is not the same as a BGP setup that you can run. Sessions drop, routes go missing and an advertisement changes nothing because of one wrong label. This module teaches the commands that show what each side sees, the attributes that change how the router treats a route, and a fixed order of checks for the faults that happen most often. It ends with the older BGP resources, because you will meet them in existing clusters.

Cilium is the Container Network Interface (CNI) plugin of the cluster. Its agent runs on every node, and the BGP Control Plane runs a BGP speaker inside that agent.

## What you will learn

The four parts of the module build on one example: the router should receive the address of the `probe-public` Service, tagged with a community, and it does not.

1. The first part shows how to inspect sessions and routes from the node side and from the router side.
2. The second part covers route attributes: communities and local preference, and what the router does with them.
3. The third part gives a fixed order of checks for a session that does not establish and for an advertisement that does not arrive.
4. The fourth part covers the older `CiliumBGPPeeringPolicy` resource, how it maps to the current resources, and the advertisement of pod address pools.

## Learning objectives

After this module you can:

- Read the session state and the route tables with the Cilium client and with the router.
- Tell the routes that a node has available from the routes that it advertises to a peer.
- Add a community and a local preference to an advertisement and verify them on the router.
- Follow a fixed order of checks from the feature flag to the router table.
- Find the three most common reasons that an advertisement does not arrive.
- Map a `CiliumBGPPeeringPolicy` to the current resources.

## Before you start

You need the previous BGP modules of this course. You need to know the resources, how a session comes up and how a Service gets an address from a pool.

Your playground is a three-node `kind` cluster running Kubernetes 1.35 without kube-proxy, with Cilium 1.20.2 and the BGP Control Plane on. The nodes use ASN 64513 and an FRR router in a Docker container uses ASN 64512. The two workers have established sessions with it. A pool `starfleet-pool` exists. The `starfleet` namespace holds a ConfigMap `lab-env` with the router address, the router container name, both ASNs and the pool range.

| Namespace | Object | What it is |
| --- | --- | --- |
| `starfleet` | ConfigMap `lab-env` | Router container, router address, ASNs and pool range |
| `starfleet` | Service `probe-public` | A `LoadBalancer` Service in the playground |
| `starfleet` | pod `shuttle`, Service `probe` | Example workloads |

## Key terms

- Community: a tag on a route that a router can match in its policy.
- Local preference: a number that routers inside one autonomous system use to choose between routes. Higher wins.
- Available route: a route that the node has in its BGP table.
- Advertised route: a route that the node sends to one peer.
- Peering policy: the older resource, `CiliumBGPPeeringPolicy`, that held the whole configuration in one object.

## Why this matters for the exam

The certification asks which options connect a cluster to an external network, and BGP is the main one. Questions about it often describe a symptom and ask for the cause: an advertisement that selects nothing, a peer configuration that selects a label nobody has, or a session in the wrong state. Knowing the order of checks answers these directly.

Start the playground now and keep it running while you read:

<!-- astrona:playground -->
