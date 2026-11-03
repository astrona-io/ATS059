---
draft: true
exam_objectives:
- Egress Connectivity Requirements
---
# Allow The Partner By Name

The partner of the `starfleet` team changes its address from time to time, but its name stays the same. Write an egress policy for the `shuttle` pod that allows the partner by name, allows DNS, and blocks every other external destination.

## Starting state

A three-node `kind` cluster runs Cilium. The pods `shuttle` (namespace `starfleet`) and `drifter` (namespace `outpost`) run `curl`. Two HTTP services run outside the cluster on port 8080: the partner and a decoy. CoreDNS resolves the partner name to the partner address. No network policy exists.

The ConfigMap `lab-env` in `starfleet` holds the facts:

```sh
kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.PARTNER_NAME}'
kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.PARTNER_IP}'
kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.DECOY_IP}'
```

## Required result

- A `CiliumNetworkPolicy` in `starfleet` selects the pods with the label `app: shuttle`.
- The policy allows DNS to the CoreDNS pods (label `k8s-app: kube-dns` in `kube-system`) on port 53, with a `rules.dns` section.
- The policy allows the partner with a `toFQDNs` rule that uses `matchName` with the value of `PARTNER_NAME`, on port 8080 and protocol TCP.
- No rule allows the entity `world`, the entity `all`, the range `0.0.0.0/0` or the name pattern `*` as a destination.
- A request from `shuttle` to `http://<PARTNER_NAME>:8080/ip` returns a JSON document with the field `origin`.
- A request from `shuttle` to the decoy address on port 8080 fails.
- `drifter` is not affected: its request to the decoy works.

Submit when you are done:

```sh
astrona submit -c .
```
