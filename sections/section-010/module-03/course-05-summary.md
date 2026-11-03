---
draft: true
exam_objectives:
- Egress Connectivity Requirements
---
# Summary

Name-based egress policy lets a rule follow a partner whose addresses change. The packet carries only addresses, so the Cilium agent builds the link between the name and the address itself. A DNS rule with `rules.dns` sends the DNS traffic of the pod through the DNS proxy of the agent. The proxy checks the name, forwards the request and reads the answer. When the name matches a `toFQDNs` rule, the agent stores the address with its TTL and adds it to the allowed destinations before it returns the answer to the pod.

Two consequences follow. A `toFQDNs` rule without the DNS rule never matches, and a connection to an address without a lookup is blocked. The decision is made on the address, so another name with the same address is allowed too.

A rule matches a name with `matchName` for an exact name and with `matchPattern` for wildcard names. A wildcard such as `*.partner.example` does not match the apex name `partner.example`, so both need entries. An allowed address stays in the cache for the TTL of the answer, plus any minimum TTL that the agent sets. Open connections continue after expiry, and new connections need a new lookup.

Destinations without a name use other rule types. Entities group destinations that Cilium knows: `world` for everything outside the cluster, `cluster`, `host`, `remote-node` and `kube-apiserver`. Pods in the cluster use `toEndpoints`. A Service without a selector that points outside uses `toServices`. Address ranges use `toCIDR` and `toCIDRSet`. A deny rule wins over every allow rule, which makes a wide `world` rule with a few deny ranges a workable pattern.

To diagnose a failure, check in order: the lookup from the pod, the FQDN cache of the agent on the node of the pod, DNS and drop flows in Hubble, and the enforcement state of the endpoint. The cache shows whether the proxy saw an answer, and the flows show whether the connection itself was dropped.

<!-- astrona:playground:destroy -->
