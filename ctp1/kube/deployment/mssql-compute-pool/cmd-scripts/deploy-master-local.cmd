echo off

kubectl create -f ..\config\ss-master.yaml
kubectl create -f ..\config\svc-master.yaml
kubectl create -f ..\config\svc-master-nodeport.yaml
