CREATE TABLE [dbo].[IndexFragmentation](
	[DateIn] [datetime2](7) NOT NULL,
	[tblname] [varchar](50) NOT NULL,
	[idxname] [varchar](100) NOT NULL,
	[PctFragmented] [decimal](4, 2) NOT NULL,
	[page_count] [int] NOT NULL,
	[sizeMB] [bigint] NOT NULL,
	[RecordCount] [bigint] NOT NULL,
	[StatsUpdated] [datetime2](7) NULL
) ON [PRIMARY]