DROP PROC IF EXISTS sp_compute_pool_log
GO

CREATE PROC sp_compute_pool_log AS
BEGIN

	DROP TABLE IF EXISTS #aris_log
	CREATE TABLE #aris_log (line nvarchar(max))

	BULK INSERT #aris_log  
	   FROM '/var/opt/mssql/log/compute_pool.log'  
	   WITH   
		  (  
			ROWTERMINATOR ='\n'  
		  );  

	SELECT * FROM #aris_log

END
GO

DROP PROC IF EXISTS sp_compute_pool_dq_exec
GO

CREATE PROC sp_compute_pool_dq_exec (@pool_name NVARCHAR(max), @credential_type NVARCHAR(max), @node_count INT, @cmd NVARCHAR(max)) AS
BEGIN

	DECLARE @cnt INT = 0;
	
	WHILE @cnt < @node_count
	BEGIN
	
	   DECLARE @statement NVARCHAR(max) = '[' + @pool_name + '-node-' + CONVERT(NVARCHAR(max), @cnt) + '-' + @credential_type + '].' + @cmd
	   EXEC sp_executesql @statement
	   SET @cnt = @cnt + 1;
	
	END;
END

DROP PROC IF EXISTS sp_compute_pool_dq_query
GO

CREATE PROC sp_compute_pool_dq_query (@pool_name NVARCHAR(max), @credential_type NVARCHAR(max), @node_count INT, @cmd NVARCHAR(max)) AS
BEGIN

	DECLARE @cnt INT = 0;
	
	WHILE @cnt < @node_count
	BEGIN
	
		DECLARE @linked_server_name NVARCHAR(max) = '[' + @pool_name + '-node-' + CONVERT(NVARCHAR(max), @cnt) + '-' + @credential_type + ']'
		DECLARE @statement NVARCHAR(max) = 'SELECT * FROM OPENQUERY('+ @linked_server_name+ ','''+ REPLACE(@cmd,'''','''''') +''')'   

		EXEC sp_executesql @statement
		
		SET @cnt = @cnt + 1;
	
	END;
END
GO

DROP PROC IF EXISTS sp_compute_pool_drop_manager_database
GO

CREATE PROC sp_compute_pool_drop_manager_database AS
BEGIN

	ALTER DATABASE [compute_pool_manager] SET SINGLE_USER WITH ROLLBACK IMMEDIATE
	
	DROP DATABASE [compute_pool_manager]

	-- Force the SQLCLR app domains to unload (so the ShardMapManager objects are flushed!)
	ALTER DATABASE CURRENT SET TRUSTWORTHY ON;
	ALTER DATABASE CURRENT SET TRUSTWORTHY OFF;

END
GO

-- EXAMPLES:
-- EXEC [sp_compute_pool_cycle_log]
-- EXEC [sp_compute_pool_support_create_linked_servers] 'mssql-compute-pool', 8
-- SELECT * from sys.servers

-- Use DQ to trouble shoot
-- sp_compute_pool_dq_query 'mssql-compute-pool', 'sa', 8, 'select * from sys.databases where name = ''high_value_data'''
-- sp_compute_pool_dq_exec 'mssql-compute-pool', 'sa', 8, 'master.sys.sp_executesql N''ALTER DATABASE high_value_data SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE high_value_data'''
-- sp_compute_pool_dq_exec 'mssql-compute-pool', 'sa', 8, 'master.sys.sp_cycle_errorlog'
-- sp_compute_pool_dq_exec 'mssql-compute-pool', 'sa', 8, 'master.sys.sp_readerrorlog'
-- sp_compute_pool_dq_query 'mssql-compute-pool', 'sa', 8, 'select * from high_value_data.sys.tables'
-- EXEC [sp_compute_pool_support_drop_linked_servers] 'mssql-compute-pool', 8