# k8s-ws

## Preparations
```
gcloud auth login
gcloud container clusters get-credentials k8s-ws-x --zone europe-west1-b --project k8s-ws-x
gcloud auth configure-docker
kubectl version
kubectl get nodes
kubectl create namespace _myname_
```

## Create java application
1. Go to this webpage: https://start.spring.io
2. Choose these options
    1. Project: Gradle Project
    2. Language: Java
    3. Spring Boot: 2.4.1
    4. Project metadata:
        1. defaults
        2. Java: 11
3. Dependecies -> Add dependencies:
     1. Spring Web
     2. Spring Boot Actuator
4. Generate (download)
5. Unzip to a folder in your computer

## Dockerize the java application

1. Copy Dockerfile to the root of the java application
2. Build it ```docker build -t _myname_:latest .```
3. Run it locally ```docker run --name _myname_ -p 8080:8080 _myname_:latest```
4. Open browser and check the health endpoint responds at ```http://localhost:8080/actuator/health```
5. Tag the docker image ```docker tag _myname_:latest eu.gcr.io/k8s-ws-x/_myname_:1```
6. Push the docker image to docker repository ```docker push eu.gcr.io/k8s-ws-x/_myname_:1```
