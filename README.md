# Kubernetes workshop

## Step 0: Preparations

Let's get ready for the workshop, so everyone would be prepared.

### Install required software
Please install these:
* docker (https://docs.docker.com/install/)
* gcloud SDK (https://cloud.google.com/sdk/install)
* kubectl (https://kubernetes.io/docs/tasks/tools/install-kubectl/) - if you already have one, then check that it is at least version 1.16
* Linux users:
    * Verify that you can use docker without sudo (https://docs.docker.com/engine/install/linux-postinstall/) 
* Windows users:
    * install WSL https://docs.microsoft.com/en-us/windows/wsl/install-win10
    * install some linux distro via WLS, for example ubuntu (and use its command-line)
    * if `docker ps` fails, open "Docker Desktop" GUI in Windows -> Settings -> Resources -> WSL INTEGRATION -> "Enable integration with my default WSL distro"

### Connect to workshop k8s cluster and create your personal k8s namespace
Open the terminal, define some variables:
```shell
k8sNamespace=your-name
k8sCluster=k8s-ws-???
gCloudProject=k8s-ws-???
```
and run following lines one by one:
```shell
# after following command browser will be opened, where you should log into google cloud with Concise email to authenticate `gcloud` CLI
gcloud auth login

# updates a kubeconfig file (~/.kube/config) with appropriate credentials and endpoint information to point kubectl at a specific cluster in Google Kubernetes Engine.
gcloud container clusters get-credentials ${k8sCluster} --zone europe-west1-b --project ${gCloudProject}

# register gcloud as a Docker credential helper (~/.docker/config.json)
gcloud components install docker-credential-gcr
docker-credential-gcr configure-docker

# check that `kubectl` is properly installed (at least version 1.16)
kubectl version

# get k8s nodes in the cluser to check that `kubectl` can communicate with the cluster
kubectl get nodes

# create your private namespace inside k8s-ws-8 cluster (isolates your stuff from other participants)
kubectl create namespace ${k8sNamespace}

# Configure your namespace as default
kubectl config set-context $(kubectl config current-context) --namespace=${k8sNamespace}
```


## Step 1: Create java application

Lets generate an application that has health endpoint (needed for k8s).
> No worries, you don't need to have Java, Gradle etc installed locally - that will be built in docker!

1. Go to this webpage: https://start.spring.io
2. Choose these options
    1. Project: Gradle Project
    2. Language: Java
    3. Spring Boot: 2.4.2
    4. Project metadata:
        1. defaults
        2. Java: 11
3. Dependencies -> Add dependencies:
     1. Spring Web
     2. Spring Boot Actuator
4. Generate (download)
5. Unzip to a folder in your computer


## Step 2: Dockerize the java application

Let's create a docker image, so that k8s wouldn't care what language or tech stack our application uses.

1. Copy Dockerfile to the root of the java application
2. Choose a unique docker tag (name) for your app, for example: `demoAppName=demo-app_${k8sNamespace}`
3. Build it ```docker build --tag ${demoAppName}:latest .```
4. Run it locally in the foreground: ```docker run --name ${demoAppName} --rm -p 8080:8080 ${demoAppName}:latest```
5. Open browser and check the health endpoint responds at ```http://localhost:8080/actuator/health```
6. Tag the docker image ```docker tag ${demoAppName}:latest eu.gcr.io/${gCloudProject}/${demoAppName}:1```
7. Push the docker image to docker repository ```docker push eu.gcr.io/${gCloudProject}/${demoAppName}:1```


## Step 3: Create deployment

Let's create a deployment, specifying pods (instances) count, liveness/readiness probes and update strategy.

Configure k8s context and namespace to be used for following commands
(to avoid passing `--context` and `--namespace` with each following command)
```shell
# see what namespaces you could use
kubectl get namespaces

# Set kubectl against certain namespace (default ns is the default, but we want to deploy to your own ns)
kubectl config set-context $(kubectl config current-context) --namespace=${k8sNamespace}

# see all contexts and which of them is currently selected and what namespace is currently selected:
kubectl config get-contexts
```

See the current state of k8s resources:
```shell
# You can get different types of resources at once
kubectl get pods,deployments,nodes

# before running next command you shouldn't have any pods
kubectl get pods
```

Create deployment (uploads manifest from given file to kubernetes)
```shell
# NB! you probably want to replace image reference with your own, but you could try with default as well
kubectl apply -f deployment.yaml
```

See if deployment created pod (hopefully in ContainerCreating and soon in Running status)
```shell
# now you should see one pod (in selected namespace of selected k8s cluster)
kubectl get pods

# Investigate events (specially if pod isn't in running status)
kubectl describe pod ${podname:-changeMe}

# Investigate pod logs
kubectl logs ${podname:-changeMe}
```

If you have managed to get pod into "Running" state, experiment with deleting:
```shell
# try deleting pod...
kubectl delete pod ${podname:-changeMe}

# ... and see what happened
kubectl get pods
```

Try adding more pods of the same deployment:
```shell
# open deployment manifest for in-line editing (note this doesn't change your deployment.yaml)
kubectl edit deployment demo

#change `replicas: 2`, save and quit

# check number of pods: 
kubectl get pods
```


## Step 4: Create service

Let's create a service, so all our healthy application pods would be accessible from same (non-public) endpoint of the service.

```shell
kubectl apply -f service.yaml
```

Get information about the service, pods and namespaces used later
```shell
# Check which services you have now
kubectl get svc
# Check the details of that service
kubectl describe svc demo
# Check the ip of your pod
kubectl get pods -o wide
# Check other namespaces
kubectl get namespaces
```

Log into one container...
```shell
# "log in" to the running container
kubectl exec -it ${podname:-changeMe} -- /bin/sh
```
... and execute following commands from there:
```shell
# How to access your running java app inside the same container
curl localhost:8080/actuator/health

# How service is accessing your pod, note the port of 8080
# (theoretical, usually you don't need the pod ip at all)
curl ${somePodip:-changeMe}:8080/actuator/health

# How to access your java app via service ip (not via DNS)
curl ${svc-cluster-ip:-changeMe}/actuator/health

# How to access a service in your own namespace (DNS)
curl demo/actuator/health

# How to access a service in any namespace (DNS)
curl demo.${k8sNamespace:-changeMe}.svc.cluster.local/actuator/health
```


## Step 5: Create ingress

Let's make the service accessible from the public web (via IP-address/hostname).

Replace the public path name in `ingress.yaml` from `${yourName}` to *your name*.

```shell
kubectl apply -f ingress.yaml
```

You should be able to see host address using either of following commands:
```shell
# now you should see one ingress (in selected namespace of selected k8s cluster)
kubectl get ingress
kubectl describe ingress demo
```

You should be able to access
`http://${hostName:-changeMe}/${yourName:-changeMe}/actuator/health`
from public internet (i.e. using your browser or curl). The full url should look like `http://35.189.236.126.xip.io/mikk/actuator/health`

> Note, on linux you can use `watch` to monitor changes of outputs of one or more commands:
> `watch "kubectl get ingress && kubectl describe ingress demo && curl http://${hostName}/${yourName}/actuator/health"`


## Step 5: Create autoscaler

Let's make our service scale horizontally based on actual usage.

Autoscaler works on comparing actual resource usage
(see `kubectl top pods`)
to requested resources (see deployment resources.requests).

```shell
kubectl apply -f autoscaler.yaml
```

Use following commands:
```shell
# to see autoscalers
kubectl get horizontalpodautoscalers

# to see pods CPU and memory usage
kubectl top pods
```

Watch what happens to pods and autoscaler:
```
# on linux you can use `watch` to evaluate expression periodically:
watch "kubectl top pods && kubectl get pods,horizontalpodautoscalers"
```

In another console generate load to your service with following command
(NB! replace `${hostName}` and `${yourName}` ):
```shell
bash \
  <(curl -s https://raw.githubusercontent.com/zalando-incubator/docker-locust/master/local.sh) \
  deploy \
  --target=http://${hostName:-changeMe}/${yourName:-changeMe}/actuator/health \
  --locust-file=https://raw.githubusercontent.com/zalando-incubator/docker-locust/master/example/simple.py \
  --slaves=4 --mode=automatic \
  --users=100 --hatch-rate=30 --duration=120
```
soon you should see an increase in CPU usage
and after about half minute you should see effects of autoscaler.

## Step 6: Create configmap

Let's attach configmap as file to our containers.
> When creating deployment we provided some configuration values via environment variables.
> Using secrets would be another option (out of the scope for this WS).

Create configuration source file for k8s configmap, for example `some.conf`:
```properties
test=1
props=2
```

Use that configuration file to create configmap:
```shell
kubectl create configmap demo --from-file=some.conf
```

Inspect configmaps:
```shell
kubectl get configmaps
kubectl describe configmap demo
```

Update your deployment.yaml with configMap mounted from volume:
```diff
             httpGet:
               path: /actuator/health
               port: 8080
+          volumeMounts:
+            - mountPath: /conf
+              name: conf
+      volumes:
+        - name: conf
+          configMap:
+            name: demo
+            items:
+              - key: some.conf
+                path: some.conf
```

Apply changes in deployment:
```shell
kubectl apply -f deployment.yaml
```

Check that mount and volume appears in deployment description:
```shell
kubectl describe deployment demo | grep ount -A 6
```

Log into running container...
```shell
kubectl get pods
# "log in" to the running container
kubectl exec -it ${podname:-changeMe} -- /bin/sh
```
... and check if conf was actually mounted as file by executing following commands:
```shell
# should see the same conf you created
cat /conf/some.conf
```
