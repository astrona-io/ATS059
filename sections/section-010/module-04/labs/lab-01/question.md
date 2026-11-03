---
draft: true
exam_objectives:
- Egress Connectivity Requirements
---
# Move The Egress Gateway To The Second Worker

The platform team must take the first worker node out of service. The partner now allows the second egress address, and the gateway for `shuttle` must move to the second worker. Select the gateway by a role label from now on, so the next move needs no policy change.

## Starting state

A three-node `kind` cluster runs Cilium with eBPF masquerading and the egress gateway. The pods `shuttle` (namespace `starfleet`) and `drifter` (namespace `outpost`) run `curl`. The partner is an HTTP service outside the cluster on port 8080. Its `/ip` path returns the source address of the caller in the field `origin`.

The policy `shuttle-to-partner` sends `shuttle` through the first worker. The second worker already owns its egress address. The ConfigMap `lab-env` in `starfleet` holds the facts:

```sh
kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.PARTNER_IP}'
kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.GATEWAY2_IP}'
kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.GATEWAY2_NODE}'
```

## Required result

- The node named in `GATEWAY2_NODE` has the label `role=egress-gateway`. No other node has it.
- A `CiliumEgressGatewayPolicy` selects the gateway node with `nodeSelector` on the label `role=egress-gateway`, not with the host name.
- The `egressIP` of the policy is the value of `GATEWAY2_IP`.
- The policy still selects only `shuttle` in `starfleet`, and its destination is still the partner as one `/32` prefix.
- A new request from `shuttle` to `/ip` of the partner returns `GATEWAY2_IP` as `origin`.
- `drifter` is not selected.

Submit when you are done:

```sh
astrona submit -c .
```
