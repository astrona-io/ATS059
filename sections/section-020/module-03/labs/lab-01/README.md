---
estimated_duration: 25m
---

# Lab: Announce The probe Service With Layer 2

Graded lab. **UNTESTED:** written from the Cilium documentation and never booted. Only static checks ran (`astrona validate`, `bash -n`). The client check uses `docker exec` on a worker container, so the validation needs Docker on the machine that runs `astrona submit`.

```sh
astrona run -c .
astrona submit -c .
astrona destroy ats-059-lab-020-03-01
```

| Script | What it proves |
| --- | --- |
| `validate-service-has-address.sh` | `probe-public` is a `LoadBalancer` Service with a pool address |
| `validate-policy-selects-service.sh` | A policy selects the Service label and announces load balancer addresses |
| `validate-policy-selects-workers.sh` | The policy excludes control plane nodes |
| `validate-lease-holder-is-worker.sh` | A worker node holds the lease |
| `validate-reachable-from-network.sh` | A client on the node network reaches the address |
| `validate-no-open-policy.sh` | Every policy has a `serviceSelector` |

The Layer 2 behavior depends on the Docker network of the machine. On Docker Desktop the check from inside the node container is the reliable one.
