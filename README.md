# k8s-ws

## Step 0: Preparations

### Install required software
Please install these:
* docker (https://docs.docker.com/install/)
* gcloud SDK (https://cloud.google.com/sdk/install)
* kubectl (https://kubernetes.io/docs/tasks/tools/install-kubectl/) - if you already have one, then check that it is at least version 1.16
* Windows users, you have a couple of options:
  * easiest to follow Linux / Mac instructions:
    * install WSL https://docs.microsoft.com/en-us/windows/wsl/install-win10
    * install some linux distro via WLS, for example ubuntu (and use its command-line)
    * if `docker ps` fails, open "Docker Desktop" GUI in Windows -> Settings -> Resources -> WSL INTEGRATION -> "Enable integration with my default WSL distro"
  * alternative: use powershell (you can use git bash for most of the things, but kubectl interactive needs powershell in windows)

Now you are ready, tools-wise, but there is one more step to do before you can start hacking the kubernetes:
login to google cloud to get access to the WS cluster and docker repository, so 
### Connect to workshop k8s cluster and create your personal k8s namespace
Open the terminal, define some variables:
```shell
k8sNamespace=your-name
k8sCluster=k8s-ws-???
gCloudProject=k8s-ws-???
```
and run these one by one:
```shell
# after following command browser will be opened, where you should log into google cloud with Concise email to authenticate `gcloud` CLI
gcloud auth login

# updates a kubeconfig file (~/.kube/config) with appropriate credentials and endpoint information to point kubectl at a specific cluster in Google Kubernetes Engine.
gcloud container clusters get-credentials ${k8sCluster} --zone europe-west1-b --project ${gCloudProject}

# register gcloud as a Docker credential helper (~/.docker/config.json)
gcloud auth configure-docker

# check that `kubectl` is properly installed (at least version 1.16)
kubectl version

# get k8s nodes in the cluser to check that `kubectl` can communicate with the cluster
kubectl get nodes

# create your private namespace inside k8s-ws-8 cluster (isolates your stuff from other participants)
kubectl create namespace ${k8sNamespace}

# Configure your namespace as default
# NB! Windows cmd users, use bash on windows or run
# `kubectl config current-context`
# then
# `kubectl config set-context ${outputFromPreviousCommand} --namespace=${k8sNamespace}`
kubectl config set-context $(kubectl config current-context) --namespace=${k8sNamespace}
```


## Step 1: Create java application
1. Go to this webpage: https://start.spring.io
2. Choose these options
    1. Project: Gradle Project
    2. Language: Java
    3. Spring Boot: 2.4.2
    4. Project metadata:
        1. defaults
        2. Java: 11
3. Dependecies -> Add dependencies:
     1. Spring Web
     2. Spring Boot Actuator
4. Generate (download)
5. Unzip to a folder in your computer


## Step 2: Dockerize the java application

1. Copy Dockerfile to the root of the java application
2. Choose a unique docker tag (name) for your app, for example: `demoAppName=demo-app_${k8sNamespace}`
3. Build it ```docker build --tag ${demoAppName}:latest .```
4. Run it locally in foreground: ```docker run --name ${demoAppName} --rm -p 8080:8080 ${demoAppName}:latest```
5. Open browser and check the health endpoint responds at ```http://localhost:8080/actuator/health```
6. Tag the docker image ```docker tag ${demoAppName}:latest eu.gcr.io/${gCloudProject}/${demoAppName}:1```
7. Push the docker image to docker repository ```docker push eu.gcr.io/${gCloudProject}/${demoAppName}:1```


## Step 3: Create deployment

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
kubectl describe pod ${podname}

# Investigate pod logs
kubectl logs ${podname}
```

If you have managed to get pod into "Running" state, experiment with deleting:
```shell
# try deleting pod...
kubectl delete pod ${podname}
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
kubectl exec -it ${podname} -- /bin/sh
```
... and execute following commands from there:
```shell
# How to access your running java app inside the same container
curl localhost:8080/actuator/health

# How service is accessing your pod, note the port of 8080
# (theoretical, usually you don't need the pod ip at all)
curl ${somePodip}:8080/actuator/health

# How to access your java app via service ip (not via DNS)
curl ${svc-cluster-ip}/actuator/health

# How to access a service in your own namespace (DNS)
curl demo/actuator/health

# How to access a service in any namespace (DNS)
curl demo.${k8sNamespace}.svc.cluster.local/actuator/health
```
