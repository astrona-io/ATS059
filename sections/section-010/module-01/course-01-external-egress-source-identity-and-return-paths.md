---
draft: true
exam_objectives:
- Egress Connectivity Requirements
---
# External Egress, Source Identity And Return Paths

A workload reaching an external service crosses boundaries outside the local Kubernetes Service model. DNS, routing, source identity, infrastructure filtering and application trust all contribute. A policy allowing egress is one necessary relationship in some designs, but it does not automatically establish every stage of the outbound path.

## Resolve The Intended Destination

The application can use a hostname whose addresses change. DNS access must be permitted and the response must identify the intended destination. FQDN-aware policy has its own supported observation and address lifecycle. A cached address can differ from a current lookup, so correlate the actual attempted destination with the policy and routing state.

TLS certificate validation and application authentication provide additional trust. Reaching an IP associated with a hostname does not independently prove the server's application identity. Network access and credential authority should be narrow enough for the workload's responsibility.

## Forward And Return Routes Must Work

A packet can leave the node yet fail to receive a response if the external system lacks a route back to its source. Native Pod addressing may require infrastructure routes, while masquerading can translate the source to an address with a supported return path. Infrastructure firewalls and connection state can also constrain the response.

Review both directions. A successful outbound observation is partial evidence and does not guarantee the reply reaches the application. Packet size, encryption or tunnel overhead can create additional path constraints that affect larger transfers differently from connection setup.

## Source Identity Can Change

Masquerading can make an external service see a node or other translated address. That affects allowlists, logs and rate limiting. The external source is therefore not always the original Pod address or network identity. Choose the supported source-preservation or translation model according to the integration requirement.

A workload recreated on another node can change its externally visible source under some arrangements. If an external partner requires predictable source addresses, a documented egress gateway design can provide selected outbound traffic with a controlled source path. It still needs eligible nodes, addresses and supported routing behavior.

## A Gateway Is Not A Universal Allow

Cilium's egress gateway feature selects supported traffic for gateway handling under its configuration and prerequisites. It does not replace endpoint network authorization or application credentials. A gateway path can be correctly configured while policy denies the workload, or policy can allow traffic while the gateway's external route fails.

Selection, exclusions and gateway failure behavior need explicit review. A new endpoint or configuration update can have convergence timing, and unsupported combinations can limit the feature. Do not claim universal seamless failover or coverage of every protocol without the intended version's contract.

## Preserve Security And Diagnosis

Suppose an external database rejects a client after source translation changes. Review the visible source and database allowlist rather than weaken all egress policy. If DNS is blocked, correct the resolver relationship instead of add an unrestricted internet rule. If TLS validation fails, inspect hostname and trust rather than disable certificate verification.

Map the destination, source transformation, routing, permission and application outcome. This keeps the boundary precise and identifies the owner of the failed relationship, including external dependencies beyond Cilium's local control.

## Common pitfalls

> [!WARNING]
> An egress allow is not route or trust proof. Source translation changes external identity, while gateway selection, return routing and application authorization have separate contracts.
