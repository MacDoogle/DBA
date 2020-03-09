/* Takes a comma delimented string of databases and runs a query against each one and inserts table sizes into DBA.dbo.TableSpacedUsed */

CREATE PROCEDURE [dbo].[usp_TableSpaceUsed_Add]
@Dbs VARCHAR(50),
@HistoryDaysToKeep INT = 180

AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	DECLARE @dbname NVARCHAR(100);
	DECLARE @cmd NVARCHAR(4000);

    DECLARE Database_Cursor CURSOR FAST_FORWARD FOR
	SELECT [name] from sys.databases WHERE ','+@Dbs+',' LIKE '%,'+CONVERT(VARCHAR(50),[name])+',%';
	
	OPEN Database_Cursor

	FETCH NEXT FROM Database_Cursor INTO @dbname
	WHILE @@FETCH_STATUS = 0
		BEGIN
			SET @cmd = '
			SELECT ''' + @dbname + ''',
				   s.name AS TableSchema,
				   t.name AS TableName,
				   MAX(p.rows) AS TableRows,
				   SUM(a.total_pages) * 8 AS TotalSpaceKB,
				   SUM(a.used_pages) * 8 AS UsedSpaceKB,
				   (SUM(a.total_pages) - SUM(a.used_pages)) * 8 AS UnusedSpaceKB
			FROM '+ @dbname +'.sys.tables t
				INNER JOIN '+ @dbname +'.sys.indexes i
					ON t.object_id = i.object_id
				INNER JOIN '+ @dbname +'.sys.partitions p
					ON i.object_id = p.object_id
					   AND i.index_id = p.index_id
				INNER JOIN '+ @dbname +'.sys.allocation_units a
					ON p.partition_id = a.container_id
				INNER JOIN '+ @dbname +'.sys.schemas s
					ON t.schema_id = s.schema_id
			WHERE t.name NOT LIKE ''dt%''
				  AND t.is_ms_shipped = 0
				  AND i.object_id > 255
			GROUP BY s.name,
					 t.name
			ORDER BY s.name,
					 t.name;'
	
	INSERT DBA.dbo.[TableSpaceUsed]
    (
        DatabaseName,
		TableSchema,
        TableName,
        TableRows,
        TotalSpaceKB,
        UsedSpaceKB,
        UnusedSpaceKB
    )
	EXECUTE sp_executesql @cmd
	
	FETCH NEXT FROM Database_Cursor INTO @dbname
	END	

	CLOSE Database_Cursor
	DEALLOCATE Database_Cursor
	
	DELETE FROM DBA.dbo.[TableSpaceUsed]
    WHERE AnalysisDate < GETDATE() - @HistoryDaysToKeep;
END;
GO


