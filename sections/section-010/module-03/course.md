---
draft: true
exam_objectives:
- Egress Connectivity Requirements
---
# Allow External Services By Name And Entity

Most egress rules in real clusters do not name an IP address. Partners and cloud services change addresses, and the cluster also needs rules for the Kubernetes API server, the nodes and the rest of the internet. Cilium has rule types for these cases: rules by DNS name (`toFQDNs`), rules by entity (`toEntities`) and rules by Service (`toServices`). This module explains how each one works, what it needs from the DNS proxy and the identity system, and how to check it.

Cilium is the Container Network Interface (CNI) plugin of the cluster. Its agent runs on every node. The agent contains a DNS proxy that sees the DNS requests and responses of the pods, and it assigns a security identity (a number) to every endpoint, node and group of external addresses.

## What you will learn

The four parts build on one example: the `shuttle` pod in `starfleet` may call the partner by name, `partner.lab.test`, and nothing else outside the cluster.

1. The first part explains how a `toFQDNs` rule works: the DNS rule, the DNS proxy, the cache of names and addresses, and the order in which the pod resolves and connects.
2. The second part covers how names are matched: `matchName`, `matchPattern`, time to live (TTL) and the cases that do not match.
3. The third part covers the other destination types: entities such as `world`, `cluster` and `kube-apiserver`, Services without selectors, and endpoints in the cluster.
4. The fourth part is about inspecting and diagnosing name-based policy with the agent cache, Hubble and the policy trace.

## Learning objectives

After this module you can:

- Explain why a `toFQDNs` rule must come with a DNS rule that has `rules.dns`.
- Write `matchName` and `matchPattern` rules and predict which names they match.
- Explain how the TTL of a DNS answer limits the time that an address stays allowed.
- Choose between `toCIDR`, `toFQDNs`, `toEntities` and `toServices` for a destination.
- Name the entities `world`, `cluster`, `host`, `remote-node` and `kube-apiserver` and say what each one selects.
- Read the DNS cache of the agent and the DNS flows in Hubble to find out why a name is blocked.

## Before you start

You need to know how to write a `CiliumNetworkPolicy` with a default deny egress rule and a DNS rule. The first module of this section covers it.

Your playground is a three-node `kind` cluster running Kubernetes 1.35 without kube-proxy. Cilium 1.20.2 is installed with Helm. Two HTTP services run outside the cluster in Docker containers on the same network as the nodes: the partner and a decoy. CoreDNS answers the name `partner.lab.test` with the address of the partner, through a `hosts` entry that the playground adds.

| Namespace | Object | What it is |
| --- | --- | --- |
| `starfleet` | pod `shuttle` | A client pod with `curl`. No policy exists at the start. |
| `outpost` | pod `drifter` | A second client pod |
| `starfleet` | Deployment and Service `probe` | An HTTP service inside the cluster |
| `starfleet` | ConfigMap `lab-env` | The partner name, the partner address and the decoy address |

## Key terms

- FQDN: a fully qualified domain name, such as `partner.lab.test`.
- DNS proxy: the component of the Cilium agent that sits on the DNS traffic of the pods and records the answers.
- Entity: a built-in group of destinations that Cilium defines, such as `world` or `kube-apiserver`.
- Security identity: the number that Cilium assigns to a group of endpoints or addresses and that policy matches.

## The order of the commands

You read the name and the address of the partner. You resolve the name from `shuttle` and connect. You apply a default deny policy and watch the name stop working. You add the DNS rule and the `toFQDNs` rule and watch it work again. At the end you read the cache of the agent and the DNS flows.

## What this module does not cover

The module does not cover rules for HTTP paths and methods (Layer 7 rules for HTTP), and it does not cover the egress gateway. The previous module in this section covers the basics of egress policy and the next module covers the gateway.

## How to read the parts

Each part has commands that you run in the playground. The text describes the kind of output to expect, because addresses differ on every machine. Each part ends with a list of common mistakes. The last page is a summary. When you finish it, the playground is destroyed.

## Why this matters for the exam

The Cilium certification expects you to know how a name-based rule works and how it differs from an address rule. A common mistake is a `toFQDNs` rule without a DNS rule: the pod cannot resolve the name, so the rule never matches.

Start the playground now and keep it running while you read:

<!-- astrona:playground -->
