---
estimated_duration: 25m
---

# Lab: Give shuttle A Fixed Source Address

Graded lab. **UNTESTED:** written from the Cilium documentation and never booted. Only static checks ran (`astrona validate`, `bash -n`).

A `CiliumEgressGatewayPolicy` must make the partner see the dedicated egress address for `shuttle` only. The task is in `question.md` and the walkthrough in `solution.md`.

```sh
astrona run -c .
astrona submit -c .
astrona destroy ats-059-lab-010-02-01
docker rm -f ats-059-lab-010-02-01-partner
```

| Script | What it proves |
| --- | --- |
| `validate-policy-exists.sh` | A gateway policy selects `shuttle` in `starfleet` with the partner `/32` |
| `validate-egress-ip-set.sh` | `egressIP` and the node selector match `lab-env` |
| `validate-shuttle-source-ip.sh` | The partner reports the gateway address for `shuttle` |
| `validate-drifter-source-ip.sh` | `drifter` does not use the gateway address |
| `validate-no-wildcard-destination.sh` | No `0.0.0.0/0` destination |

The bootstrap starts the partner container on the `kind` Docker network and adds a secondary address to the first worker node (`docker exec ... ip addr add`). `astrona destroy` does not remove the partner container.
