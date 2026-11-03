---
draft: true
exam_objectives:
- Understand Options to Connect Cilium-managed Clusters with External Networks
---
# Announce The probe Service With Layer 2

The office network has no router that speaks BGP, but clients on the same network as the nodes must reach the `probe` pods through one stable address. Create a Service of type `LoadBalancer` for them and announce its address with Layer 2 announcements. Only worker nodes may answer.

## Starting state

A three-node `kind` cluster runs Cilium with Layer 2 announcements. A pool named `starfleet-pool` holds addresses from the network of the nodes. The Deployment `probe` in `starfleet` has pods with the label `app: probe` that listen on port 8080. The Service `probe` is of type `ClusterIP`. No announcement policy exists.

The nodes are Docker containers on one network, so a request from inside a worker container acts as a client on that network:

```sh
WORKER=$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.WORKER_NODE}')
docker exec $WORKER curl -s --max-time 5 http://<ADDRESS>/ip
```

## Required result

- A Service `probe-public` in `starfleet` is of type `LoadBalancer`, has the label `announce: l2`, selects `app: probe`, exposes port 80 to target port 8080, and receives an address from the pool.
- A `CiliumL2AnnouncementPolicy` selects Services with the label `announce: l2` and announces load balancer addresses.
- The policy has a `nodeSelector` that excludes the control plane nodes with the key `node-role.kubernetes.io/control-plane` and the operator `DoesNotExist`.
- No policy lacks a `serviceSelector`.
- The lease `cilium-l2announce-starfleet-probe-public` in `kube-system` has a worker node as holder.
- A request from the worker container to the Service address returns a JSON document.

Submit when you are done:

```sh
astrona submit -c .
```
