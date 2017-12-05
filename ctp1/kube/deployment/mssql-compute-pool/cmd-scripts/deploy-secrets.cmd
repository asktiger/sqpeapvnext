echo off

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

REM Create docker registry secrets
REM
kubectl create secret docker-registry mssql-private-registry --docker-server=private-repo.microsoft.com --docker-username=%DOCKER_USERNAME% --docker-password=%DOCKER_PASSWORD% --docker-email=%DOCKER_EMAIL%

REM Create SQL Server secrets
REM
FOR /F "tokens=* USEBACKQ" %%F IN (`powershell "[convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes(\"%MSSQL_SA_PASSWORD%\"))"`) DO (SET BASE64_ENCODED_MSSQL_SA_PASSWORD=%%F)
FOR /F "tokens=* USEBACKQ" %%F IN (`powershell "[convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes(\"%MSSQL_IMPORT_PASSWORD%\"))"`) DO (SET BASE64_ENCODED_MSSQL_IMPORT_PASSWORD=%%F)
FOR /F "tokens=* USEBACKQ" %%F IN (`powershell "[convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes(\"%MSSQL_EXTERNAL_PASSWORD%\"))"`) DO (SET BASE64_ENCODED_MSSQL_EXTERNAL_PASSWORD=%%F)

(
  echo apiVersion: v1 
  echo kind: Secret
  echo metadata:
  echo   name: mssql-compute-pool-secret
  echo type: Opaque
  echo data:
  echo   mssql-compute-pool-sa: %BASE64_ENCODED_MSSQL_SA_PASSWORD%
  echo   mssql-compute-pool-external: %BASE64_ENCODED_MSSQL_EXTERNAL_PASSWORD%
  echo   mssql-compute-pool-import: %BASE64_ENCODED_MSSQL_IMPORT_PASSWORD%
) > secrets.yaml

kubectl create -f secrets.yaml
DEL secrets.yaml
:End
