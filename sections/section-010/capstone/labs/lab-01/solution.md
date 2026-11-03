---
draft: true
exam_objectives:
- Egress Connectivity Requirements
---
# Capstone: A Restricted Partner Connection With A Fixed Source Address: Solution

Two resources solve the task. A `CiliumNetworkPolicy` limits the destinations of `shuttle`, and a `CiliumEgressGatewayPolicy` sets the source address.

## Step 1: read the values

```sh
PARTNER_IP=$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.PARTNER_IP}')
GATEWAY_IP=$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.GATEWAY_IP}')
GATEWAY_NODE=$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.GATEWAY_NODE}')
echo $PARTNER_IP $GATEWAY_IP $GATEWAY_NODE
```

## Step 2: limit the destinations

Save this as `cnp-shuttle-egress.yaml`. Replace `<PARTNER>` with the value of `$PARTNER_IP`:

```yaml
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: shuttle-egress
  namespace: starfleet
spec:
  endpointSelector:
    matchLabels:
      app: shuttle
  egress:
  - toEndpoints:
    - matchLabels:
        "k8s:io.kubernetes.pod.namespace": kube-system
        "k8s:k8s-app": kube-dns
    toPorts:
    - ports:
      - port: "53"
        protocol: ANY
      rules:
        dns:
        - matchPattern: "*"
  - toCIDR:
    - <PARTNER>/32
    toPorts:
    - ports:
      - port: "8080"
        protocol: TCP
```

Apply it:

```sh
kubectl apply -f cnp-shuttle-egress.yaml
```

## Step 3: set the source address

Save this as `egress-gateway-shuttle.yaml`. Replace `<PARTNER>`, `<GATEWAY>` and `<GATEWAY_NODE>` with the three values:

```yaml
apiVersion: cilium.io/v2
kind: CiliumEgressGatewayPolicy
metadata:
  name: shuttle-to-partner
spec:
  selectors:
  - podSelector:
      matchLabels:
        io.kubernetes.pod.namespace: starfleet
        app: shuttle
  destinationCIDRs:
  - <PARTNER>/32
  egressGateway:
    nodeSelector:
      matchLabels:
        kubernetes.io/hostname: <GATEWAY_NODE>
    egressIP: <GATEWAY>
```

Apply it:

```sh
kubectl apply -f egress-gateway-shuttle.yaml
```

## Step 4: check each requirement

Run each command from a new connection:

```sh
kubectl -n starfleet exec shuttle -- curl -s --max-time 8 http://$PARTNER_IP:8080/ip
kubectl -n outpost exec drifter -- curl -s --max-time 8 http://$PARTNER_IP:8080/ip
kubectl -n starfleet exec shuttle -- nslookup kubernetes.default.svc.cluster.local
```

The first command returns the gateway address as `origin`. The second command returns the address of the node of `drifter`. The third command resolves the name. A connection from `shuttle` to the router on port 179 fails, because the network policy does not allow it. Then submit:

```sh
astrona submit -c .
```
