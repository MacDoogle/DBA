CREATE TABLE [dbo].[TableSpaceUsed](
	[DatabaseName] [nvarchar] (100) NOT NULL,
	[AnalysisDate] [datetime] NOT NULL,
	[TableSchema] [varchar](200) NOT NULL,
	[TableName] [varchar](200) NOT NULL,
	[TableRows] [int] NOT NULL,
	[TotalSpaceKB] [int] NOT NULL,
	[UsedSpaceKB] [int] NOT NULL,
	[UnusedSpaceKB] [int] NOT NULL,
 CONSTRAINT [PK_TableSpaceUsed] PRIMARY KEY CLUSTERED 
(
	[AnalysisDate] ASC,
	[DatabaseName] ASC,
	[TableSchema] ASC,
	[TableName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[TableSpaceUsed] ADD  CONSTRAINT [DF_TableSpaceUsed_AnalysisDate]  DEFAULT (getdate()) FOR [AnalysisDate]
GO