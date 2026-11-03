---
estimated_duration: 25m
---

# Lab: Make The Router Receive The probe-public Address

Graded lab. **UNTESTED:** written from the Cilium documentation and never booted. Only static checks ran (`astrona validate`, `bash -n`). The router checks use `docker exec`, so the validation needs Docker on the machine that runs `astrona submit`.

```sh
astrona run -c .
astrona submit -c .
astrona destroy ats-059-lab-020-04-01
```

| Script | What it proves |
| --- | --- |
| `validate-sessions-established.sh` | Both workers keep an established session |
| `validate-advertisement-selected.sh` | The peer configuration selects an existing advertisement |
| `validate-service-labeled.sh` | The Service has the label that the advertisement selects |
| `validate-community-set.sh` | The Service advertisement sets `64513:100` |
| `validate-router-has-route.sh` | The router has a path to the address |
| `validate-router-sees-community.sh` | The router shows the community on the path |
