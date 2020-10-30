CREATE TABLE [dbo].[IndexUsageStats](
	[ObjectName] [sysname] NOT NULL,
	[IndexName] [sysname] NOT NULL,
	[IndexType] [sysname] NOT NULL,
	[TotalUserSeeks] [bigint] NULL,
	[TotalUserScans] [bigint] NULL,
	[TotalUserLookups] [bigint] NULL,
	[TotalUserUpdates] [bigint] NULL,
	[SumReads] [bigint] NULL,
	[rws] [int] NULL,
	[is_unique_constraint] [tinyint] NULL,
	[CheckDate] [datetime2](7) NOT NULL,
 CONSTRAINT [PK_IndexUsageStats] PRIMARY KEY CLUSTERED 
(
	[CheckDate] ASC,
	[IndexName] ASC,
	[ObjectName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]