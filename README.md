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

## Step 3: Dockerize the java application

1. Copy Dockerfile to the root of the java application
2. Build it ```docker build -t _myname_:latest .```
3. Run it locally ```docker run --name _myname_ -p 8080:8080 _myname_:latest```
4. Open browser and check the health endpoint responds at ```http://localhost:8080/actuator/health```
5. Tag the docker image ```docker tag _myname_:latest eu.gcr.io/k8s-ws-x/_myname_:1```
6. Push the docker image to docker repository ```docker push eu.gcr.io/k8s-ws-x/_myname_:1```
