---
draft: true
exam_objectives:
- BGP Control Plane
---
# Connection Options And Failures

A BGP setup that works on a quiet day is not finished. Nodes restart, agents upgrade and links fail. This part covers the options of the peer configuration that decide how a session behaves under those events: timers, graceful restart, multihop, authentication and per-node overrides. You will also restart an agent and watch what happens to the routes on the router.

## Timers and failure detection

The keepalive timer sets how often a node sends a keepalive message. The hold timer sets how long a peer waits for any message before it declares the session dead and removes every route that it learned. The router and the node negotiate the smaller hold time. The Cilium defaults are a hold time of 90 seconds and a keepalive time of 30 seconds, so a failed node can stay in the routing table for up to 90 seconds.

The fields `holdTimeSeconds` and `keepAliveTimeSeconds` in the `timers` section of the `CiliumBGPPeerConfig` change them. The lowest values that Cilium accepts are 3 seconds for the hold time and 1 second for the keepalive time. Cilium does not support BFD (bidirectional forwarding detection), the separate protocol that detects link failures faster, so short timers are the only way to speed up detection. The cost is that a short pause of the agent can then drop the session. A common rule is a keepalive time of one third of the hold time.

## Graceful restart

When a Cilium agent restarts, for example during an upgrade, its BGP sessions close. The router sees a closed session and removes the routes of that node. Traffic to the Service addresses of that node then fails until the agent is back and the session is up again.

Graceful restart avoids this gap. With `gracefulRestart.enabled: true`, the node tells the router at the start of the session that it supports graceful restart. When the session drops later, the router keeps the old routes for the time in `restartTimeSeconds` and waits for the node to return. The router must support graceful restart too, and FRR does by default.

<!-- astrona:playground:renew -->

Save this as `bgp-peer-config-graceful.yaml`:

```yaml
apiVersion: cilium.io/v2
kind: CiliumBGPPeerConfig
metadata:
  name: cilium-peer
spec:
  timers:
    holdTimeSeconds: 9
    keepAliveTimeSeconds: 3
  gracefulRestart:
    enabled: true
    restartTimeSeconds: 15
  families:
  - afi: ipv4
    safi: unicast
    advertisements:
      matchLabels:
        advertise: bgp
```

The resource name `cilium-peer` is the one that the playground already uses, so the apply updates it. Apply it:

```sh
kubectl apply -f bgp-peer-config-graceful.yaml
```

Then restart the agent of one worker and watch the router. The agent pod name comes from the list of agents:

```sh
kubectl -n kube-system get pods -l k8s-app=cilium -o wide
kubectl -n kube-system delete pod <AGENT_ON_WORKER>
ROUTER_CONTAINER=$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.ROUTER_CONTAINER}')
docker exec $ROUTER_CONTAINER vtysh -c 'show ip route bgp'
```

Run the last command right after the deletion. With graceful restart the routes of that worker stay in the table while the agent restarts. Without graceful restart they disappear until the session returns. A changed peer configuration can reset the sessions once, so wait until both sessions are `Established` again before you delete the agent pod.

## Multihop

An eBGP session expects the peer to be directly connected, and the packets carry a TTL (time to live) of 1. When the router sits behind another router, the TTL expires and the session never opens. The field `ebgpMultihop` in the peer configuration raises the TTL. A value of 4 allows three routers in between. Do not set it for a directly connected peer: it adds nothing and weakens the check that the peer is next to you.

## Authentication

BGP sessions can carry an MD5 password in the TCP options. The peer configuration names a Secret with `authSecretRef`. The Secret holds the password in a key called `password`, and it lives in the namespace set by the Helm value `bgpControlPlane.secretNamespace.name`, by default `kube-system`. If the Secret is missing, Cilium logs it, sets the condition `cilium.io/MissingAuthSecret` on the peer configuration, and the session uses an empty password. The router with a configured password then refuses the session. Both sides must hold the same password.

## Node overrides

The cluster configuration applies to every selected node. The `CiliumBGPNodeConfigOverride` changes one node. Its name must equal the node name, and the instance and peer names must equal those of the cluster configuration. It can set `routerID`, `localPort`, `localASN`, and `localAddress` for a named peer. A node with two interfaces needs `localAddress` when the router accepts sessions only from one of them. Remember that an override with a name that matches no node has no effect.

## Prefix aggregation

When a cluster has many Service addresses, the router receives one `/32` route for each of them. The fields `service.aggregationLengthIPv4` and `service.aggregationLengthIPv6` in a Service advertisement merge them into shorter prefixes. Use aggregation with care: announcing a prefix that is shorter than the addresses that exist can attract traffic for addresses that have no backend.

## Reading the result

Write down what you see before and after each change: the session state, the routes on the router and the time that the routes stay. The numbers prove whether a setting helped. A setting that you cannot measure is a guess.

## Checking after a change

After every change, verify in this order. First, the status of the cluster configuration and the peer configuration for conditions. Second, the status of the node configuration for the session state. Third, the router for the routes. Fourth, a connection from a client behind the router to the address. A failure at one step explains the failures of the later steps, so do not skip ahead.

## What you can now do

You can set timers and explain their cost, enable graceful restart and say what it changes for a restarting agent, name the cases that need multihop, authentication and overrides, and verify a change in order from status to router to client.

## Common pitfalls

> [!WARNING]
> Very short timers can drop a healthy session when the agent pauses. Graceful restart helps only when the router supports it. Multihop on a directly connected peer is unnecessary. A missing password Secret does not stop the agent: it starts the session with an empty password, and the router then rejects it. An override works only when its name equals the node name.
