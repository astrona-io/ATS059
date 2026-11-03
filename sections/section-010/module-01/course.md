---
draft: true
exam_objectives:
- Egress Connectivity Requirements
---
# Trace Outbound Traffic From Pods To External Services

A pod in a Kubernetes cluster often has to call a system that is not part of the cluster: a partner API, a database in another network, a software update server. This outbound direction is called egress. Egress looks simple from inside the pod, because the application only opens a connection. Underneath, four separate mechanisms decide whether the connection works: the route the packet takes out of the node, the address translation that changes the source address, the network policy that allows or denies the destination, and the return path that brings the reply back to the right pod.

This module teaches you to follow one outbound request through all four mechanisms and to say, for each of them, which component does the work. Cilium is the Container Network Interface (CNI) plugin that connects pods to the network and enforces network policy. Its agent runs on every node as the `cilium` DaemonSet and programs eBPF (extended Berkeley Packet Filter) programs in the Linux kernel. Those programs handle the packets of every pod on the node.

## What you will learn

The three parts of the module build on one example: the `shuttle` pod in the `starfleet` namespace calls an external HTTP service called the partner.

1. The first part follows the packet from the pod to the partner. You see where Cilium translates the source address (masquerading), which destinations it translates for, and what the partner records as the caller.
2. The second part controls which destinations a pod may reach. You write a default deny egress policy, allow DNS, and allow one external address with `toCIDR`. You also learn how `toFQDNs` rules work and why they need a DNS rule.
3. The third part is about source identity and return paths. You learn why an external allowlist sees a node address, why the reply needs a route back, and how to diagnose a failed outbound connection step by step.

## Learning objectives

After this module you can:

- Describe the path of a packet from a pod to an external address, and name the component that makes each decision.
- Explain masquerading, state when Cilium applies it, and name the settings `bpf.masquerade` and `ipv4NativeRoutingCIDR`.
- Write a `CiliumNetworkPolicy` that denies all egress for a pod except DNS and one external address.
- Explain what `toFQDNs` rules need from the DNS proxy and why a DNS rule must come with them.
- Predict which source address an external service sees, and explain why a reply can fail to arrive.
- Use `curl`, `kubectl`, and the Cilium agent commands to find which stage of an outbound connection fails.

## Before you start

You need to know what a pod, a namespace, a Service, and a Deployment are, and you need basic `kubectl` and `curl` skills. You do not need to know BGP or eBPF.

Your playground is a three-node `kind` cluster (one control plane node and two worker nodes) that runs Kubernetes 1.35 without kube-proxy. Cilium 1.20.2 is installed with Helm. It replaces kube-proxy and uses eBPF masquerading. The cluster runs in Docker containers on your machine.

Next to the cluster, one more Docker container runs on the same Docker network. It is the partner: an HTTP service that is outside the cluster. Its `/ip` path returns the source address of the caller in a field named `origin`. This is how you see which address your traffic carries when it leaves the cluster.

| Namespace | Object | What it is |
| --- | --- | --- |
| `starfleet` | pod `shuttle` | A client pod with `curl`, the pod you test from |
| `starfleet` | Deployment and Service `probe` | An HTTP service inside the cluster |
| `outpost` | pod `drifter` | A second client pod in another namespace |
| `starfleet` | ConfigMap `lab-env` | The addresses of the partner container, read with `kubectl` |

No `CiliumNetworkPolicy` exists at the start, so every pod can reach every destination.

## Key terms

These terms appear in every part. Each part defines them again where it first needs them.

- Egress: traffic that leaves a pod toward a destination.
- Masquerading: rewriting the source address of an outgoing packet to the address of the node.
- Source NAT (network address translation): the general name for rewriting a source address.
- CiliumNetworkPolicy: the Cilium resource that allows or denies traffic for selected pods.
- DNS proxy: the component inside the Cilium agent that reads DNS queries and answers of selected pods.
- CIDR: a block of IP addresses written as an address and a prefix length, for example `192.0.2.0/24`.
- Return path: the route that a reply takes from the external service back to the pod.

## The order of the commands

The commands in the parts follow one thread. First you read the address of the partner. Then you send a request from a pod and compare the source address that the partner reports with the pod address. Then you add policies that restrict the pod, one rule at a time. At the end you diagnose a failure by testing each stage separately. Every command works on the playground cluster only and does not change your machine.

## The scenario

The `shuttle` pod in `starfleet` must send requests to a partner service that runs outside the cluster. The security team asks three questions.

1. Which source address does the partner see when `shuttle` calls it?
2. Can `shuttle` reach only the partner, and nothing else outside the cluster?
3. If the call fails, how do you find out which stage failed?

The three parts answer these questions in this order. Keep them in mind while you read. At the end of the module you can answer each one with a command and its output, not with a guess.

## What this module does not cover

The module does not teach how to give a pod a fixed source address. It does not teach BGP. It stays with the default behavior of Cilium: the node address as source, policy as the filter, and the return path as the condition for a working reply.

## How to read the parts

Each part has commands that you run in the playground. The commands show the kind of output to expect and describe it in words, because addresses differ on every machine. Read the output on your screen and compare it with the explanation, not with exact numbers.

Each part ends with a short list of common mistakes. The last page of the module is a summary of the whole topic.


## How the playground ends

When you finish the last part, the summary page destroys the playground. Policies and pods that you created in it are removed with it. Start it again at any time to repeat an experiment from a clean state.

Keep one terminal open for `kubectl` commands. Each command in the parts is short and prints its result at once, so you can run it and read the output before you go on.

Start the playground now and keep it running while you read:

<!-- astrona:playground -->
