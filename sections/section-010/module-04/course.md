---
draft: true
exam_objectives:
- Egress Connectivity Requirements
---
# Operate The Egress Gateway

A gateway policy that works on the first day is only the start. Over the life of a cluster, the gateway node needs maintenance, the partner changes its allowlist and teams ask to add workloads. This module covers the operational side of the egress gateway: the cluster requirements, how to choose and label gateway nodes, how to design policies that stay readable, and how to move the gateway to another node without surprises.

Cilium is the Container Network Interface (CNI) plugin of the cluster, and its agent runs on every node. The egress gateway is a feature of the agent: it compiles each `CiliumEgressGatewayPolicy` into eBPF maps, forwards selected traffic to the gateway node and translates the source address there.

## What you will learn

The four parts build on one example: the partner accepts one address, the address of the gateway node, and the platform team must move the gateway from the first worker node to the second one.

1. The first part covers what the cluster needs for the feature, how to check that it is on, and what to read in the agent when a policy does not work.
2. The second part covers how to choose gateway nodes: node labels, a role label, the `egressIP` field and the `interface` field, and how to check that a node owns the address.
3. The third part covers policy design: selectors, destination ranges, exclusions and what happens when policies overlap.
4. The fourth part is a runbook for changing the gateway: moving it to another node, maintenance of the gateway node and what happens to open connections.

## Learning objectives

After this module you can:

- Name the Helm values that the egress gateway needs and check that the agent has the feature on.
- Label a node as a gateway and select it with a `nodeSelector` on the role label.
- Choose between `egressIP` and `interface` and check that the node owns the source address.
- Write selectors and destination ranges that select exactly the intended traffic, with `excludedCIDRs` for exceptions.
- Explain why overlapping policies are hard to reason about and how to avoid them.
- Move a gateway to another node in a safe order and say what happens to open connections.

## Before you start

You need to know what a `CiliumEgressGatewayPolicy` is and what its fields do. The previous module in this section covers it.

Your playground is a three-node `kind` cluster (one control plane node and two worker nodes) running Kubernetes 1.35 without kube-proxy. Cilium 1.20.2 is installed with eBPF masquerading and the egress gateway on. The partner is an HTTP service outside the cluster on port 8080. Its `/ip` path returns the source address of the caller.

The first worker node has the egress address `GATEWAY_IP`, and the second worker node has a second address `GATEWAY2_IP`. A policy `shuttle-to-partner` already sends traffic of `shuttle` to the partner through the first worker.

| Namespace | Object | What it is |
| --- | --- | --- |
| `starfleet` | pod `shuttle` | A client pod with `curl`, selected by the policy |
| `outpost` | pod `drifter` | A second client pod, not selected |
| `starfleet` | ConfigMap `lab-env` | The partner address, both gateway nodes and both gateway addresses |

## Key terms

- Gateway node: the node through which selected traffic leaves the cluster.
- Egress address: the source address that the gateway node uses for that traffic.
- Role label: a label that marks a node for a purpose, for example `role=egress-gateway`.

## The order of the commands

You check that the feature is on. You read the policy and the eBPF table of the agent. You label the second worker as a gateway. You change the policy to select the label and use the second address, then you check the partner and the table again.

## What this module does not cover

The module does not cover high availability of the gateway in Cilium Enterprise, and it does not cover BGP announcements of the egress address. The BGP section covers sessions and advertisements.

## How to read the parts

Each part has commands that you run in the playground. The text describes the kind of output to expect. Each part ends with a list of common mistakes. The last page is a summary. When you finish it, the playground is destroyed.

## Why this matters for the exam

The Cilium certification expects you to know that the egress gateway needs eBPF masquerading and kube-proxy replacement, that the egress address must belong to the gateway node, and that a gateway policy does not allow traffic by itself.

Start the playground now and keep it running while you read:

<!-- astrona:playground -->
