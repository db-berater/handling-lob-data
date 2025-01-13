/*
	============================================================================
	File:		03 - extended event - lock_required.sql

	Summary:	This script creates an extended event to track all required
				and released locks on data pages to see, how Microsoft SQL
				Server will access data pages from overflow data

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
IF EXISTS (SELECT * FROM sys.server_event_sessions WHERE name = N'dbLockings')
	DROP EVENT SESSION dbLockings ON SERVER;
	GO

CREATE EVENT SESSION [dbLockings]
ON SERVER
ADD EVENT sqlserver.lock_acquired
(
	WHERE	[package0].[equal_uint64]([resource_type], 'PAGE')
			AND [sqlserver].[equal_i_sql_unicode_string]([sqlserver].[database_name], N'demo_db')
),
ADD EVENT sqlserver.lock_released
(
	WHERE	[package0].[equal_uint64]([resource_type], 'PAGE')
			AND [sqlserver].[equal_i_sql_unicode_string]([sqlserver].[database_name], N'demo_db')

),
ADD EVENT sqlserver.sql_batch_completed
(
	WHERE	[sqlserver].[is_system] = (0)
            AND [sqlserver].[database_name] = N'demo_db'
),
ADD EVENT sqlserver.sql_batch_starting
(
	WHERE	[sqlserver].[is_system] = (0)
            AND [sqlserver].[database_name] = N'demo_db'
)
WITH
(
    MAX_MEMORY = 4096KB,
    EVENT_RETENTION_MODE = ALLOW_SINGLE_EVENT_LOSS,
    MAX_DISPATCH_LATENCY = 5 SECONDS,
    MAX_EVENT_SIZE = 0KB,
    MEMORY_PARTITION_MODE = NONE,
    TRACK_CAUSALITY = OFF,
    STARTUP_STATE = OFF
);
GO

ALTER EVENT SESSION dbLockings ON SERVER STATE = START;
GO
