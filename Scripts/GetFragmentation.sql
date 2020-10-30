INSERT INTO DBA.dbo.IndexFragmentation
SELECT 
	GETDATE() as DateIn,
	t.name as tblname, 
	i.name as idxname,   
    CAST(ips.avg_fragmentation_in_percent AS DECIMAL(4, 2)) AS PctFragmented,
	ips.page_count AS PageCnt,
	(ips.page_count * 8) / 1024 AS sizeMB,
	ips.record_count as RecordCnt,
	STATS_DATE(ips.object_id, ips.index_id) AS StatsUpdated  
FROM sys.dm_db_index_physical_stats ( DB_ID(), NULL, NULL, NULL, 'sampled') ips  
JOIN sys.tables t on t.object_id = ips.object_id  
JOIN sys.indexes i ON i.object_id = ips.object_id
WHERE ips.index_id = i.index_id
AND ips.database_id = DB_ID()
AND i.name IS NOT NULL