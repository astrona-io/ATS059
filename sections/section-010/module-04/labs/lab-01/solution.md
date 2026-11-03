---
draft: true
exam_objectives:
- Egress Connectivity Requirements
---
# Move The Egress Gateway To The Second Worker: Solution

The move has two parts: label the new gateway node, and change the policy to select the label and use the new address.

## Step 1: read the facts and label the node

```sh
PARTNER_IP=$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.PARTNER_IP}')
GATEWAY2_IP=$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.GATEWAY2_IP}')
GATEWAY2_NODE=$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.GATEWAY2_NODE}')
kubectl label node $GATEWAY2_NODE role=egress-gateway
kubectl get nodes -l role=egress-gateway
```

The last command lists only the second worker.

## Step 2: change the policy

Save this as `egress-gateway-move.yaml`. Replace `<PARTNER>` with the value of `$PARTNER_IP` and `<GATEWAY2>` with the value of `$GATEWAY2_IP`:

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
        role: egress-gateway
    egressIP: <GATEWAY2>
```

Apply it:

```sh
kubectl apply -f egress-gateway-move.yaml
```

## Step 3: check with new connections

```sh
kubectl -n starfleet exec shuttle -- curl -s http://$PARTNER_IP:8080/ip
kubectl -n outpost exec drifter -- curl -s http://$PARTNER_IP:8080/ip
```

The first answer has `origin` equal to `$GATEWAY2_IP`. The second answer shows the address of the node of `drifter`. Then submit:

```sh
astrona submit -c .
```
