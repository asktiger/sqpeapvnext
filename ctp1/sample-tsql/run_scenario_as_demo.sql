-- Welcome to Project Aris, a demo scenario: 
--		1. Spark Streaming into SQL Server Big Data cluster
--		2. Fan-out query joining SQL Server high value data with SQL Server high volume in Big Data cluster

-- Kubernetes configuration (K8s)
--
DECLARE @compute_pool_name NVARCHAR(max) = 'mssql-compute-pool'
DECLARE @cluster_node_count INT = 8

PRINT 'STEP 1: Initialize compute cluster'
--        1. setup up 'map' management
--        2. create credential for head node --> compute node authentication
--        3. create compute node databases and configure 'map'
--        4. create EXTERNAL DATASOURCE on head node for compute cluster
--
EXEC sp_compute_pool_create @compute_pool_name, @cluster_node_count
GO

-- View compute pool settings
--		
SELECT * FROM dm_compute_pools ()
GO
	
-- View state of nodes in compute pool
--
DECLARE @compute_pool_name NVARCHAR(max) = 'mssql-compute-pool'
SELECT * FROM dm_compute_pool_node_status (@compute_pool_name)
GO

PRINT 'STEP 2: Derive table schema from sample file (using Spark) and create SQL Server table schema'
--		1. Submit Resource Negotiator request to submit Spark job to derive T/SQL schema
--		2. Create TABLE on each compute node
--		3. Create EXTERNAL TABLE on the head node
--
DECLARE @compute_pool_name NVARCHAR(max) = 'mssql-compute-pool'
DECLARE @table_name NVARCHAR(max) = 'airlinedata'
DECLARE @sample_file_name NVARCHAR(max) = 'hdfs:///airlinedata/airlinedata_sample.csv'
EXEC sp_compute_pool_create_table @compute_pool_name, @table_name, @sample_file_name
GO

-- View the compute_pool (Spark) job history/status
--
DECLARE @compute_pool_name NVARCHAR(max) = 'mssql-compute-pool'
SELECT * FROM dm_compute_pool_jobs(@compute_pool_name)
GO

-- View the compute_pool table DMV
--
DECLARE @compute_pool_name NVARCHAR(max) = 'mssql-compute-pool'
DECLARE @table_name NVARCHAR(max) = 'airlinedata'
SELECT * FROM dm_compute_pool_table_status (@compute_pool_name, @table_name)
GO

PRINT 'STEP 3: Start/Stop Spark stream (Submit Spark job to Resource Negotiator)'
--	Submit Spark job to ingest data from specified folder (files) into compute nodes
--
DECLARE @compute_pool_name NVARCHAR(max) = 'mssql-compute-pool'
DECLARE @table_name NVARCHAR(max) = 'airlinedata'
DECLARE @source_folder NVARCHAR(max) = 'hdfs:///airlinedata'
EXEC sp_compute_pool_start_import @compute_pool_name, @table_name, @source_folder;
GO

-- View data via fan-out queries
--
SELECT count(*) FROM airlinedata
SELECT TOP 10 * FROM airlinedata
SELECT id as EngineId, count(*) FROM airlinedata GROUP BY id
GO

-- Stop Streaming
--
DECLARE @compute_pool_name NVARCHAR(max) = 'mssql-compute-pool'
DECLARE @table_name NVARCHAR(max) = 'airlinedata'
EXEC sp_compute_pool_stop_import @compute_pool_name, @table_name
GO

-- Restart streaming
--
DECLARE @compute_pool_name NVARCHAR(max) = 'mssql-compute-pool'
DECLARE @table_name NVARCHAR(max) = 'airlinedata'
DECLARE @source_folder NVARCHAR(max) = 'hdfs:///airlinedata'
EXEC sp_compute_pool_start_import @compute_pool_name, @table_name, @source_folder;
GO

-- Stop Streaming
--
DECLARE @compute_pool_name NVARCHAR(max) = 'mssql-compute-pool'
DECLARE @table_name NVARCHAR(max) = 'airlinedata'
EXEC sp_compute_pool_stop_import @compute_pool_name, @table_name
GO

-- View data via fan-out queries
--
SELECT count(*) FROM airlinedata
GO

-- View log from compute_pool manager
--
EXEC sp_compute_pool_log
GO

-- Drop the compute_pool
--
IF OBJECT_ID('AirlineEngineSensorDataNorm') IS NOT NULL
  DROP EXTERNAL TABLE AirlineEngineSensorDataNorm;

DECLARE @compute_pool_name NVARCHAR(max) = 'mssql-compute-pool'
DECLARE @table_name NVARCHAR(max) = 'airlinedata'
EXEC sp_compute_pool_drop_table	@compute_pool_name, @table_name
GO

DECLARE @compute_pool_name NVARCHAR(max) = 'mssql-compute-pool'
EXEC sp_compute_pool_drop @compute_pool_name
GO

-- Drop the manager database before re-creating a pool with the same name (to flush ADO.NET connection pooling)
EXEC sp_compute_pool_drop_manager_database
GO

-- View the job history/status
--
DECLARE @compute_pool_name NVARCHAR(max) = 'mssql-compute-pool'
SELECT * FROM dm_compute_pool_jobs(@compute_pool_name)
GO

-- Clean up old jobs/context
DECLARE @compute_pool_name NVARCHAR(max) = 'mssql-compute-pool'
SELECT * FROM dm_compute_pool_jobs(@compute_pool_name) WHERE status = 'RUNNING'
DECLARE @jobId NVARCHAR(max) = (SELECT TOP 1 jobId FROM dm_compute_pool_jobs(@compute_pool_name) WHERE status = 'RUNNING')
EXEC sp_compute_pool_job_delete @compute_pool_name, @jobId
GO

DECLARE @compute_pool_name NVARCHAR(max) = 'mssql-compute-pool'
SELECT * FROM dm_compute_pool_jobs(@compute_pool_name)
SELECT * FROM dm_compute_pool_jobs(@compute_pool_name) WHERE status = 'KILLED'
DECLARE @context NVARCHAR(max) = (SELECT TOP 1 context FROM dm_compute_pool_jobs(@compute_pool_name) WHERE status = 'KILLED')
EXEC sp_compute_pool_context_delete @compute_pool_name, @context
GO