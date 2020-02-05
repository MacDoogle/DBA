CREATE TABLE [dbo].[PurgeTables]
(
	[TableName] VARCHAR(50) NOT NULL CONSTRAINT PK_TableName PRIMARY KEY,
	[PurgeByColumn] VARCHAR(50) NOT NULL,
	[Retention]	INT NOT NULL,
	[BatchSize] INT NOT NULL
)
