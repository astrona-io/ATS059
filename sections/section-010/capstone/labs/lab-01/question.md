---
draft: true
exam_objectives:
- Egress Connectivity Requirements
---
# Capstone: A Restricted Partner Connection With A Fixed Source Address

The partner of the `starfleet` team has two requirements. It accepts requests from one source address only, and the security team wants the `shuttle` pod to reach nothing else outside the cluster. Build both controls and keep the other workloads unchanged.

## Starting state

A three-node `kind` cluster runs Cilium with eBPF masquerading and the egress gateway. The pods `shuttle` (namespace `starfleet`) and `drifter` (namespace `outpost`) run `curl`. The partner is an HTTP service outside the cluster on port 8080. Its `/ip` path returns the source address of the caller in the field `origin`. A router container also runs outside the cluster and listens on TCP port 179.

The ConfigMap `lab-env` in `starfleet` holds `PARTNER_IP`, `GATEWAY_IP`, `GATEWAY_NODE` and `ROUTER_IP`. The address `GATEWAY_IP` is already added to the node `GATEWAY_NODE`. No policy exists.

## Required result

- `shuttle` reaches the partner on TCP port 8080 and receives HTTP 200.
- The partner sees `GATEWAY_IP` as the source address of requests from `shuttle`.
- `shuttle` cannot open a connection to any other external address, for example `ROUTER_IP` on port 179.
- `shuttle` still resolves cluster DNS names.
- `drifter` in `outpost` is unchanged: it reaches the partner and the partner does not see `GATEWAY_IP`.
- No policy uses a wildcard destination (`0.0.0.0/0`, `world` or `all`). The partner is written as one `/32` prefix in both policies.

Submit when you are done:

```sh
astrona submit -c .
```
