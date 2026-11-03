---
draft: true
exam_objectives:
- BGP Control Plane
---
# Bringing Up A Peering Session

The two earlier parts gave you the protocol and the resources. This part puts them together. You label two nodes, write a peer configuration and a cluster configuration, and check from both sides that the session reaches the state `Established`. Then you break the configuration on purpose to see how each mistake looks.

## The starting facts

The playground has an external router in a Docker container on the same Docker network as the cluster nodes. The router runs FRR, an open-source routing suite, and it accepts sessions from the address range of that network when the peer uses the ASN of the cluster nodes. The ConfigMap `lab-env` in `starfleet` holds the facts you need: the address of the router, the container name of the router, the ASN of the router and the ASN of the nodes.

Read them into shell variables:

<!-- astrona:playground:renew -->

```sh
ROUTER_IP=$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.ROUTER_IP}')
ROUTER_CONTAINER=$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.ROUTER_CONTAINER}')
ROUTER_ASN=$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.BGP_ROUTER_ASN}')
LOCAL_ASN=$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.BGP_LOCAL_ASN}')
echo $ROUTER_IP $ROUTER_CONTAINER $ROUTER_ASN $LOCAL_ASN
```

The last command prints the router address, the router container name and the two ASNs. No BGP resource exists yet, so the router shows no peers. Check that from the router side:

```sh
docker exec $ROUTER_CONTAINER vtysh -c 'show bgp summary'
```

The output has no neighbor lines, because no node opened a session.

## Select the nodes

The cluster configuration selects nodes by label, so label the two worker nodes first. The label key and value are your choice, and the selector must use the same pair:

```sh
kubectl label node astro-ats-059-playground-020-01-worker astro-ats-059-playground-020-01-worker2 bgp=enabled
```

Run `kubectl get nodes` first if your node names differ, and use the names that it prints. The control plane node stays without the label and does not run a speaker.

## The peer configuration

Save this as `bgp-peer-config.yaml`. It sets short timers so that the session reacts fast in a small test cluster:

```yaml
apiVersion: cilium.io/v2
kind: CiliumBGPPeerConfig
metadata:
  name: cilium-peer
spec:
  timers:
    holdTimeSeconds: 9
    keepAliveTimeSeconds: 3
  families:
  - afi: ipv4
    safi: unicast
    advertisements:
      matchLabels:
        advertise: bgp
```

Apply it:

```sh
kubectl apply -f bgp-peer-config.yaml
```

The family has an `advertisements` selector, but no advertisement with the label `advertise: bgp` exists yet. This is valid. The session will come up and no prefix will be sent.

## The cluster configuration

Save this as `bgp-cluster-config.yaml`. Replace `<ROUTER>` with the value of `$ROUTER_IP`, `<ROUTER_ASN>` with `$ROUTER_ASN` and `<LOCAL_ASN>` with `$LOCAL_ASN`:

```yaml
apiVersion: cilium.io/v2
kind: CiliumBGPClusterConfig
metadata:
  name: cilium-bgp
spec:
  nodeSelector:
    matchLabels:
      bgp: enabled
  bgpInstances:
  - name: instance-nodes
    localASN: <LOCAL_ASN>
    peers:
    - name: peer-router
      peerASN: <ROUTER_ASN>
      peerAddress: <ROUTER>
      peerConfigRef:
        name: cilium-peer
```

Apply it:

```sh
kubectl apply -f bgp-cluster-config.yaml
```

## Check the session from both sides

The operator needs a moment to create the node configurations and the agents need a moment to open the sessions. Check from the cluster side first:

```sh
kubectl get ciliumbgpnodeconfigs
kubectl describe ciliumbgpnodeconfigs astro-ats-059-playground-020-01-worker
```

The list shows one node configuration for each labeled node. In the output of `describe`, look under `Status` for the peer entry. Its `Peering State` is `established` when the session works. If the Cilium command-line client is installed on your machine, `cilium bgp peers` prints all sessions of all nodes in one table with the columns node, local AS, peer AS, peer address, session state and uptime.

Then check from the router side:

```sh
docker exec $ROUTER_CONTAINER vtysh -c 'show bgp summary'
```

The router now lists two neighbors, one for each worker node, with the state `Established` or a number of received prefixes. Both sides agree. Because no advertisement exists, the number of received prefixes is zero.

## What each mistake looks like

Change one value at a time in the cluster configuration, apply it, and watch the effect.

- A wrong `peerASN`: the router sees the OPEN message, the ASN does not match, and the session never reaches `Established`.
- A wrong `peerAddress`: nothing listens at that address, so the TCP connection fails and the state stays in `Active` or `Connect`.
- A node without the label: the node has no `CiliumBGPNodeConfig` and runs no speaker. The router shows only one neighbor.
- A missing `peerConfigRef` target: the status of the cluster configuration has the condition `cilium.io/MissingPeerConfigs`, and no session starts.

Always return the configuration to the working state after each experiment.

## What you can now do

You can select nodes with a label, write a peer configuration and a cluster configuration, and verify the session with the node configuration status, the Cilium client and the router. You can also tell from the state which part of the configuration is wrong. A session without advertisements still carries no prefixes, so the next question is what to announce and how.

## Common pitfalls

> [!WARNING]
> `Established` on one side only is not enough: confirm both sides. A session without a matching advertisement is healthy and empty. The control plane node has no label and no speaker, so it does not appear in the router output. Do not label a node that another `CiliumBGPClusterConfig` already selects. Use the node names that `kubectl get nodes` prints.
