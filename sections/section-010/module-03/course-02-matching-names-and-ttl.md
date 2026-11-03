---
draft: true
exam_objectives:
- Egress Connectivity Requirements
---
# Matching Names And TTL

A name rule is only as good as its match. This part covers the two ways to write a name in a rule, what they match and what they do not, and the TTL (time to live) that limits how long a learned address stays allowed. These details decide whether a policy works for a partner that has many names and changing addresses.

## matchName

`matchName` is an exact name. The name is compared in lower case and without a trailing dot. A rule for `api.partner.example` matches that name only. It does not match `www.api.partner.example`, and it does not match `partner.example`.

```yaml
  - toFQDNs:
    - matchName: api.partner.example
```

Use `matchName` when the partner gives you the exact names. It is the narrowest rule and the easiest to audit.

## matchPattern

`matchPattern` uses the character `*` as a wildcard. In a `toFQDNs` rule, a `*` matches any number of characters that are valid in a DNS name. A pattern such as `*.partner.example` matches `api.partner.example`, and it also matches names with more labels such as `eu.api.partner.example`. It does not match `partner.example` itself, because the pattern needs at least one label before the suffix.

Therefore a partner with the apex name `partner.example` and the subdomain `api.partner.example` needs two entries:

```yaml
  - toFQDNs:
    - matchName: partner.example
    - matchPattern: "*.partner.example"
```

A pattern that is only `*` matches every name. That is the pattern to use in the DNS rule when the pod may look up anything. Do not use it in a `toFQDNs` rule that is meant to restrict destinations, because it allows every address that any lookup returns.

<!-- astrona:playground:renew -->

You can test the difference in the playground. After you apply the policy from the previous part, resolve a name that the rule does not list. The DNS rule allows the lookup, but the connection is not allowed, because the name is not in a `toFQDNs` rule:

```sh
PARTNER_IP=$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.PARTNER_IP}')
kubectl -n starfleet exec shuttle -- nslookup kubernetes.default.svc.cluster.local
kubectl -n starfleet exec shuttle -- curl -s --max-time 5 http://probe/ip
```

The lookup answers, because the DNS rule allows every name. The second command fails to connect: the policy allows DNS and the partner, so traffic to the Service `probe` inside the cluster has no rule. This shows that a name that resolves is not a name that is allowed.

## TTL and the cache

Every DNS answer has a TTL, the number of seconds for which the answer may be used. The agent keeps each learned address in its FQDN cache until the TTL ends. When the TTL ends, the address leaves the list of allowed destinations, unless a connection that uses it is still open.

Two consequences follow. A pod that keeps a connection open after the TTL ends keeps working, because Cilium tracks connection state and allows packets of an established connection. A pod that opens a new connection to a cached address after the TTL ended fails, unless it resolves the name again. Applications that resolve a name once at startup and keep using the address for hours then fail after the first TTL. The fix is in the application: it must resolve again, or the connection pool must refresh.

The agent also has an option for a minimum TTL, `tofqdns-min-ttl`. An answer with a shorter TTL is kept at least that long, so that a pod that connects slightly after the lookup still works. Read the value for your Cilium version in the agent configuration before you rely on it.

## Names with CNAME records

A name may answer with a CNAME (canonical name) record that points to another name, and the other name answers with the address. The agent records the whole chain. A rule for the first name allows the final addresses, even when the CNAME target is a different name that the rule does not list. This helps with partners behind content delivery networks, and it also explains why one rule can allow addresses that are shared with other customers of the same network.

## What you can now do

You can write `matchName` and `matchPattern` rules and predict which names they match, including the apex name that a wildcard does not cover. You can explain the TTL limit of an allowed address, the effect on open connections and the effect of CNAME chains. The open question is what to do for destinations that have no name, such as the nodes and the Kubernetes API server.

## Common pitfalls

> [!WARNING]
> `*.partner.example` does not match `partner.example`. A rule allows addresses, not names, so it also allows other names that point to the same address. An application that caches an address longer than the TTL loses access when the entry expires. A `toFQDNs` rule with the pattern `*` allows every destination that is looked up.
