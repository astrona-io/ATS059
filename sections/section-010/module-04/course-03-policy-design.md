---
draft: true
exam_objectives:
- Egress Connectivity Requirements
---
# Policy Design

A gateway policy that selects too much redirects traffic that nobody meant to move. A policy that selects too little leaves workloads on the node address. This part covers how to write selectors and destinations that select exactly the right traffic, how to exclude ranges, and how to keep several policies from overlapping.

## Select pods

The field `selectors` is a list. Each entry has a `podSelector`, a `namespaceSelector` or both. A pod is selected when any entry matches it. Write the namespace into the entry. A `podSelector` that matches `app: shuttle` without a namespace selects every pod with that label in every namespace.

```yaml
  selectors:
  - namespaceSelector:
      matchLabels:
        team: starfleet
    podSelector:
      matchLabels:
        egress: partner
```

This entry selects pods with the label `egress: partner` in namespaces that have the label `team: starfleet`. A team can opt a pod in by setting the label. The label on the pod is the contract between the team and the platform.

## Select destinations

`destinationCIDRs` lists the destinations that use the gateway. Use the smallest ranges that cover the partner. A wide range such as `0.0.0.0/0` redirects all external traffic of the selected pods, including traffic to the nodes and to other clusters.

`excludedCIDRs` lists ranges inside `destinationCIDRs` that keep the normal path. A policy that sends all traffic to the gateway needs at least the exclusions for the ranges of the nodes and the pods, because those must not leave through the gateway.

```yaml
  destinationCIDRs:
  - 0.0.0.0/0
  excludedCIDRs:
  - 10.244.0.0/16
  - 172.18.0.0/16
```

The first exclusion is the pod range. The second is an example node range. Read the real ranges of your cluster before you write them.

## Overlapping policies

Two policies overlap when one pod and one destination match both. Cilium then has to pick one of them, and the choice is not a rule that you want to depend on. Avoid overlaps by design.

- Give every partner its own destination range and its own policy.
- Select pods by a label that belongs to one partner, not by a namespace that many partners share.
- Review the existing policies before you add one: `kubectl get ciliumegressgatewaypolicies -o yaml`.

<!-- astrona:playground:renew -->

You can look for overlaps with a command that prints each policy with its destinations:

```sh
kubectl get ciliumegressgatewaypolicies -o custom-columns=NAME:.metadata.name,DEST:.spec.destinationCIDRs,GW:.spec.egressGateway.egressIP
```

Compare the destination lists. Two rows with the same destination and a selector that covers the same pods are an overlap to resolve.

## The policy does not allow traffic

A gateway policy selects the path. It does not allow or deny anything. A pod with a default deny egress policy still needs an allow rule for the partner, and that rule matches the real destination address. The gateway policy and the network policy are two resources with two jobs.

## IPv4 and IPv6

The examples use IPv4 destinations. Check the documentation of your Cilium version for the support of IPv6 in the egress gateway before you use IPv6 ranges.

## What you can now do

You can select pods with namespace and pod labels, choose destination ranges, exclude ranges that must stay on the normal path, find overlapping policies, and say that the gateway policy never replaces a network policy.

## Common pitfalls

> [!WARNING]
> A `podSelector` without a namespace selects pods in all namespaces. A destination of `0.0.0.0/0` without exclusions redirects node and pod traffic. Overlapping policies give a result that depends on the implementation. A gateway policy does not allow traffic.
