---
draft: true
exam_objectives:
- Egress Connectivity Requirements
---
# Allow The Partner By Name: Solution

The solution is one policy with two egress rules: one for DNS and one for the partner name.

## Step 1: read the facts

```sh
PARTNER_NAME=$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.PARTNER_NAME}')
echo $PARTNER_NAME
```

## Step 2: write the policy

Save this as `cnp-shuttle-partner-name.yaml`. Replace `<PARTNER_NAME>` with the value that the previous command printed:

```yaml
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: shuttle-partner-name
  namespace: starfleet
spec:
  endpointSelector:
    matchLabels:
      app: shuttle
  egress:
  - toEndpoints:
    - matchLabels:
        io.kubernetes.pod.namespace: kube-system
        k8s-app: kube-dns
    toPorts:
    - ports:
      - port: "53"
        protocol: ANY
      rules:
        dns:
        - matchPattern: "*"
  - toFQDNs:
    - matchName: <PARTNER_NAME>
    toPorts:
    - ports:
      - port: "8080"
        protocol: TCP
```

The first rule lets `shuttle` look up names and sends the lookups through the DNS proxy. The second rule allows connections to the addresses that the name resolves to.

## Step 3: apply and test

```sh
kubectl apply -f cnp-shuttle-partner-name.yaml
kubectl -n starfleet exec shuttle -- curl -s --max-time 5 http://$PARTNER_NAME:8080/ip
DECOY_IP=$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.DECOY_IP}')
kubectl -n starfleet exec shuttle -- curl -s --max-time 5 http://$DECOY_IP:8080/ip
```

The first request returns the JSON document. The second request fails after five seconds, because no rule allows the decoy. Then submit:

```sh
astrona submit -c .
```
