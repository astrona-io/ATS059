---
estimated_duration: 25m
---

# Lab: Peer The Worker Nodes With The External Router

Graded lab. **UNTESTED:** written from the Cilium documentation and never booted. Only static checks ran (`astrona validate`, `bash -n`). The field `status.bgpInstances[].peers[].peeringState` that the validation reads is taken from the documented status; confirm it on the first live run.

```sh
astrona run -c .
astrona submit -c .
astrona destroy ats-059-lab-020-01-01
docker rm -f ats-059-lab-020-01-01-router
```

| Script | What it proves |
| --- | --- |
| `validate-cluster-config.sh` | The cluster configuration peers the right ASNs and router address |
| `validate-peer-config-exists.sh` | The referenced peer configuration exists with `ipv4/unicast` |
| `validate-workers-select.sh` | Only workers have a node configuration |
| `validate-worker-established.sh` | First worker session established |
| `validate-worker2-established.sh` | Second worker session established |

The bootstrap starts an FRR container (`ats-059-lab-020-01-01-router`) on the `kind` Docker network. `astrona destroy` does not remove it.
