---
draft: true
exam_objectives:
- BGP Control Plane
---
# Peer The Worker Nodes With The External Router: Solution

The solution has three steps: label the workers, create the peer configuration and create the cluster configuration. The operator then creates the node configurations, and the agents open the sessions.

## Step 1: read the facts and label the workers

```sh
ROUTER_IP=$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.ROUTER_IP}')
ROUTER_ASN=$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.BGP_ROUTER_ASN}')
LOCAL_ASN=$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.BGP_LOCAL_ASN}')
kubectl get nodes
```

Label each worker node with the names that the last command prints. Do not label the control plane node:

```sh
kubectl label node <WORKER_1> <WORKER_2> bgp=enabled
```

## Step 2: the peer configuration

Save this as `bgp-peer-config.yaml`:

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

## Step 3: the cluster configuration

Save this as `bgp-cluster-config.yaml`. Replace `<LOCAL_ASN>`, `<ROUTER_ASN>` and `<ROUTER>` with the three values from step 1:

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

## Step 4: check the sessions

Wait a few seconds, then read the status of the node configurations:

```sh
kubectl get ciliumbgpnodeconfigs
kubectl describe ciliumbgpnodeconfigs <WORKER_1>
```

Under `Status`, the peer shows the `Peering State` `established`. If it does not, compare the ASNs and the address with the values of the ConfigMap. Then submit:

```sh
astrona submit -c .
```
