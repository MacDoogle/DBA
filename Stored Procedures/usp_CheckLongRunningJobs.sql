

CREATE PROCEDURE [dbo].[usp_CheckLongRunningJobs]
-- exec ipDBA_CheckForHangingSQLAgentJobs
-- Checks to see if any job (besides exclusions) have been running for more then 3 hours.  Sends an email if true.
AS
BEGIN
	DECLARE @jobname VARCHAR(400),
		@jobstart	 VARCHAR(100),
		@message	 VARCHAR(4000) = '',
		@EmailDBA	 VARCHAR(MAX)  = 'lukemac82@gmail.com';

	DECLARE jobs CURSOR FOR
		SELECT j.name,
			ja.start_execution_date
		FROM msdb.dbo.sysjobactivity ja
			INNER JOIN msdb.dbo.sysjobs j ON j.job_id = ja.job_id
		WHERE ja.start_execution_date <= DATEADD(mi, -180, GETDATE())
			AND ja.stop_execution_date IS NULL
			AND j.name != 'RSys Distribution Web Service Client - MOUNTAINRES'
			-- Only get the jobs running in the active session.
			AND ja.session_id = (SELECT MAX(session_id) from msdb.dbo.syssessions)
			-- cdc.Inntopia2_capture is always running, so ignore that.
			AND j.name != 'cdc.Inntopia2_capture';

	OPEN jobs;

	FETCH NEXT FROM jobs
	INTO @jobname,
		@jobstart;

	WHILE @@FETCH_STATUS = 0
	BEGIN

		SET @message = @message + @jobname + ' started on ' + @jobstart + CHAR(13);

		FETCH NEXT FROM jobs
		INTO @jobname,
			@jobstart;
	END;

	CLOSE jobs;
	DEALLOCATE jobs;

	IF @message IS NOT NULL AND @message != ''
	BEGIN
		DECLARE @msgSubject varchar(100)
		SET @msgSubject = 'Check Hanging SQL Agent Jobs - ' + @@SERVERNAME
		EXEC sp_send_dbmail @MailTo = @EmailDBA,
			@Subject = @msgSubject,
			@MailFromDisplay = 'DBAs',
			@MailFrom = @EmailDBA,
			@fText = 1,
			@Message = @message;
	END;
END;
GO


