# SQL Server vNext CTP1.3 Deployment Scripts & Samples

[Documentation](documentation)

This folder contains documentation for SQL Server vNext CTP1.3 including getting started and supplemental documentation that contains instructions for how to deploy Kubernetes cluster on multiple VMs.

[High Value Database Configuration](high-value-db-configuration)

This folder contains the scripts for configuration of the database for storing/querying the high value data  on the head node. The configuration steps are documented in the "Bring your own high value database" section of the getting started document.

[Kube](kube/deployment/mssql-compute-pool)

This folder contains the deployment scripts that will deploy SQL Server vNext CTP1.3 on a Kubernetes cluster.

[Sample Spark Jobs](sample-spark-job)

This folder contains the sample Spark jobs that can be modified for your data injestion scenario.

[Sample T-SQL Scripts](sample-tsql)

This folder contains the sample T-SQL end-to-end demo script that you can execute on the head node in the high_value_data database. This script will show usage of the compute pool T-SQL API and query scenarios.
