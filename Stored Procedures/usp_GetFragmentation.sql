CREATE PROCEDURE [dbo].[usp_GetFragmentation]
	@param1 int = 0,
	@param2 int
AS
	WITH CTE_Fragmentation
AS (
SELECT GETDATE() AS DateIn,
	OBJECT_NAME(object_id, DB_ID()) AS tblname,
	OBJECT_NAME(index_id,DB_ID()) AS idxname,
	CAST(avg_fragmentation_in_percent AS DECIMAL(4, 2)) AS PctFragmented,
	page_count AS page_count,
	(page_count * 8) / 1024 AS sizeMB,
	record_count,
	STATS_DATE(object_id, index_id) AS StatsUpdated
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'sampled')
WHERE database_id = DB_ID() AND avg_fragmentation_in_percent > '15' AND page_count > 1000)

INSERT INTO DBA.dbo.IndexFragmentation
SELECT [DateIn], [tblname], [idxname], [PctFragmented], [page_count], [sizeMB], record_count, [StatsUpdated]
FROM CTE_Fragmentation
WHERE idxname IS NOT NULL;
