DECLARE @hash BINARY(64)
SET @hash = (SELECT HASHBYTES('SHA2_512', c1) FROM OPENROWSET(BULK '/root/clr/Microsoft.SqlServer.ComputePoolManagement.SqlClr.dll', SINGLE_BLOB) AS st(c1))
EXEC sp_add_trusted_assembly @hash, N'Microsoft.SqlServer.ComputePoolManagement.SqlClr'
SET @hash = (SELECT HASHBYTES('SHA2_512', c1) FROM OPENROWSET(BULK '/root/clr/Microsoft.SqlServer.ComputePoolManagement.dll', SINGLE_BLOB) AS st(c1))
EXEC sp_add_trusted_assembly @hash, N'Microsoft.SqlServer.ComputePoolManagement'
SET @hash = (SELECT HASHBYTES('SHA2_512', c1) FROM OPENROWSET(BULK '/root/clr/Microsoft.Practices.EnterpriseLibrary.TransientFaultHandling.dll', SINGLE_BLOB) AS st(c1))
EXEC sp_add_trusted_assembly @hash, N'TransientFaultHandling'
SET @hash = (SELECT HASHBYTES('SHA2_512', c1) FROM OPENROWSET(BULK '/root/clr/System.Runtime.dll', SINGLE_BLOB) AS st(c1))
EXEC sp_add_trusted_assembly @hash, N'System.Runtime'
SET @hash = (SELECT HASHBYTES('SHA2_512', c1) FROM OPENROWSET(BULK '/root/clr/System.ComponentModel.Composition.dll', SINGLE_BLOB) AS st(c1))
EXEC sp_add_trusted_assembly @hash, N'System.ComponentModel.Composition'
SET @hash = (SELECT HASHBYTES('SHA2_512', c1) FROM OPENROWSET(BULK '/root/clr/System.Threading.Tasks.dll', SINGLE_BLOB) AS st(c1))
EXEC sp_add_trusted_assembly @hash, N'System.Thread.Tasks'
SET @hash = (SELECT HASHBYTES('SHA2_512', c1) FROM OPENROWSET(BULK '/root/clr/System.Resources.ResourceManager.dll', SINGLE_BLOB) AS st(c1))
EXEC sp_add_trusted_assembly @hash, N'System.Thread.Tasks'
SET @hash = (SELECT HASHBYTES('SHA2_512', c1) FROM OPENROWSET(BULK '/root/clr/System.Globalization.dll', SINGLE_BLOB) AS st(c1))
EXEC sp_add_trusted_assembly @hash
SET @hash = (SELECT HASHBYTES('SHA2_512', c1) FROM OPENROWSET(BULK '/root/clr/System.Diagnostics.Tools.dll', SINGLE_BLOB) AS st(c1))
EXEC sp_add_trusted_assembly @hash
SET @hash = (SELECT HASHBYTES('SHA2_512', c1) FROM OPENROWSET(BULK '/root/clr/System.Diagnostics.Debug.dll', SINGLE_BLOB) AS st(c1))
EXEC sp_add_trusted_assembly @hash
SET @hash = (SELECT HASHBYTES('SHA2_512', c1) FROM OPENROWSET(BULK '/root/clr/System.Linq.dll', SINGLE_BLOB) AS st(c1))
EXEC sp_add_trusted_assembly @hash
SET @hash = (SELECT HASHBYTES('SHA2_512', c1) FROM OPENROWSET(BULK '/root/clr/System.Collections.dll', SINGLE_BLOB) AS st(c1))
EXEC sp_add_trusted_assembly @hash
SET @hash = (SELECT HASHBYTES('SHA2_512', c1) FROM OPENROWSET(BULK '/root/clr/System.Threading.dll', SINGLE_BLOB) AS st(c1))
EXEC sp_add_trusted_assembly @hash
SET @hash = (SELECT HASHBYTES('SHA2_512', c1) FROM OPENROWSET(BULK '/root/clr/System.Runtime.Extensions.dll', SINGLE_BLOB) AS st(c1))
EXEC sp_add_trusted_assembly @hash
SET @hash = (SELECT HASHBYTES('SHA2_512', c1) FROM OPENROWSET(BULK '/root/clr/Microsoft.Azure.SqlDatabase.ElasticScale.Client.dll', SINGLE_BLOB) AS st(c1))
EXEC sp_add_trusted_assembly @hash
SET @hash = (SELECT HASHBYTES('SHA2_512', c1) FROM OPENROWSET(BULK '/root/clr/System.Runtime.Serialization.dll', SINGLE_BLOB) AS st(c1))
EXEC sp_add_trusted_assembly @hash
SET @hash = (SELECT HASHBYTES('SHA2_512', c1) FROM OPENROWSET(BULK '/root/clr/System.ServiceModel.Internals.dll', SINGLE_BLOB) AS st(c1))
EXEC sp_add_trusted_assembly @hash
SET @hash = (SELECT HASHBYTES('SHA2_512', c1) FROM OPENROWSET(BULK '/root/clr/SMDiagnostics.dll', SINGLE_BLOB) AS st(c1))
EXEC sp_add_trusted_assembly @hash
SET @hash = (SELECT HASHBYTES('SHA2_512', c1) FROM OPENROWSET(BULK '/root/clr/Microsoft.Practices.EnterpriseLibrary.TransientFaultHandling.Data.dll', SINGLE_BLOB) AS st(c1))
EXEC sp_add_trusted_assembly @hash
SET @hash = (SELECT HASHBYTES('SHA2_512', c1) FROM OPENROWSET(BULK '/root/clr/System.Data.Entity.dll', SINGLE_BLOB) AS st(c1))
EXEC sp_add_trusted_assembly @hash
SET @hash = (SELECT HASHBYTES('SHA2_512', c1) FROM OPENROWSET(BULK '/root/clr/System.ComponentModel.DataAnnotations.dll', SINGLE_BLOB) AS st(c1))
EXEC sp_add_trusted_assembly @hash
SET @hash = (SELECT HASHBYTES('SHA2_512', c1) FROM OPENROWSET(BULK '/root/clr/Newtonsoft.Json.dll', SINGLE_BLOB) AS st(c1))
EXEC sp_add_trusted_assembly @hash
GO

