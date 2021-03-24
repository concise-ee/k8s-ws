# K8s WS Host

Stuff to do in order to prepare the workshop

## Prepare cloud env 
Use same name for Google Cloud project and k8s cluster, for example
k8s-ws-${number of the workshop}

### Create G-Cloud project

### Create Kubernetes cluster
cluster type: standard
Location type: Zonal; zone: europe-west1-b
NB! Set autoscaling for node-pool, min 1 node max 10
Wait about 5 minutes until cluster is created

### Add participants
IAM -> Add -> enter participant emails -> role: Basic>Editor -> Save

## Create global ingress controller

### Background information
We used to create a GKE native ingress per namespace, but had to wait 5 minutes for the load balancers
to propagate. And had a quota limit of 5 per cluster (which we had to increase manually).
Now, the workaround was to create one ingress controller (nginx) and use different host/path combinations for each of the applications.

However, in order to not have to resolve DNS or modify hosts files, we are using magic domain ip-from-nginx.xip.io,
which always resolves to the subdomain ip address.

However, now that everyone has the same domain (with nginx ip address as subdomain), we need to make the routing based on path,
and everyone has to set a path in `ingress` to *your name*.
Then we do the rewrite in `ingress.yaml` so the application still gets the path as `/actuator/health` and not `/name/actuator/health`

### What you have to do
https://kubernetes.github.io/ingress-nginx/deploy/

1. Initialize your user as a cluster-admin with the following command:
```shell
kubectl create clusterrolebinding cluster-admin-binding \
  --clusterrole cluster-admin \
  --user $(gcloud config get-value account)
```

2. Deploy an NGINX controller Deployment and Service by running the following command:
```shell
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v0.44.0/deploy/static/provider/cloud/deploy.yaml
```

3. Verify that the nginx-ingress-controller Deployment and Service are deployed to the GKE cluster in ingress-nginx:
```shell
watch "kubectl get deployments,services --namespace ingress-nginx"
```

4. Replace the ip from this ingress controller
```shell
kubectl describe --namespace ingress-nginx service ingress-nginx-controller | grep Ingress 
```
in `README.md` and `ingress.yaml`
