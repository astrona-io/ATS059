---
draft: true
exam_objectives:
- Egress Connectivity Requirements
---
# Rolling Out Egress Policy Safely

A default deny egress policy is easy to write and easy to get wrong. One missing rule stops a production workload from reaching a database, and the first sign is an application error, not a clear message. This part covers the tools Cilium gives you to introduce egress policy without an outage: the enforcement modes, the audit mode, explicit deny rules and cluster-wide policies.

## Policy enforcement modes

Cilium decides per endpoint (a pod, in a Kubernetes cluster) whether policy is enforced. The setting `policyEnforcementMode` of the agent has three values.

- `default`: an endpoint accepts and sends all traffic until a policy selects it for that direction. After a policy with an `egress` section selects it, the endpoint may send only what the rules allow. Ingress is evaluated separately.
- `always`: every endpoint is in default deny for both directions, even without a policy. You must allow all traffic with rules, including DNS and traffic to the Kubernetes API server.
- `never`: Cilium does not enforce policy. Rules exist but have no effect.

The mode is a Helm value of the Cilium chart, `policyEnforcementMode`, and it applies to the whole cluster. The playground uses `default`, which is why the pod `drifter` keeps full access while `shuttle` has a policy.

## Audit mode

Audit mode lets Cilium evaluate the policy and log the result, but it does not drop the traffic. It is the safe way to learn what a new default deny policy would block. The Helm value `policyAuditMode=true` turns it on for the whole agent. A single endpoint can also be switched with the agent command `cilium-dbg endpoint config <ID> PolicyAuditMode=Enabled`, where the ID is the endpoint number that `cilium-dbg endpoint list` prints.

<!-- astrona:playground:renew -->

In audit mode, Hubble shows a connection that the policy would deny with the verdict `AUDIT` instead of `DROPPED`. Read the flows from the agent that runs on the node of the pod:

```sh
kubectl -n kube-system get pods -l k8s-app=cilium -o wide
kubectl -n kube-system exec <AGENT_ON_NODE_OF_SHUTTLE> -- hubble observe --from-pod starfleet/shuttle --verdict AUDIT --last 20
```

Every line is one connection attempt that would be dropped without audit mode. Collect the destinations from these lines, write an allow rule for each one that is legitimate, and turn audit mode off when the list of `AUDIT` verdicts is empty. In audit mode the application keeps working, so a mistake in the rule list costs nothing.

## Explicit deny rules

Allow rules cannot express "everything except this". For that, a policy has `egressDeny`. A deny rule matches the same kinds of destinations as an allow rule: `toCIDR`, `toCIDRSet`, `toEndpoints` and `toEntities`. A deny rule always wins over an allow rule, even when the allow rule is more specific.

```yaml
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: shuttle-deny-metadata
  namespace: starfleet
spec:
  endpointSelector:
    matchLabels:
      app: shuttle
  egressDeny:
  - toCIDR:
    - 169.254.169.254/32
```

The policy blocks the address `169.254.169.254` for `shuttle`. This address is the metadata service of many cloud providers. A pod that can reach it can often read the credentials of its node. A deny rule is the right tool for a destination that no pod of a group may reach, whatever other rules say.

A deny rule does not put the pod into default deny. If a pod has only an `egressDeny` section, every other destination stays allowed. Add an allow rule or an empty `- {}` egress rule when you also want default deny.

## Cluster-wide policy

A `CiliumNetworkPolicy` lives in one namespace and selects only pods of that namespace. A `CiliumClusterwideNetworkPolicy` has no namespace. It selects pods in all namespaces and uses the same `egress` and `egressDeny` sections. Use it for rules that every workload needs, such as the rule that allows DNS, or the deny rule for the metadata address.

```yaml
apiVersion: cilium.io/v2
kind: CiliumClusterwideNetworkPolicy
metadata:
  name: deny-metadata-everywhere
spec:
  endpointSelector: {}
  egressDeny:
  - toCIDR:
    - 169.254.169.254/32
```

An empty `endpointSelector` selects every pod. The policy applies the same way to all namespaces, so a team cannot remove it from its own namespace.

## A rollout order

A rollout that works for most teams has five steps. Turn on audit mode for the endpoint. Apply the default deny policy with the rules that you already know. Read the `AUDIT` flows for a full business cycle, for example a week. Add the missing rules. Turn audit mode off and keep reading `DROPPED` flows for a few days.

```sh
kubectl get cnp -A
kubectl get ccnp
```

The first command lists the namespaced policies of all namespaces. The second lists the cluster-wide policies. When a pod behaves differently from what you expect, read both lists, because a cluster-wide policy applies without being visible in the namespace of the pod.

## What you can now do

You can name the three enforcement modes, use audit mode to find the rules a default deny policy needs, write an explicit deny rule, and place a rule that applies to all namespaces in a cluster-wide policy. The question still open is how a partner sees the pod when the rules allow it: the source address.

## Common pitfalls

> [!WARNING]
> A policy in `always` mode without an allow rule for DNS and the API server breaks every pod that has no rule. An `egressDeny` rule always wins over an allow rule, so a deny range that is too wide cannot be corrected by a more specific allow rule. Audit mode applies to the agent or to the endpoint that you set it on, not to one policy. Turn it off after the rollout, because a policy in audit mode protects nothing.