CREATE ASSEMBLY compute_pool_assembly 
FROM '/root/clr/Microsoft.SqlServer.ComputePoolManagement.SqlClr.dll'   
WITH PERMISSION_SET = UNSAFE;
GO

CREATE PROC [sp_compute_pool_create]
	@compute_pool_name NVARCHAR(max), 
	@node_count INT
AS EXTERNAL NAME compute_pool_assembly.[Microsoft.SqlServer.ComputePoolManagement.SqlClr.ComputePoolProcedures].ComputePoolCreate;
GO

CREATE PROC [sp_compute_pool_create_table] 
	@compute_pool_name NVARCHAR(max),
	@table_name NVARCHAR(max), 
	@sample_file_name NVARCHAR(max)
AS EXTERNAL NAME compute_pool_assembly.[Microsoft.SqlServer.ComputePoolManagement.SqlClr.ComputePoolProcedures].ComputePoolCreateTable;
GO

CREATE PROC [sp_compute_pool_start_import] 
	@compute_pool_name NVARCHAR(max),
	@table_name NVARCHAR(max), 
	@parameter NVARCHAR(max)
AS EXTERNAL NAME compute_pool_assembly.[Microsoft.SqlServer.ComputePoolManagement.SqlClr.ComputePoolProcedures].ComputePoolStartImport;
GO

CREATE PROC [sp_compute_pool_drop_table] 
	@compute_pool_name NVARCHAR(max),
	@table_name NVARCHAR(max)
AS EXTERNAL NAME compute_pool_assembly.[Microsoft.SqlServer.ComputePoolManagement.SqlClr.ComputePoolProcedures].ComputePoolDropTable;
GO

CREATE PROC [sp_compute_pool_drop] 
	@compute_pool_name NVARCHAR(max)
AS EXTERNAL NAME compute_pool_assembly.[Microsoft.SqlServer.ComputePoolManagement.SqlClr.ComputePoolProcedures].ComputePoolDrop;
GO

CREATE PROC [sp_compute_pool_job_delete] 
	@compute_pool_name NVARCHAR(max),
	@job_id NVARCHAR(max)
AS EXTERNAL NAME compute_pool_assembly.[Microsoft.SqlServer.ComputePoolManagement.SqlClr.ComputePoolProcedures].ComputePoolJobDelete;
GO

