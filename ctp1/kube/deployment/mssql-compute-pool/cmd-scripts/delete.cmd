echo off

kubectl delete svc service-master --cascade=true
kubectl delete svc service-master-nodeport --cascade=true
kubectl delete svc service-master-lb --cascade=true

kubectl delete endpoints service-master
kubectl delete endpoints service-master-nodeport
kubectl delete endpoints service-master-lb

kubectl delete svc service-node --cascade=true
kubectl delete endpoints service-node

kubectl delete statefulset mssql-compute-pool-master --force --now --cascade=true --timeout=5s
kubectl delete statefulset mssql-compute-pool-node --force --now --cascade=true

kubectl delete statefulset mssql-compute-pool-master --force --now --cascade=false --timeout=5s
kubectl delete statefulset mssql-compute-pool-node --force --now --cascade=false

kubectl delete pod mssql-compute-pool-master-0
kubectl delete pod mssql-compute-pool-node-0
kubectl delete pod mssql-compute-pool-node-1

kubectl delete secret mssql-compute-pool-secret
kubectl delete secret mssql-private-registry

kubectl get statefulset
kubectl get pod
