# K8s WS Host

Stuff to do in order to prepare the workshop

## Create global ingress controller

https://cloud.google.com/community/tutorials/nginx-ingress-gke

1. Before you deploy the NGINX Ingress Helm chart to the GKE cluster, add the nginx-stable Helm repository in Cloud Shell:
```shell
helm repo add nginx-stable https://helm.nginx.com/stable
helm repo update
```

2. Deploy an NGINX controller Deployment and Service by running the following command:
```shell
helm install nginx-ingress nginx-stable/nginx-ingress
```

3. Verify that the nginx-ingress-controller Deployment and Service are deployed to the GKE cluster:
```shell
kubectl get deployment nginx-ingress-nginx-ingress
kubectl get service nginx-ingress-nginx-ingress
```

4. Replace the ip from this ingress controller in `README.md` and `ingress.yaml`
