# Overview: Layer 2 Announcements (Playground)

This is a playground, not a lab. It starts a cluster and waits. There is no task and no `astrona submit`. Apply resources, change them and run `astrona destroy` to start again.

## What is in the environment

- A three-node `kind` cluster running Kubernetes 1.35 without kube-proxy. Cilium 1.20.2 has Layer 2 announcements, external IPs and the Cilium client rate limits on.
- A `CiliumLoadBalancerIPPool` named `starfleet-pool` with the range `POOL_START` to `POOL_STOP` from the Docker network of the nodes.
- The Deployment and ClusterIP Service `probe` and the pod `shuttle` in `starfleet`, the pod `drifter` in `outpost`.
- A ConfigMap `lab-env` in `starfleet` with `WORKER_NODE`, `POOL_START`, `POOL_STOP` and `POOL_BASE`.
- No announcement policy.

## Ideas to try

- Create a `LoadBalancer` Service and call its address from the worker container with `docker exec`.
- Apply a `CiliumL2AnnouncementPolicy` and call the address again.
- Read the lease of the Service and `ip neigh show` for the address.
- Stop the container of the lease holder and watch the lease move.
- Remove the `serviceSelector` and see which Services are announced.
