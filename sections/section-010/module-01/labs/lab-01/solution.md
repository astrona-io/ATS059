---
draft: true
exam_objectives:
- Egress Connectivity Requirements
---
# Limit Egress To One External Partner: Solution

The solution is one `CiliumNetworkPolicy` with two egress rules: DNS and the partner. Once any egress rule selects `shuttle`, the pod is in default deny for everything else.

## Step 1: read the partner address

```sh
kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.PARTNER_IP}'
```

Note the address. The YAML below uses `<PARTNER>` as a placeholder for it.

## Step 2: write the policy

Save this as `cnp-shuttle-egress.yaml`, with `<PARTNER>` replaced by the address:

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

## Step 3: check each requirement

The partner must answer, the decoy must not, and DNS must work:

```sh
kubectl -n starfleet exec shuttle -- curl -s --max-time 8 http://<PARTNER>:8080/ip
kubectl -n starfleet exec shuttle -- curl -s --max-time 6 http://<DECOY>:8080/ip
kubectl -n starfleet exec shuttle -- nslookup kubernetes.default.svc.cluster.local
```

The first command prints a JSON document. The second command ends without an answer. The third command resolves the name. The policy selects only `app: shuttle` in `starfleet`, so `drifter` keeps its access.

Then submit:

```sh
astrona submit -c .
```
