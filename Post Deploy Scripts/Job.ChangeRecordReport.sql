USE [msdb]
GO

BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance] ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA Record Table Space Used', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Executes usp_TableSpaceUsed and emails the report.', 
		@category_name=N'Database Maintenance', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Run usp_TableSpaceUsed]    Script Date: 2/27/2020 3:15:27 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Run usp_TableSpaceUsed', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXEC dbo.usp_TableSpaceUsed', 
		@database_name=N'DBA', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Email Report]    Script Date: 2/27/2020 3:15:27 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Email Report', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DECLARE @DT1 DATETIME, @DT2 DATETIME, @DT3 DATETIME;

SELECT @DT1 = MAX(AnalysisDate) FROM TableSpaceUsed;
SELECT @DT2 = MAX(AnalysisDate) FROM TableSpaceUsed WHERE AnalysisDate<DATEADD(hh, -23, @DT1);
SELECT @DT3 = MAX(AnalysisDate) FROM TableSpaceUsed WHERE AnalysisDate<DATEADD(mm, -1, DATEADD(hh, 1, @DT1));

-- SELECT @DT1, @DT2, @DT3

DECLARE @xml1 NVARCHAR(MAX) = CAST(( SELECT TOP 5
	t1.TableSchema as ''td'', '''',
	t1.TableName as ''td'', '''',
	t2.TableRows as ''td'', '''',
	t1.TableRows as ''td'', '''',
	t1.TableRows - t2.TableRows as ''td''
	FROM TableSpaceUsed t1
	INNER JOIN TableSpaceUsed t2 ON t1.TableSchema = t2.TableSchema AND t1.TableName = t2.TableName
	WHERE t1.AnalysisDate = @DT1 AND t2.AnalysisDate = @DT2
	ORDER BY t1.TableRows - t2.TableRows DESC
FOR XML PATH(''tr''), ELEMENTS) AS NVARCHAR(MAX));

DECLARE @xml2 NVARCHAR(MAX) = CAST(( SELECT TOP 5
	t1.TableSchema as ''td'', '''',
	t1.TableName as ''td'', '''',
	t2.TableRows as ''td'', '''',
	t1.TableRows as ''td'', '''',
	t1.TableRows - t2.TableRows as ''td''
	FROM TableSpaceUsed t1
	INNER JOIN TableSpaceUsed t2 ON t1.TableSchema = t2.TableSchema AND t1.TableName = t2.TableName
	WHERE t1.AnalysisDate = @DT1 AND t2.AnalysisDate = @DT3
	ORDER BY t1.TableRows - t2.TableRows DESC
FOR XML PATH(''tr''), ELEMENTS ) AS NVARCHAR(MAX));

DECLARE @xml3 NVARCHAR(MAX) = CAST(( SELECT TOP 5
	t1.TableSchema as ''td'',  '''',
	t1.TableName as ''td'',  '''',
	t2.TotalSpaceKB as ''td'',  '''',
	t1.TotalSpaceKB as ''td'',  '''',
	t1.TotalSpaceKB - t2.TotalSpaceKB as ''td''
	FROM TableSpaceUsed t1
	INNER JOIN TableSpaceUsed t2 ON t1.TableSchema = t2.TableSchema AND t1.TableName = t2.TableName
	WHERE t1.AnalysisDate = @DT1 AND t2.AnalysisDate = @DT2
	ORDER BY t1.TotalSpaceKB - t2.TotalSpaceKB DESC
FOR XML PATH(''tr''), ELEMENTS ) AS NVARCHAR(MAX));

DECLARE @xml4 NVARCHAR(MAX) = CAST(( SELECT TOP 5
	t1.TableSchema as ''td'',  '''',
	t1.TableName as ''td'',  '''',
	t2.TotalSpaceKB as ''td'',  '''',
	t1.TotalSpaceKB as ''td'',  '''',
	t1.TotalSpaceKB - t2.TotalSpaceKB as ''td''
	FROM TableSpaceUsed t1
	INNER JOIN TableSpaceUsed t2 ON t1.TableSchema = t2.TableSchema AND t1.TableName = t2.TableName
	WHERE t1.AnalysisDate = @DT1 AND t2.AnalysisDate = @DT3
	ORDER BY t1.TotalSpaceKB - t2.TotalSpaceKB DESC
FOR XML PATH(''tr''), ELEMENTS ) AS NVARCHAR(MAX));

DECLARE @Subject NVARCHAR(MAX) = N''Table Space Increase Report For '' + CONVERT(VARCHAR(20), GETDATE(), 101);
DECLARE @Header NVARCHAR(MAX) = ''<tr><th>Schema</th><th>Table</th><th>Old Value</th><th>New Value</th><th>Difference</th></tr>'';

DECLARE @HTMLOutput NVARCHAR(MAX) = ''<html><body>''
	+ ''<H3>Top Daily Row Gainers</H3><table border = 1>'' + @Header + @xml1 + ''</table><br>''
	+ ''<H3>Top Monthly Row Gainers</H3><table border = 1>'' + @Header + @xml2 + ''</table><br>''
	+ ''<H3>Top Daily Space Gainers (in KB)</H3><table border = 1>'' + @Header + @xml3 + ''</table><br>''
	+ ''<H3>Top Monthly Space Gainers (in KB)</H3><table border = 1>'' + @Header + @xml4 + ''</table>''
	+ ''</body></html>'';

--SELECT @HTMLOutput

DECLARE @recipients VARCHAR(MAX) = utility.GetConfigurationString(''Email.DBA'');

EXEC msdb.dbo.sp_send_dbmail
	@profile_name=''SQL Agent'',
	@recipients=@recipients,
	@subject=@Subject,
	@body=@HTMLOutput,
	@body_format=''HTML'';
', 
		@database_name=N'DBA', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Weekly 9 AM', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=2, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20160802, 
		@active_end_date=99991231, 
		@active_start_time=90000, 
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


