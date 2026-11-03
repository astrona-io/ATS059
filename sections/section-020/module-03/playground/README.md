# Layer 2 Announcements: Playground

Ungraded environment (`ats-059-playground-020-03`). **UNTESTED:** never booted. Three-node `kind` cluster, Cilium 1.20.2 with Layer 2 announcements and external IPs on, and a pool `starfleet-pool` with addresses from the Docker network of the nodes. No announcement policy and no `LoadBalancer` Service at the start.

```sh
astrona run -c .
astrona destroy ats-059-playground-020-03
```
