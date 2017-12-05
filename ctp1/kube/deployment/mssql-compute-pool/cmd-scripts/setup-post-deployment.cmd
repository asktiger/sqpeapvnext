echo off

REM This script should be run after all nodes in the cluster are in running state.
REM This is because we need hdfs to be up and running. The script will 
REM 1. upload test files to hdfs 
REM 2. upload jar file to spark-job-server

kubectl exec -ti mssql-compute-pool-master-0 -c mssql-compute-pool-master -- /setup-hadoop.sh

REM Create high value database
kubectl exec -it mssql-compute-pool-master-0 -c mssql-compute-pool-data -- /bin/bash /root/create_high_value_db.sh
