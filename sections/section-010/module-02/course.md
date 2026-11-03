---
draft: true
exam_objectives:
- Egress Connectivity Requirements
---
# Give Pods A Fixed Source Address With The Egress Gateway

Some external systems accept requests only from addresses on an allowlist. A partner bank, a licence server or a managed database often works like this. A pod in a Kubernetes cluster does not have a stable address, and the node address that the partner sees changes when the pod moves to another node. The Cilium egress gateway removes that problem: it makes the traffic of selected pods leave the cluster through one chosen node with one chosen address.

This module teaches how the feature works, how to configure it with a `CiliumEgressGatewayPolicy`, and how to find the cause when it does not work. Cilium is the Container Network Interface (CNI) plugin that connects the pods and enforces network policy. Its agent runs on every node and programs eBPF (extended Berkeley Packet Filter) programs in the Linux kernel. Those programs redirect and masquerade the packets.

## What you will learn

The three parts of the module build on one example: the `shuttle` pod in the `starfleet` namespace calls a partner service outside the cluster, and the partner must see the same source address for every call.

1. The first part explains why node addresses do not fit an allowlist, what the egress gateway is, and how a packet travels through the gateway node.
2. The second part writes the policy: pod selectors, destination ranges, the gateway node and the egress address. You measure the source address before and after.
3. The third part covers failures of the gateway node, the interaction with a `CiliumNetworkPolicy`, and a step-by-step diagnosis of a pod that cannot reach its partner.

## Learning objectives

After this module you can:

- Explain why a partner allowlist needs a fixed source address and why the default node address does not provide one.
- Describe the three parts of a `CiliumEgressGatewayPolicy` and name the Helm settings that the feature requires.
- Write a policy that selects pods by namespace and label, limits itself to partner destinations and names a gateway node and an egress address.
- Prove with the partner `/ip` path which source address a pod uses.
- Explain that a gateway policy chooses the path and never allows traffic, and combine it with a `CiliumNetworkPolicy`.
- State the limits of a single gateway node and diagnose a failing connection in order.

## Before you start

You need to know what a pod, a namespace and a node are, and you need basic `kubectl` and `curl` skills. You should know that Cilium masquerades traffic that leaves the cluster. You do not need to know BGP.

Your playground is a three-node `kind` cluster (one control plane node and two worker nodes) running Kubernetes 1.35 without kube-proxy. Cilium 1.20.2 is installed with Helm. eBPF masquerading and the egress gateway feature are on.

Next to the cluster, one more Docker container runs on the same Docker network: the partner. It is an HTTP service outside the cluster whose `/ip` path returns the source address of the caller in a field named `origin`. The setup also adds a second IPv4 address to the first worker node. That address is the dedicated egress address.

| Namespace | Object | What it is |
| --- | --- | --- |
| `starfleet` | pod `shuttle` | A client pod with `curl`, the pod you select |
| `starfleet` | Deployment and Service `probe` | An HTTP service inside the cluster |
| `outpost` | pod `drifter` | A second client pod, used for comparison |
| `starfleet` | ConfigMap `lab-env` | The partner address, the egress address and the gateway node name |

No policy exists at the start. Every pod reaches the partner with the address of its own node.

## Key terms

- Egress: traffic that leaves a pod toward a destination.
- Egress gateway: the Cilium feature that sends selected egress traffic through one node.
- Gateway node: the node that masquerades the selected traffic.
- Egress IP: the source address that the gateway node puts on the packets.
- CIDR: a block of IP addresses written as an address and a prefix length, for example `192.0.2.0/24`.
- Allowlist: a list of source addresses that a service accepts.

## The order of the commands

The commands follow one thread. You read the facts about the environment from the ConfigMap. You send a request and record the `origin` value. You apply a policy and send the request again. At the end you break the setup on purpose, one element at a time, and watch the symptom change. All commands work on the playground cluster only.

## The scenario

The partner of the `starfleet` team accepts requests from one source address only. The team asks three questions.

1. Which address does the partner see today, and why does it vary?
2. How do we make every call from `shuttle` arrive from one address?
3. What happens when something on the path fails, and how do we find it?

The three parts answer these questions in this order.

At the end you can answer each of them with a command and its output.

## What this module does not cover

The module does not cover BGP, and it does not cover how a cloud provider assigns addresses to nodes. It also does not cover the layer 7 features of Cilium. It stays with the egress gateway of the open-source Cilium agent.

## How to read the parts

Each part has commands that you run in the playground. The text describes the kind of output to expect and does not print exact numbers, because addresses differ on every machine. Read the output on your screen and compare it with the explanation.

Each part ends with a short list of common mistakes. The last page of the module is a summary of the topic. When you finish the summary, the playground is destroyed. Policies and pods that you created in it disappear with it.

## Why this matters for the exam

The egress connectivity requirements of the Cilium certification ask you to reason about the path of outbound traffic. You must know which component changes the source address, which resource controls it, and which symptom belongs to which failure. The example of this module is small on purpose, so that each of those questions has one clear answer.

Keep a short checklist in mind while you work: which pods are selected, which destinations match, which node is the gateway, and which address the node owns.

Start the playground now and keep it running while you read:

<!-- astrona:playground -->
