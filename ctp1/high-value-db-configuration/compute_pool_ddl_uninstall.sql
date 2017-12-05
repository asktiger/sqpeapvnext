DECLARE @hash BINARY(64)
SET @hash = (SELECT HASHBYTES('SHA2_512', c1) FROM OPENROWSET(BULK '/root/clr/Microsoft.SqlServer.ComputePoolManagement.SqlClr.dll', SINGLE_BLOB) AS st(c1))
EXEC sp_drop_trusted_assembly  @hash
SET @hash = (SELECT HASHBYTES('SHA2_512', c1) FROM OPENROWSET(BULK '/root/clr/Microsoft.SqlServer.ComputePoolManagement.dll', SINGLE_BLOB) AS st(c1))
EXEC sp_drop_trusted_assembly  @hash
SET @hash = (SELECT HASHBYTES('SHA2_512', c1) FROM OPENROWSET(BULK '/root/clr/Microsoft.Practices.EnterpriseLibrary.TransientFaultHandling.dll', SINGLE_BLOB) AS st(c1))
EXEC sp_drop_trusted_assembly  @hash
SET @hash = (SELECT HASHBYTES('SHA2_512', c1) FROM OPENROWSET(BULK '/root/clr/System.Runtime.dll', SINGLE_BLOB) AS st(c1))
EXEC sp_drop_trusted_assembly  @hash
SET @hash = (SELECT HASHBYTES('SHA2_512', c1) FROM OPENROWSET(BULK '/root/clr/System.ComponentModel.Composition.dll', SINGLE_BLOB) AS st(c1))
EXEC sp_drop_trusted_assembly  @hash
SET @hash = (SELECT HASHBYTES('SHA2_512', c1) FROM OPENROWSET(BULK '/root/clr/System.Threading.Tasks.dll', SINGLE_BLOB) AS st(c1))
EXEC sp_drop_trusted_assembly  @hash
SET @hash = (SELECT HASHBYTES('SHA2_512', c1) FROM OPENROWSET(BULK '/root/clr/System.Resources.ResourceManager.dll', SINGLE_BLOB) AS st(c1))
EXEC sp_drop_trusted_assembly  @hash
SET @hash = (SELECT HASHBYTES('SHA2_512', c1) FROM OPENROWSET(BULK '/root/clr/System.Globalization.dll', SINGLE_BLOB) AS st(c1))
EXEC sp_drop_trusted_assembly  @hash
SET @hash = (SELECT HASHBYTES('SHA2_512', c1) FROM OPENROWSET(BULK '/root/clr/System.Diagnostics.Tools.dll', SINGLE_BLOB) AS st(c1))
EXEC sp_drop_trusted_assembly  @hash
SET @hash = (SELECT HASHBYTES('SHA2_512', c1) FROM OPENROWSET(BULK '/root/clr/System.Diagnostics.Debug.dll', SINGLE_BLOB) AS st(c1))
EXEC sp_drop_trusted_assembly  @hash
SET @hash = (SELECT HASHBYTES('SHA2_512', c1) FROM OPENROWSET(BULK '/root/clr/System.Linq.dll', SINGLE_BLOB) AS st(c1))
EXEC sp_drop_trusted_assembly  @hash
SET @hash = (SELECT HASHBYTES('SHA2_512', c1) FROM OPENROWSET(BULK '/root/clr/System.Collections.dll', SINGLE_BLOB) AS st(c1))
EXEC sp_drop_trusted_assembly  @hash
SET @hash = (SELECT HASHBYTES('SHA2_512', c1) FROM OPENROWSET(BULK '/root/clr/System.Threading.dll', SINGLE_BLOB) AS st(c1))
EXEC sp_drop_trusted_assembly  @hash
SET @hash = (SELECT HASHBYTES('SHA2_512', c1) FROM OPENROWSET(BULK '/root/clr/System.Runtime.Extensions.dll', SINGLE_BLOB) AS st(c1))
EXEC sp_drop_trusted_assembly  @hash
SET @hash = (SELECT HASHBYTES('SHA2_512', c1) FROM OPENROWSET(BULK '/root/clr/Microsoft.Azure.SqlDatabase.ElasticScale.Client.dll', SINGLE_BLOB) AS st(c1))
EXEC sp_drop_trusted_assembly  @hash
SET @hash = (SELECT HASHBYTES('SHA2_512', c1) FROM OPENROWSET(BULK '/root/clr/System.Runtime.Serialization.dll', SINGLE_BLOB) AS st(c1))
EXEC sp_drop_trusted_assembly  @hash
SET @hash = (SELECT HASHBYTES('SHA2_512', c1) FROM OPENROWSET(BULK '/root/clr/System.ServiceModel.Internals.dll', SINGLE_BLOB) AS st(c1))
EXEC sp_drop_trusted_assembly  @hash
SET @hash = (SELECT HASHBYTES('SHA2_512', c1) FROM OPENROWSET(BULK '/root/clr/SMDiagnostics.dll', SINGLE_BLOB) AS st(c1))
EXEC sp_drop_trusted_assembly  @hash
SET @hash = (SELECT HASHBYTES('SHA2_512', c1) FROM OPENROWSET(BULK '/root/clr/Microsoft.Practices.EnterpriseLibrary.TransientFaultHandling.Data.dll', SINGLE_BLOB) AS st(c1))
EXEC sp_drop_trusted_assembly  @hash
SET @hash = (SELECT HASHBYTES('SHA2_512', c1) FROM OPENROWSET(BULK '/root/clr/System.Data.Entity.dll', SINGLE_BLOB) AS st(c1))
EXEC sp_drop_trusted_assembly  @hash
SET @hash = (SELECT HASHBYTES('SHA2_512', c1) FROM OPENROWSET(BULK '/root/clr/System.ComponentModel.DataAnnotations.dll', SINGLE_BLOB) AS st(c1))
EXEC sp_drop_trusted_assembly  @hash
SET @hash = (SELECT HASHBYTES('SHA2_512', c1) FROM OPENROWSET(BULK '/root/clr/Newtonsoft.Json.dll', SINGLE_BLOB) AS st(c1))
EXEC sp_drop_trusted_assembly  @hash
GO

DROP PROC IF EXISTS [sp_compute_pool_create] 
DROP PROC IF EXISTS [sp_compute_pool_create_table] 
DROP PROC IF EXISTS [sp_compute_pool_start_import]
DROP PROC IF EXISTS [sp_compute_pool_stop_import]
DROP PROC IF EXISTS [sp_compute_pool_drop_table] 
DROP PROC IF EXISTS [sp_compute_pool_drop] 
DROP PROC IF EXISTS [sp_compute_pool_job_delete]
DROP PROC IF EXISTS [sp_compute_pool_context_delete]
DROP PROC IF EXISTS [sp_compute_pool_cycle_log]
DROP PROC IF EXISTS [sp_compute_pool_support_create_linked_servers]
DROP PROC IF EXISTS [sp_compute_pool_support_drop_linked_servers]
DROP FUNCTION IF EXISTS [dm_compute_pool_jobs] 
DROP FUNCTION IF EXISTS [dm_compute_pool_node_status] 
DROP FUNCTION IF EXISTS [dm_compute_pools] 
DROP FUNCTION IF EXISTS [dm_compute_pool_external_table_status] 
DROP FUNCTION IF EXISTS [dm_compute_pool_table_status] 
GO

DROP ASSEMBLY compute_pool_assembly 
GO