---
draft: true
exam_objectives:
- Egress Connectivity Requirements
---
# Requirements And Feature Checks

A `CiliumEgressGatewayPolicy` is accepted by the Kubernetes API even when the feature is off. The resource then exists, and nothing happens. This part lists what the cluster needs, shows how to confirm it, and shows what the agent says when a policy is active.

## What the cluster needs

The egress gateway depends on three settings of the Cilium Helm chart.

- `egressGateway.enabled=true` turns the feature on in the agent and the operator.
- `bpf.masquerade=true` makes the agent translate source addresses in eBPF. The gateway does its address translation in the same eBPF program.
- `kubeProxyReplacement=true` makes Cilium handle Services in eBPF instead of kube-proxy.

A cluster that uses iptables masquerading or kube-proxy for Services does not meet the requirements. Changing these settings changes the data path of the whole cluster, so plan it as a change of its own. Check the Cilium documentation for your version for other limits, for example the supported routing modes.

## Confirm that the feature is on

Cilium stores its settings in the ConfigMap `cilium-config` in `kube-system`. The key `enable-ipv4-egress-gateway` has the value `true` when the Helm value is set:

<!-- astrona:playground:renew -->

```sh
kubectl -n kube-system get configmap cilium-config -o jsonpath='{.data.enable-ipv4-egress-gateway}'
kubectl -n kube-system get configmap cilium-config -o jsonpath='{.data.enable-bpf-masquerade}'
```

Both commands print `true` in the playground. If the first command prints nothing, the feature is off and no policy has an effect. After you change a Helm value, the agents restart to read the new configuration.

## Read the policy and the table

The resource shows what you asked for. The agent shows what it compiled. Compare both:

```sh
kubectl get ciliumegressgatewaypolicies
kubectl -n kube-system exec ds/cilium -- cilium-dbg bpf egress list
```

The second command prints the eBPF map of the agent that `ds/cilium` selects. Each line pairs a source pod address and a destination range with the gateway address. A policy that exists as a resource but has no lines in the table means that the agent did not compile it. Typical causes are a selector that matches no pod, a `nodeSelector` that matches no node, or the feature being off.

The table is per agent. An agent on a node that runs no selected pod can show other lines than the agent on the node of the pod. Run the command against the agent on the node of the pod you test.

## Find the agent of a node

```sh
kubectl -n starfleet get pod shuttle -o wide
kubectl -n kube-system get pods -l k8s-app=cilium -o wide
```

The first command shows the node of `shuttle`. The second shows which agent pod runs on that node. Use that pod name with `kubectl exec`.

## What you can now do

You can name the three settings that the egress gateway needs, confirm in the ConfigMap that the feature is on, and compare the policy resource with the table in the agent. The open question is how to choose the gateway node and the address.

## Common pitfalls

> [!WARNING]
> A policy resource without the feature does nothing and gives no error. The table of one agent does not show what another agent compiled. Changing masquerading or kube-proxy settings changes the whole data path and needs a plan.
