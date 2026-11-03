---
draft: true
exam_objectives:
- Egress Connectivity Requirements
---
# How A FQDN Rule Works

A partner changes its IP address more often than its name. A rule that lists a name keeps working after the address changes, and a rule that lists an address does not. Cilium cannot match a name inside a packet, because the packet carries only addresses. This part explains how the agent connects the two: it watches the DNS answers and turns them into allowed addresses.

## Two rules, one mechanism

A name-based egress policy always has two rules. The first one allows the pod to send DNS requests to CoreDNS and tells Cilium to inspect them. The second one, `toFQDNs`, allows connections to the names. The second rule has no effect without the first, because the agent learns the addresses only from DNS answers that it saw.

Save this as `cnp-shuttle-partner-name.yaml`:

```yaml
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: shuttle-partner-name
  namespace: starfleet
spec:
  endpointSelector:
    matchLabels:
      app: shuttle
  egress:
  - toEndpoints:
    - matchLabels:
        io.kubernetes.pod.namespace: kube-system
        k8s-app: kube-dns
    toPorts:
    - ports:
      - port: "53"
        protocol: ANY
      rules:
        dns:
        - matchPattern: "*"
  - toFQDNs:
    - matchName: partner.lab.test
    toPorts:
    - ports:
      - port: "8080"
        protocol: TCP
```

The field `rules.dns` is what redirects the DNS traffic of the pod to the DNS proxy. Without it, the traffic goes straight to CoreDNS and the agent never sees the answers. The pattern `"*"` allows the pod to look up any name. The second rule then decides which names the pod may connect to.

## Measure first

<!-- astrona:playground:renew -->

Read the facts and test the starting state. No policy exists yet, so both the name and the address work:

```sh
PARTNER_NAME=$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.PARTNER_NAME}')
PARTNER_IP=$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.PARTNER_IP}')
kubectl -n starfleet exec shuttle -- curl -s --max-time 5 http://$PARTNER_NAME:8080/ip
```

The answer is a JSON document with the field `origin`. The name resolved through CoreDNS and the connection reached the partner.

## Apply the policy

```sh
kubectl apply -f cnp-shuttle-partner-name.yaml
kubectl -n starfleet exec shuttle -- curl -s --max-time 5 http://$PARTNER_NAME:8080/ip
kubectl -n starfleet exec shuttle -- curl -s --max-time 5 http://$PARTNER_IP:8080/ip
```

The first request, by name, works. The second request, by address, fails after five seconds and `curl` returns a non-zero status. Both go to the same partner. The difference is that the second connection has no DNS answer behind it, so the agent has no entry that allows that address.

## The sequence

The order of events explains the behavior.

1. The pod sends a DNS request for the name. The eBPF program redirects it to the DNS proxy of the agent.
2. The proxy checks the name against the `rules.dns` patterns. The pattern allows it, so the proxy forwards the request to CoreDNS.
3. CoreDNS answers with an address and a time to live (TTL).
4. The proxy checks the answer against the `toFQDNs` rules. The name matches `partner.lab.test`, so the agent stores the address and the TTL in its FQDN cache and adds the address to the list of allowed destinations of the pod.
5. The proxy returns the answer to the pod, and the pod connects to the address. The eBPF program finds the address in the allowed list and forwards the packet.

The agent updates the allowed list before it returns the answer to the pod. This order matters: the pod cannot connect before the address is allowed.

## Why the address check still happens

The policy decision is made on the address of the packet, not on the name. The name only fills the list of allowed addresses. If two names share an address, a rule for one name allows connections to the other one too, once the address is in the list. A name-based rule is therefore not a strict name filter for connections. It is a way to keep an address list up to date.

## What you can now do

You can write a policy that allows one name, explain why the DNS rule with `rules.dns` is required, and describe the five steps from DNS request to allowed connection. You can also explain why a connection to the partner address fails when the pod did not resolve the name first. The open question is which names a rule matches and for how long an address stays allowed.

## Common pitfalls

> [!WARNING]
> A `toFQDNs` rule without a `rules.dns` rule never matches. A pod that uses a hardcoded address, or a resolver other than the cluster DNS, bypasses the proxy and is blocked. A name-based rule allows every address that the name resolves to, and another name with the same address then also works.
