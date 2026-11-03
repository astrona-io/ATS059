---
draft: true
exam_objectives:
- Egress Connectivity Requirements
---
# Entities, Services And Endpoints

Not every destination has a name or a fixed address. The Kubernetes API server, the nodes of the cluster and "anything outside the cluster" are destinations that a policy must describe in a different way. This part covers the rule types for them: `toEntities`, `toServices` and `toEndpoints`, and when to use each one next to `toCIDR` and `toFQDNs`.

## Entities

An entity is a built-in group of destinations that Cilium defines through security identities. A rule lists entity names in `toEntities`. The main entities for egress are:

| Entity | What it selects |
| --- | --- |
| `world` | Every address outside the cluster that Cilium does not know as an endpoint or a node |
| `cluster` | All endpoints, nodes and the host of the cluster |
| `host` | The node on which the pod runs |
| `remote-node` | The other nodes of the cluster |
| `kube-apiserver` | The Kubernetes API server |
| `all` | Every destination |

A pod that must reach the Kubernetes API server, for example a controller, needs an explicit rule once default deny is on:

```yaml
  egress:
  - toEntities:
    - kube-apiserver
```

The entity `kube-apiserver` follows the address of the API server, also when it changes. A `toCIDR` rule with the address of the API server would need an update after every change. An entity is the right tool for destinations that Cilium already knows.

## The world entity

`world` selects everything outside the cluster. A rule that allows `world` is the opposite of default deny for external traffic: the pod may reach the whole internet. Use it only together with a deny rule for the ranges that must stay blocked, or for pods that need broad access, such as a build job that downloads packages.

```yaml
  egress:
  - toEntities:
    - world
  egressDeny:
  - toCIDR:
    - 169.254.169.254/32
```

The deny rule wins over the allow rule, so the metadata address stays blocked. A destination inside the cluster, such as another pod, is not part of `world`. It has its own identity, and a rule for `world` does not allow it.

<!-- astrona:playground:renew -->

You can check the difference in the playground. Apply a policy that allows DNS and the entity `world` to `shuttle`, then reach the partner by address and the Service `probe` inside the cluster:

```sh
PARTNER_IP=$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.PARTNER_IP}')
kubectl -n starfleet exec shuttle -- curl -s --max-time 5 http://$PARTNER_IP:8080/ip
kubectl -n starfleet exec shuttle -- curl -s --max-time 5 http://probe/ip
```

The first request works, because the partner is outside the cluster. The second fails, because the `probe` pod is an endpoint of the cluster and `world` does not include it.

## Endpoints in the cluster

`toEndpoints` selects pods by labels. The selector matches the labels of the destination pods and, as in the DNS rule, the label `io.kubernetes.pod.namespace` limits the match to a namespace. Use it for traffic inside the cluster. A rule `toEndpoints` with `matchLabels: {app: probe}` in the policy of `shuttle` allows traffic to the `probe` pods of the same namespace only, because a selector without a namespace label defaults to the namespace of the policy.

## Services

A Service of type `ClusterIP` that has a selector is handled through its pods: you write a `toEndpoints` rule for the pods. A Service without a selector is different. It has manually created Endpoints that can point to addresses outside the cluster, such as a database in another network. For these Services, `toServices` allows the Service by name and namespace:

```yaml
  egress:
  - toServices:
    - k8sService:
        serviceName: external-database
        namespace: starfleet
```

The rule follows the Endpoints of the Service. When the team changes the address of the database in the Endpoints object, the policy follows without an edit. The rule `toServices` selects a Service that has no selector and so no pods behind it. It is not the way to select a normal Service with pods.

## Choosing the rule type

Use this order when you write a rule:

1. The destination is in the cluster and has pods: `toEndpoints`.
2. The destination is known to Cilium as a node or the API server: `toEntities`.
3. The destination is outside the cluster and has a stable name: `toFQDNs`.
4. The destination is outside the cluster and has a stable address range: `toCIDR` or `toCIDRSet`.
5. The destination is a selectorless Service that points outside: `toServices`.
6. Everything outside the cluster: `toEntities` with `world`, with deny rules for what must stay blocked.

## What you can now do

You can name the entities that matter for egress, write a rule that allows the API server, explain what `world` does and does not include, and choose between `toEndpoints`, `toEntities`, `toFQDNs`, `toCIDR` and `toServices`. The open question is how to find out why a destination is blocked when the rules look correct.

## Common pitfalls

> [!WARNING]
> `world` does not include pods or nodes of the cluster. A rule for the API server by address breaks when the address changes, where the entity `kube-apiserver` does not. `toServices` works for Services without a selector, not for Services that have pods. A wide allow rule with `world` needs deny rules for the metadata address and other ranges that must stay closed.
