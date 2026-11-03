# Overview: Operating The Egress Gateway (Playground)

This is a playground, not a lab. It starts a cluster and waits. There is no task and no `astrona submit`. Change the policy, move the gateway, run `astrona destroy` and start again.

## What is in the environment

- A three-node `kind` cluster running Kubernetes 1.35 without kube-proxy. Cilium 1.20.2 has eBPF masquerading, kube-proxy replacement, the egress gateway and Hubble Relay on.
- An external HTTP partner in a Docker container. Its `/ip` path returns the source address of the caller.
- The first worker has the extra address `GATEWAY_IP`, and the second worker has `GATEWAY2_IP`, both with prefix length 32 on `eth0`.
- The policy `shuttle-to-partner` selects `shuttle` and sends traffic to the partner through the first worker.
- The pods `shuttle` (namespace `starfleet`) and `drifter` (namespace `outpost`).
- A ConfigMap `lab-env` in `starfleet` with `PARTNER_IP`, `GATEWAY_IP`, `GATEWAY_NODE`, `GATEWAY2_IP` and `GATEWAY2_NODE`.

## Ideas to try

- Run `cilium-dbg bpf egress list` in the agent on the node of `shuttle`.
- Label the second worker with `role=egress-gateway` and select the label in the policy.
- Move the gateway to the second worker and check the `origin` at the partner.
- Delete the label and see what happens to the policy table.
- Add an `excludedCIDRs` entry and check that the exempt destination keeps the node address.
