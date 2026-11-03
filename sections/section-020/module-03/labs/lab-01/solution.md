---
draft: true
exam_objectives:
- Understand Options to Connect Cilium-managed Clusters with External Networks
---
# Announce The probe Service With Layer 2: Solution

The solution has two resources: a Service that gets an address from the pool, and a policy that announces it from worker nodes.

## Step 1: the LoadBalancer Service

Save this as `service-probe-public.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: probe-public
  namespace: starfleet
  labels:
    announce: l2
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

## Step 2: the announcement policy

Check the API version of the resource with `kubectl api-resources | grep -i l2announcement`. Save this as `l2-policy.yaml` and use that version:

```yaml
apiVersion: cilium.io/v2alpha1
kind: CiliumL2AnnouncementPolicy
metadata:
  name: starfleet-l2
spec:
  serviceSelector:
    matchLabels:
      announce: l2
  nodeSelector:
    matchExpressions:
    - key: node-role.kubernetes.io/control-plane
      operator: DoesNotExist
  interfaces:
  - ^eth[0-9]+
  loadBalancerIPs: true
```

Apply it:

```sh
kubectl apply -f l2-policy.yaml
```

## Step 3: check the lease and the client

Wait a few seconds, then read the holder of the lease and call the address from a worker container:

```sh
kubectl -n kube-system get lease cilium-l2announce-starfleet-probe-public -o jsonpath='{.spec.holderIdentity}'
WORKER=$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.WORKER_NODE}')
LB_IP=$(kubectl -n starfleet get service probe-public -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
docker exec $WORKER curl -s --max-time 5 http://$LB_IP/ip
```

The holder is a worker node, and the request returns a JSON document. Then submit:

```sh
astrona submit -c .
```
