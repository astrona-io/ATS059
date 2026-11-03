---
draft: true
exam_objectives:
- Egress Connectivity Requirements
---
# Inspecting And Diagnosing Name-Based Policy

A name-based rule has more moving parts than an address rule: the DNS proxy, the cache and the TTL. When a connection fails, you need to know which part failed. This part gives a fixed order of checks and the commands that show each part: the DNS cache of the agent, the flows in Hubble, and the policy of the endpoint.

## Check in this order

1. Does the pod resolve the name? Run `nslookup` or `curl` from the pod. A resolution error means the DNS rule is missing or CoreDNS fails.
2. Did the proxy see the answer? The FQDN cache of the agent lists the name and the addresses.
3. Is the address in the allowed list? The policy of the endpoint shows the selectors that match.
4. Is the connection dropped for another reason, such as the port? Hubble shows the verdict.

## The FQDN cache

The agent on the node of the pod keeps the cache. List it with the agent command:

<!-- astrona:playground:renew -->

```sh
kubectl -n kube-system get pods -l k8s-app=cilium -o wide
kubectl -n kube-system exec <AGENT_ON_NODE_OF_SHUTTLE> -- cilium-dbg fqdn cache list
```

The output has one line for each learned name and address, with the TTL and the time at which the entry expires. A name that is missing from the list means that the proxy never saw an answer for it. Common causes are a missing `rules.dns` section, a pod that uses another resolver, or a lookup that ran before the policy was applied. Run the lookup again after you apply the policy.

The agent can clear the cache with `cilium-dbg fqdn cache clean`. Use it in a test to prove that the pod needs a new lookup, and not in production, because every pod loses its learned addresses until the next lookup.

## DNS flows in Hubble

Hubble records DNS requests and answers as flows when the DNS proxy sees them. Filter by protocol to read them:

```sh
kubectl -n kube-system exec <AGENT_ON_NODE_OF_SHUTTLE> -- hubble observe --from-pod starfleet/shuttle --protocol dns --last 20
```

A forwarded DNS flow shows the query name. A dropped DNS flow means the `rules.dns` patterns did not allow the name. Then read the policy verdicts of the connection itself:

```sh
kubectl -n kube-system exec <AGENT_ON_NODE_OF_SHUTTLE> -- hubble observe --from-pod starfleet/shuttle --verdict DROPPED --last 20
```

A connection that is dropped right after a forwarded DNS answer for the right name points to the port in the rule, to an address that does not match, or to an expired TTL.

## The policy of the endpoint

`cilium-dbg endpoint list` prints the endpoints of the node, each with an ID, and a column that says whether egress policy is enforced. `cilium-dbg endpoint get <ID>` prints the details of one endpoint as JSON, including the policy that applies to it. Read the ID of the `shuttle` endpoint from the list, and check that the column for egress enforcement says `Enabled`. An endpoint that shows `Disabled` is not selected by any policy, so the policy does not match its labels.

## Common failure patterns

- The name resolves, the connection to the address fails, and the cache has no entry: the `toFQDNs` rule does not match the name. Check spelling and the apex case.
- The cache has the entry, and the connection fails: the port or protocol in `toPorts` differs.
- The first connection works and later ones fail after some minutes: the TTL ended and the application did not resolve again.
- The lookup fails with a refused or timed-out answer: the DNS rule selects the wrong CoreDNS labels, or the policy blocks UDP and TCP port 53.

## What you can now do

You can check a name-based policy in a fixed order, read the FQDN cache, read DNS and drop flows in Hubble, check that a policy selects the endpoint, and map the common symptoms to their causes.

## Common pitfalls

> [!WARNING]
> Run the cache and Hubble commands against the agent on the node of the pod, not against any agent. Clearing the cache removes the learned addresses of all pods on the node. Test again with a new lookup after every change of the policy.
