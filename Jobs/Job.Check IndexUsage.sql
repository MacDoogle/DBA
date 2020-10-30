USE [msdb]
GO

/****** Object:  Job [DBA Check Index Usage]    Script Date: 10/30/2020 2:21:43 PM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 10/30/2020 2:21:43 PM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA Check Index Usage', 
		@enabled=0, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Runs daily to get read and writes of indexes to determine their general value.  High writes with no reads defeats purpose of indexes.  Generally look for indexes with at least 10x more updates then reads.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Update IndexUsageStats]    Script Date: 10/30/2020 2:21:44 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Update IndexUsageStats', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'-- Collects index information into CTE before loading it into IndexUsageStats table.

WITH IndexCTE (ObjectName, IndexName, IndexType, TotalUserSeeks, 
TotalUserScans, TotalUserLookups, TotalUserUpdates, SumReads, rws, is_unique_constraint, CheckDate)
AS
(
SELECT 
     SCHEMA_NAME([sObj].[schema_id]) + ''.'' + [sObj].[name] AS [ObjectName],
     ISNULL([sIdx].[name], ''N/A'') AS [IndexName],
     CASE
      WHEN [sIdx].[type] = 0 THEN ''Heap''
      WHEN [sIdx].[type] = 1 THEN ''Clustered''
      WHEN [sIdx].[type] = 2 THEN ''Nonclustered''
      WHEN [sIdx].[type] = 3 THEN ''XML''
      WHEN [sIdx].[type] = 4 THEN ''Spatial''
      WHEN [sIdx].[type] = 5 THEN ''Reserved for future use''
      WHEN [sIdx].[type] = 6 THEN ''Nonclustered columnstore index''
     END AS [IndexType]
   , [sdmvIUS].[user_seeks] AS [TotalUserSeeks]
   , [sdmvIUS].[user_scans] AS [TotalUserScans]
   , [sdmvIUS].[user_lookups] AS [TotalUserLookups]
   , [sdmvIUS].[user_updates] AS [TotalUserUpdates]
   , [sdmvIUS].[user_seeks] + [sdmvIUS].[user_scans] + [sdmvIUS].[user_lookups] AS [SumReads]
   , [p].[rows] AS [rws]
   ,sIdx.is_unique_constraint
   ,GETDATE()
FROM
   [sys].[indexes] AS [sIdx]
   INNER JOIN [sys].[objects] AS [sObj]
      ON [sIdx].[object_id] = [sObj].[object_id]
   LEFT JOIN [sys].[dm_db_index_usage_stats] AS [sdmvIUS]
      ON [sIdx].[object_id] = [sdmvIUS].[object_id]
      AND [sIdx].[index_id] = [sdmvIUS].[index_id]
      AND [sdmvIUS].[database_id] = DB_ID()
   LEFT JOIN [sys].[dm_db_index_operational_stats] (DB_ID(),NULL,NULL,NULL) AS [sdmfIOPS]
      ON [sIdx].[object_id] = [sdmfIOPS].[object_id]
	  AND [sIdx].[index_id] = [sdmfIOPS].[index_id]
	LEFT JOIN sys.partitions AS p
	 ON sIdx.object_id = p.object_id
	 AND sIDx.index_id = p.index_id
WHERE
   [sObj].[type] IN (''U'',''V'')         -- Look in Tables & Views
   AND [sObj].[is_ms_shipped] = 0x0   -- Exclude System Generated Objects
   )

   INSERT INTO DBA.dbo.IndexUsageStats
   SELECT * FROM IndexCTE', 
		@database_name=N'DBA', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Check Indexes 9PM', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=2, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20200826, 
		@active_end_date=99991231, 
		@active_start_time=210000, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO


