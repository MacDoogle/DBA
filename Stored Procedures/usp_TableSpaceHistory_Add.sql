CREATE PROCEDURE dbo.usp_TableSpaceUsed_Add @HistoryDaysToKeep INT = 180
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    INSERT dbo.[TableSpaceUsed]
    (
        TableSchema,
        TableName,
        TableRows,
        TotalSpaceKB,
        UsedSpaceKB,
        UnusedSpaceKB
    )
    SELECT s.name AS TableSchema,
           t.name AS TableName,
           MAX(p.rows) AS TableRows,
           SUM(a.total_pages) * 8 AS TotalSpaceKB,
           SUM(a.used_pages) * 8 AS UsedSpaceKB,
           (SUM(a.total_pages) - SUM(a.used_pages)) * 8 AS UnusedSpaceKB
    FROM sys.tables t
        INNER JOIN sys.indexes i
            ON t.object_id = i.object_id
        INNER JOIN sys.partitions p
            ON i.object_id = p.object_id
               AND i.index_id = p.index_id
        INNER JOIN sys.allocation_units a
            ON p.partition_id = a.container_id
        INNER JOIN sys.schemas s
            ON t.schema_id = s.schema_id
    WHERE t.name NOT LIKE 'dt%'
          AND t.is_ms_shipped = 0
          AND i.object_id > 255
    GROUP BY s.name,
             t.name
    ORDER BY s.name,
             t.name;

    DELETE FROM dbo.[TableSpaceUsed]
    WHERE AnalysisDate < GETDATE() - @HistoryDaysToKeep;
END;
GO