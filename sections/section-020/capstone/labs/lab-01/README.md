---
estimated_duration: 45m
---

# Capstone Lab: Publish The probe Service To The External Router

Graded capstone. **UNTESTED:** written from the Cilium documentation and never booted. Only static checks ran (`astrona validate`, `bash -n`). The field `status.bgpInstances[].peers[].peeringState` and the router checks through `docker exec` are the points to confirm on the first live run.

```sh
astrona run -c .
astrona submit -c .
astrona destroy ats-059-capstone-020
docker rm -f ats-059-capstone-020-partner ats-059-capstone-020-router
```

| Script | What it proves |
| --- | --- |
| `validate-sessions-established.sh` | Both workers established, control plane runs no BGP |
| `validate-peer-options.sh` | Graceful restart on, hold time 30 seconds or less |
| `validate-service-address.sh` | `probe-public` has a pool address |
| `validate-router-routes.sh` | Router has the Service route and the pod prefixes |
| `validate-no-clusterip-advertised.sh` | No `ClusterIP` announced |

The bootstrap starts partner and router containers and creates the pool. `astrona destroy` does not remove the containers.
