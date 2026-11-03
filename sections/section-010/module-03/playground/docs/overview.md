# Overview: Name And Entity Egress Rules (Playground)

This is a playground, not a lab. It starts a cluster and waits. There is no task and no `astrona submit`. Write policies, break them, run `astrona destroy` and start again.

## What is in the environment

- A three-node `kind` cluster running Kubernetes 1.35 without kube-proxy. Cilium 1.20.2 has eBPF masquerading and Hubble Relay on.
- Two external HTTP services in Docker containers on the `kind` network: the partner and a decoy.
- A CoreDNS `hosts` entry that answers `partner.lab.test` with the address of the partner.
- The pods `shuttle` (namespace `starfleet`) and `drifter` (namespace `outpost`), and the Deployment and Service `probe`.
- A ConfigMap `lab-env` in `starfleet` with `PARTNER_NAME`, `PARTNER_IP` and `DECOY_IP`.
- No network policy.

## Ideas to try

- Resolve and call `partner.lab.test` from `shuttle` before any policy.
- Apply a default deny policy and add the DNS rule and the `toFQDNs` rule step by step.
- Call the partner by address and see the connection fail.
- Replace the name rule with `toEntities: world` and add an `egressDeny` for the decoy address.
- Read the FQDN cache with `cilium-dbg fqdn cache list` in the agent on the node of `shuttle`.
