---
draft: true
exam_objectives:
- BGP Control Plane
---
# Peer Cilium Nodes With An External Router Using BGP

A cluster network is invisible to the network around it. A router outside the cluster has no route to a pod prefix or to a Service address, so it cannot deliver traffic to them. BGP (Border Gateway Protocol) solves this: the cluster nodes open sessions with the router and announce what they can reach. The Cilium BGP Control Plane runs the BGP speaker inside the Cilium agent and configures it with Kubernetes resources.

This module teaches the first half of that work: the protocol basics, the resources, and how to bring up a peering session between the nodes and an external router. Announcing addresses comes after the session works, and a different module covers it. Cilium is the Container Network Interface (CNI) plugin of the cluster. Its agent runs on every node and enforces network policy with eBPF (extended Berkeley Packet Filter) programs.

## What you will learn

The three parts of the module build on one example: two worker nodes must peer with an external router.

1. The first part explains BGP for people who run Kubernetes: sessions, autonomous systems, states, timers and advertisements.
2. The second part explains the Cilium resources: the cluster configuration, the peer configuration, the advertisement, the node configuration and the override, and which component handles each.
3. The third part brings up a session in the playground and checks it from the node side and the router side. You also break it on purpose and read the symptoms.

## Learning objectives

After this module you can:

- Describe a BGP session, the difference between eBGP and iBGP, and the states from Idle to Established.
- Explain hold time and keepalive time, and what happens to routes when a session drops.
- Name the Helm setting that turns the BGP Control Plane on and the five resources that it adds.
- Write a `CiliumBGPPeerConfig` and a `CiliumBGPClusterConfig` that peer selected nodes with a router.
- Verify a session with the status of the node configuration, with the Cilium client, and with the router.
- Diagnose a failed session from its state and from the conditions in the resource status.

## Before you start

You need to know what a node, a label and a custom resource are, and you need basic `kubectl` skills. You do not need to know BGP: the first part teaches what you need.

Your playground is a three-node `kind` cluster (one control plane node and two worker nodes) running Kubernetes 1.35 without kube-proxy. Cilium 1.20.2 is installed with Helm, and the BGP Control Plane is on. The nodes use the private ASN 64513.

Next to the cluster, a Docker container on the same Docker network runs FRR, an open-source routing suite. It acts as the external router with ASN 64512. It accepts sessions from addresses in the network of the nodes, when the peer uses ASN 64513. At the start no BGP resource exists, so no session exists.

| Namespace | Object | What it is |
| --- | --- | --- |
| `starfleet` | ConfigMap `lab-env` | The router address, the router container name and both ASNs |
| `starfleet` | pod `shuttle` and Service `probe` | Example workloads |
| `outpost` | pod `drifter` | A second example workload |

## Key terms

- BGP: the protocol that routers use to announce prefixes to each other.
- Autonomous system number (ASN): the number that identifies the administration of a group of routers.
- Peer: the router at the other end of a session.
- Session: the TCP connection with the BGP state that two peers share.
- Prefix: a block of addresses written as an address and a length.
- Advertisement: a message that announces a prefix to a peer.

## The order of the commands

You read the facts from the ConfigMap and check that the router sees no peers. You label the worker nodes, apply the peer configuration, apply the cluster configuration, and check the session from the cluster side and from the router. At the end you change one value at a time to see how each mistake appears.

## The scenario

The network team of the `starfleet` cluster runs an external router. It asks the cluster team for three things.

1. Which nodes will open sessions to the router, and with which ASN?
2. How can both teams see that the sessions are up?
3. What does each configuration mistake look like, so that a failure is found fast?

The three parts answer these questions in this order.

At the end of the module you can show the answers with commands.

## What this module does not cover

The module does not announce any prefix. It also does not cover BGP route policies on the router, and it does not cover the older BGP implementation of Cilium that used a single policy resource. It uses the current resources of the BGP Control Plane.

## How to read the parts

Each part has commands that you run in the playground. The text describes the kind of output to expect and does not print exact values, because addresses differ on every machine. Read the output on your screen and compare it with the explanation.

Each part ends with a list of common mistakes.

The last page is a summary. When you finish it, the playground is destroyed. The resources that you created in it disappear with it.


## Why this matters for the exam

The BGP objectives of the Cilium certification ask you to configure peering and to explain what each resource does. You must also read the state of a session and name the likely cause. The example of this module is small, so each question has one clear answer.

Keep a short checklist in mind while you work: is the feature on, do the nodes carry the label, do the names match, do the ASNs and the address match the router, and does the status report a condition.

Start the playground now and keep it running while you read:

<!-- astrona:playground -->
