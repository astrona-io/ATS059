---
draft: true
exam_objectives:
- BGP Control Plane
- Understand Options to Connect Cilium-managed Clusters with External Networks
---
# Make The Router Receive The probe-public Address: Solution

Follow the order of checks: the session, the advertisement selection, the Service labels, and the attributes.

## Step 1: find where the route stops

The sessions are up, so look at the advertisement chain. Compare the label that the peer configuration selects with the label of the advertisement:

```sh
kubectl get ciliumbgppeerconfigs cilium-peer -o jsonpath='{.spec.families[0].advertisements.matchLabels}'
kubectl get ciliumbgpadvertisements --show-labels
```

The peer configuration selects `advertise: bgp`. The advertisement carries `advertise: bgpp`. It is a typo, so the peer configuration uses no advertisement.

## Step 2: check the Service label

The Service entry of the advertisement selects Services with `bgp In (advertise)`. Read the labels of the Service:

```sh
kubectl -n starfleet get service probe-public --show-labels
```

The Service has no label `bgp`. Add it:

```sh
kubectl -n starfleet label service probe-public bgp=advertise
```

## Step 3: fix the advertisement and add the community

Save this as `bgp-advertisement.yaml`:

```yaml
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
    attributes:
      communities:
        standard:
        - "64513:100"
```

Apply it:

```sh
kubectl apply -f bgp-advertisement.yaml
```

## Step 4: check on the router

Wait a few seconds, then read the path on the router:

```sh
ROUTER_CONTAINER=$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.ROUTER_CONTAINER}')
LB_IP=$(kubectl -n starfleet get service probe-public -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
docker exec $ROUTER_CONTAINER vtysh -c "show bgp ipv4 unicast $LB_IP/32"
```

The output lists the paths with the community `64513:100`. Then submit:

```sh
astrona submit -c .
```
