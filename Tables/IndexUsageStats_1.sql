CREATE TABLE [dbo].[IndexUsageStats](
	[ObjectName] [sysname] NOT NULL,
	[IndexName] [sysname] NOT NULL,
	[IndexType] [sysname] NOT NULL,
	[TotalUserSeeks] [BIGINT] NULL,
	[TotalUserScans] [BIGINT] NULL,
	[TotalUserLookups] [BIGINT] NULL,
	[TotalUserUpdates] [BIGINT] NULL,
	[SumReads] [BIGINT] NULL,
	[rws] [INT] NULL,
	[is_unique_constraint] [TINYINT] NULL,
	[CheckDate] [DATETIME2](7) NOT NULL,
 CONSTRAINT [PK_IndexUsageStats] PRIMARY KEY CLUSTERED 
(
	[CheckDate] ASC,
	[IndexName] ASC,
	[ObjectName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 95) ON [PRIMARY]
) ON [PRIMARY]