---
draft: true
exam_objectives:
- Egress Connectivity Requirements
---
# Give shuttle A Fixed Source Address: Solution

The solution is one `CiliumEgressGatewayPolicy`. It has a pod selector, one destination range and one gateway with an egress address.

## Step 1: read the three values

```sh
PARTNER_IP=$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.PARTNER_IP}')
GATEWAY_IP=$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.GATEWAY_IP}')
GATEWAY_NODE=$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.GATEWAY_NODE}')
echo $PARTNER_IP $GATEWAY_IP $GATEWAY_NODE
```

The last command prints the two addresses and the node name. The YAML below uses them as placeholders.

## Step 2: write the policy

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

## Step 3: check the source address

Send a new request from each pod:

```sh
kubectl -n starfleet exec shuttle -- curl -s http://$PARTNER_IP:8080/ip
kubectl -n outpost exec drifter -- curl -s http://$PARTNER_IP:8080/ip
```

The `origin` for `shuttle` is the gateway address. The `origin` for `drifter` is the address of its own node, because the selector matches only `app: shuttle` in `starfleet`. Then submit:

```sh
astrona submit -c .
```
