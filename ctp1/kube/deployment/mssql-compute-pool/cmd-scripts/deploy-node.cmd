echo off

kubectl create -f ..\config\ss-node.yaml
kubectl create -f ..\config\svc-node.yaml
