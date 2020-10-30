CREATE TABLE [dbo].[IndexFragmentation](
	[DateIn] [datetime2](7) NOT NULL,
	[tblname] [varchar](200) NOT NULL,
	[idxname] [varchar](200) NOT NULL,
	[PctFragmented] [decimal](4, 2) NOT NULL,
	[PageCnt] [int] NOT NULL,
	[sizeMB] [bigint] NOT NULL,
	[RecordCnt] [bigint] NOT NULL,
	[StatsUpdated] [datetime2](7) NULL
) ON [PRIMARY]