CREATE PROC [sp_compute_pool_context_delete] 
	@compute_pool_name NVARCHAR(max),
	@context_name NVARCHAR(max)
AS EXTERNAL NAME compute_pool_assembly.[Microsoft.SqlServer.ComputePoolManagement.SqlClr.ComputePoolProcedures].ComputePoolJobContextDelete;
GO

CREATE FUNCTION [dm_compute_pool_jobs](@compute_pool_name NVARCHAR(max)) 
RETURNS TABLE 
(duration NVARCHAR(max), class_path NVARCHAR(max),start_time NVARCHAR(max),context NVARCHAR(max), [status] NVARCHAR(max), job_id NVARCHAR(max), result_message NVARCHAR(max), result_error_class NVARCHAR(max), result_stack NVARCHAR(max))  
AS   
EXTERNAL NAME compute_pool_assembly.[Microsoft.SqlServer.ComputePoolManagement.SqlClr.Supportabilty].GetJobs;  
GO

CREATE PROC [sp_compute_pool_stop_import] 	
	@compute_pool_name NVARCHAR(max),
	@table_name NVARCHAR(max) 
AS
BEGIN
	
	DECLARE @context NVARCHAR(max)
	DECLARE @context_search_pattern NVARCHAR(max) = @compute_pool_name + '_' + @table_name + '-%'

	WHILE (1 = 1) 
	BEGIN

	  -- Get next @Context (i.e. airlinedata-{GUID})
	  SELECT TOP 1 @context = Context
	  FROM dm_compute_pool_jobs(@compute_pool_name)
	  WHERE [status] = 'RUNNING' 
		AND [context] LIKE @context_search_pattern

	  -- Exit loop if no more Running Contexts
	  IF @@ROWCOUNT = 0 BREAK;

	  -- Delete the context (Which stops streaming)
	  EXEC [sp_compute_pool_context_delete] @compute_pool_name, @context

	END

END
GO

CREATE FUNCTION [dm_compute_pool_node_status](@compute_pool_name NVARCHAR(max))
RETURNS TABLE 
(node_id NVARCHAR(max), [state] NVARCHAR(max), connection_time NVARCHAR(max), [version] NVARCHAR(max), exception_message NVARCHAR(max), exception_stack NVARCHAR(max), exception_source NVARCHAR(max))  
AS   
EXTERNAL NAME compute_pool_assembly.[Microsoft.SqlServer.ComputePoolManagement.SqlClr.Supportabilty].ComputeNodesStatus;  
GO

CREATE FUNCTION [dm_compute_pools]()
RETURNS TABLE 
(name NVARCHAR(max), [nodes] NVARCHAR(max))  
AS   
EXTERNAL NAME compute_pool_assembly.[Microsoft.SqlServer.ComputePoolManagement.SqlClr.Supportabilty].GetPools;  
GO

CREATE FUNCTION [dm_compute_pool_table_status](
	@compute_pool_name NVARCHAR(max),
	@table_name NVARCHAR(max))
RETURNS TABLE 
(node_id NVARCHAR(max), [rows] NVARCHAR(max), exception_message NVARCHAR(max), exception_stack NVARCHAR(max), exception_source NVARCHAR(max))
AS   
EXTERNAL NAME compute_pool_assembly.[Microsoft.SqlServer.ComputePoolManagement.SqlClr.Supportabilty].ComputePoolTableStatus;  
GO

CREATE PROC [sp_compute_pool_cycle_log] 
AS EXTERNAL NAME compute_pool_assembly.[Microsoft.SqlServer.ComputePoolManagement.SqlClr.Supportabilty].CycleLog;
GO

CREATE PROC [sp_compute_pool_support_create_linked_servers](
	@compute_pool_name NVARCHAR(max),
	@node_count int)
AS EXTERNAL NAME compute_pool_assembly.[Microsoft.SqlServer.ComputePoolManagement.SqlClr.Supportabilty].CreateLinkedServers;
GO

CREATE PROC [sp_compute_pool_support_drop_linked_servers](
	@compute_pool_name NVARCHAR(max),
	@node_count int)
AS EXTERNAL NAME compute_pool_assembly.[Microsoft.SqlServer.ComputePoolManagement.SqlClr.Supportabilty].DropLinkedServers;
GO
