---
draft: true
exam_objectives:
- BGP Control Plane
---
# Advertise The probe Service And The Pod Prefixes: Solution

The solution has three resources: a Service that gets an address from the pool, an advertisement for Service addresses and an advertisement for pod prefixes.

## Step 1: the LoadBalancer Service

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

Apply it:

```sh
kubectl apply -f service-probe-public.yaml
```

Then check the result. The `EXTERNAL-IP` column shows an address from `198.51.100.0/28`:

```sh
kubectl -n starfleet get service probe-public
```

## Step 2: the Service advertisement

Save this as `bgp-advertisement-service.yaml`:

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
```

Apply it:

```sh
kubectl apply -f bgp-advertisement-service.yaml
```

## Step 3: the pod prefix advertisement

Save this as `bgp-advertisement-podcidr.yaml`:

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
```

Apply it:

```sh
kubectl apply -f bgp-advertisement-podcidr.yaml
```

## Step 4: check the router

Wait a few seconds, then list the BGP routes on the router:

```sh
ROUTER_CONTAINER=$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.ROUTER_CONTAINER}')
docker exec $ROUTER_CONTAINER vtysh -c 'show ip route bgp'
```

The list has a `/32` route for the Service address and a route for the pod prefix of each worker. Then submit:

```sh
astrona submit -c .
```
