---
draft: true
exam_objectives:
- Egress Connectivity Requirements
---
# Give shuttle A Fixed Source Address

The partner of the `starfleet` team accepts requests from one address only. Today the partner sees the address of the node that runs the `shuttle` pod, and that address changes when the pod moves. Make every request from `shuttle` to the partner arrive from the dedicated egress address, and leave all other pods alone.

## Starting state

A three-node `kind` cluster runs Cilium with eBPF masquerading and the egress gateway feature. The pods `shuttle` (namespace `starfleet`) and `drifter` (namespace `outpost`) run `curl`. The partner is an HTTP service outside the cluster on port 8080. Its `/ip` path returns the source address of the caller in the field `origin`.

The ConfigMap `lab-env` in `starfleet` holds the facts you need. The address is already added to the gateway node:

```sh
kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.PARTNER_IP}'
kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.GATEWAY_IP}'
kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.GATEWAY_NODE}'
```

No policy exists yet.

## Required result

- A `CiliumEgressGatewayPolicy` selects the `shuttle` pods in the `starfleet` namespace.
- The policy applies only to the partner address, written as one `/32` prefix. No wildcard destination (`0.0.0.0/0`).
- The gateway node is the node named in `GATEWAY_NODE`, selected with the label `kubernetes.io/hostname`.
- The `egressIP` is the value of `GATEWAY_IP`.
- A request from `shuttle` to `/ip` of the partner returns the gateway address as `origin`.
- `drifter` is not selected. Its requests do not carry the gateway address.

Submit when you are done:

```sh
astrona submit -c .
```
