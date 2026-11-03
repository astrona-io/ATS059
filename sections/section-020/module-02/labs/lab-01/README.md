---
estimated_duration: 30m
---

# Lab: Advertise The probe Service And The Pod Prefixes

Graded lab. **UNTESTED:** written from the Cilium documentation and never booted. Only static checks ran (`astrona validate`, `bash -n`). The router checks use `docker exec` on the router container, so the validation needs Docker on the machine that runs `astrona submit`.

```sh
astrona run -c .
astrona submit -c .
astrona destroy ats-059-lab-020-02-01
docker rm -f ats-059-lab-020-02-01-router
```

| Script | What it proves |
| --- | --- |
| `validate-service-has-address.sh` | `probe-public` is a `LoadBalancer` Service with a pool address |
| `validate-service-advertisement.sh` | A `Service` advertisement with `LoadBalancerIP` and the label `advertise=bgp` |
| `validate-router-service-route.sh` | The router has a BGP `/32` route for the Service address |
| `validate-router-pod-prefixes.sh` | The router has routes for both worker pod prefixes |
| `validate-no-clusterip-advertised.sh` | No advertisement announces `ClusterIP` |

The bootstrap starts an FRR container on the `kind` Docker network, creates an established session on both workers and a pool `starfleet-pool`. `astrona destroy` does not remove the container.
