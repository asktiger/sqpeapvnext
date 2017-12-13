echo off
setlocal enabledelayedexpansion

REM ABORT IF ANY REQUIRED PASSWORD IS NOT SET
IF "%MSSQL_SA_PASSWORD%" == "" (ECHO Please set env variable MSSQL_SA_PASSWORD prior to running this script 
  goto End)
IF "%MSSQL_IMPORT_PASSWORD%" == "" (ECHO Please set env variable MSSQL_IMPORT_PASSWORD prior to running this script
  goto End)
IF "%MSSQL_EXTERNAL_PASSWORD%" == "" (ECHO Please set env variable MSSQL_EXTERNAL_PASSWORD prior to running this script
  goto End)
IF "%DOCKER_USERNAME%" == "" (ECHO Please set env variable DOCKER_USERNAME prior to running this script
  goto End)
IF "%DOCKER_PASSWORD%" == "" (ECHO Please set env variable DOCKER_PASSWORD prior to running this script
  goto End)
IF "%DOCKER_EMAIL%" == "" (ECHO Please set env variable DOCKER_EMAIL prior to running this script
  goto End)

call delete.cmd
call deploy-secrets.cmd
call deploy-master-local.cmd

echo 'waiting for master to be running'

set status=
for /f "tokens=3" %%A IN ('kubectl get pods ^| find "mssql-compute-pool-master-0"') do (
    set status=%%A
)

:loopmaster
if "%status%" NEQ "Running" (
    for /f "tokens=3" %%A IN ('kubectl get pods ^| find "mssql-compute-pool-master-0"') do (
        set status=%%A
    )
    timeout /nobreak /t 2 > NUL
    goto loopmaster
)

call deploy-node.cmd

for /F "delims=: tokens=3" %%G in ('findstr /spi "replica" ..\config\ss-node.yaml') DO set nodeCount=%%G
set nodeCount=%nodeCount: =%
set /a lastNode=%nodeCount%-1

echo 'waiting for compute node to be running'

set status=
for /f "tokens=3" %%A IN ('kubectl get pods ^| find "mssql-compute-pool-node-%lastNode%"') do (
    set status=%%A
)

:loopnode
if "%status%" NEQ "Running" (
    for /f "tokens=3" %%A IN ('kubectl get pods ^| find "mssql-compute-pool-node-%lastNode%"') do (
        set status=%%A
    )
    timeout /nobreak /t 5 > NUL
    goto loopnode
)

call setup-post-deployment.cmd

Echo ====== Deployment completed. ======
Echo.

REM Getting head node connection information
REM 
FOR /F "tokens=7" %%F IN ('kubectl get pods -o wide ^| find "master"') DO set SERVERNAME=%%F

IF /I "%SERVERNAME%" equ "minikube" (
    Echo This is a minikube deployment. Use minikube VM as the server name.
    FOR /F "tokens=1" %%G IN ('minikube ip') DO set SERVERNAME=%%G
)

echo SQL server head node: %SERVERNAME%,31433
:End
