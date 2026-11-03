---
draft: true
exam_objectives:
- BGP Control Plane
---
# Capstone: Publish The probe Service To The External Router: Solution

The solution builds the chain in order: session, advertisements, Service. Check each stage before the next one.

## Step 1: read the values and label the workers

```sh
ROUTER_IP=$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.ROUTER_IP}')
ROUTER_ASN=$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.BGP_ROUTER_ASN}')
LOCAL_ASN=$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.BGP_LOCAL_ASN}')
kubectl get nodes
```

Label the two workers with the names that the last command prints. Do not label the control plane node:

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

Apply it:

```sh
kubectl apply -f bgp-peer-config.yaml
```

## Step 3: the cluster configuration

Save this as `bgp-cluster-config.yaml`. Replace `<LOCAL_ASN>`, `<ROUTER_ASN>` and `<ROUTER>` with the values from step 1:

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

Apply it, then check that the sessions are `established`:

```sh
kubectl apply -f bgp-cluster-config.yaml
kubectl describe ciliumbgpnodeconfigs <WORKER_1>
```

## Step 4: the advertisements

Save this as `bgp-advertisements.yaml`:

```yaml
apiVersion: cilium.io/v2
kind: CiliumBGPAdvertisement
metadata:
  name: pod-prefixes
  labels:
    advertise: bgp
spec:
  advertisements:
  - advertisementType: PodCIDR
---
apiVersion: cilium.io/v2
kind: CiliumBGPAdvertisement
metadata:
  name: service-addresses
  labels:
    advertise: bgp
spec:
  advertisements:
  - advertisementType: Service
    service:
      addresses:
      - LoadBalancerIP
    selector:
      matchExpressions:
      - key: bgp
        operator: In
        values:
        - advertise
```

Apply it:

```sh
kubectl apply -f bgp-advertisements.yaml
```

## Step 5: the Service

Save this as `service-probe-public.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: probe-public
  namespace: starfleet
  labels:
    bgp: advertise
spec:
  type: LoadBalancer
  selector:
    app: probe
  ports:
  - port: 80
    targetPort: 8080
```

Apply it and read the address:

```sh
kubectl apply -f service-probe-public.yaml
kubectl -n starfleet get service probe-public
```

## Step 6: check the router

```sh
ROUTER_CONTAINER=$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.ROUTER_CONTAINER}')
docker exec $ROUTER_CONTAINER vtysh -c 'show ip route bgp'
```

The output has a `/32` route for the Service address and a route for the pod prefix of each worker. Then submit:

```sh
astrona submit -c .
```
