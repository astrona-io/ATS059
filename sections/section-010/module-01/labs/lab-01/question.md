---
draft: true
exam_objectives:
- Egress Connectivity Requirements
---
# Limit Egress To One External Partner

The `shuttle` pod in `starfleet` must call the partner service that runs outside the cluster. A security review found that it can reach every external address. Limit it to the partner and nothing else, without breaking name resolution and without affecting other pods.

## Starting state

A three-node `kind` cluster runs Cilium with eBPF masquerading. The pods `shuttle` (namespace `starfleet`) and `drifter` (namespace `outpost`) run `curl`. Two HTTP services run outside the cluster on port 8080: the partner and a decoy. Their addresses are in the ConfigMap `lab-env` in `starfleet`:

```sh
kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.PARTNER_IP}'
kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.DECOY_IP}'
```

No network policy exists yet.

## Required result

- `shuttle` reaches the partner on TCP port 8080.
- `shuttle` cannot reach the decoy or any other external address.
- `shuttle` still resolves names with the cluster DNS.
- The partner is allowed by its address as a single `/32` prefix, with a `toCIDR` rule. No wildcard destination (`0.0.0.0/0`, `world` or `all`).
- `drifter` in `outpost` still reaches external services.

Use a `CiliumNetworkPolicy` in the `starfleet` namespace. Submit when you are done:

```sh
astrona submit -c .
```
