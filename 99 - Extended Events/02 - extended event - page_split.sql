/*
	============================================================================
	File:		02 - extended event - page_split.sql

	Summary:	This script creates an extended event which counts in a histogram
				the number of page_splits

	Date:		December 2022
	Session:	SQL Server - LOB Data Management

	SQL Server Version: >= 2016
	------------------------------------------------------------------------------
	Written by Uwe Ricken, db Berater GmbH

	This script is intended only as a supplement to demos and lectures
	given by Uwe Ricken.  
  
	THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF 
	ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED 
	TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
	PARTICULAR PURPOSE.
	============================================================================
*/
IF EXISTS (SELECT * FROM sys.dm_xe_sessions WHERE name = N'db_page_splits')
	DROP EVENT SESSION [db_page_splits] ON SERVER 
	GO


CREATE EVENT SESSION [db_page_splits]
	ON SERVER 
	ADD EVENT sqlserver.page_split
	(
		WHERE ([sqlserver].[database_name]=N'ERP_Demo')
	)
	ADD TARGET package0.histogram
	(
		SET filtering_event_name=N'sqlserver.page_split',
		source=N'file_id',
		source_type=(0)
	)
WITH
(
	MAX_MEMORY=4096 KB,
	EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,
	MAX_DISPATCH_LATENCY=5 SECONDS,
	MAX_EVENT_SIZE=0 KB,
	MEMORY_PARTITION_MODE=NONE,
	TRACK_CAUSALITY=OFF,
	STARTUP_STATE=OFF
)
GO

ALTER EVENT SESSION [db_page_splits] ON SERVER STATE = START;
GO