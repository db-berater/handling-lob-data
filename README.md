# Workshop - Making Bad Codes Better
This repository contains all codes for my workshop "Making Bad Codes Better" which deals with several real world examples of bad written SQL Code
All scripts are created for the use of Microsoft SQL Server (Version 2016 or higher)
To work with the scripts it is required to have the workshop database [ERP_Demo](https://www.db-berater.de/downloads/ERP_DEMO_2012.BAK) installed on your SQL Server Instance.
The last version of the demo database can be downloaded here:

**https://www.db-berater.de/downloads/ERP_DEMO_2012.BAK**

> Written by
>	[Uwe Ricken](https://www.db-berater.de/uwe-ricken/), 
>	[db Berater GmbH](https://db-berater.de)
> 
> All scripts are intended only as a supplement to demos and lectures
> given by Uwe Ricken.  
>   
> **THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF 
> ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED 
> TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
> PARTICULAR PURPOSE.**

**Note**
The database contains a framework for all workshops / sessions from db Berater GmbH
+ Stored Procedures
+ User Definied Inline Functions

Workshop Scripts for SQL Server Workshop "Making Bad Codes Better"

# Folder structure
+ Each scenario is stored in a separate folder (e.g. Scenario 01 in Folder Scenario 01)
+ All scripts have numbers and basically the script with the prefix 01 is for the preparation of the environment
+ The folder **SQL ostress** contains .cmd files as substitute for SQL Query Stress.
   To use ostress you must download and install the **[RML Utilities](https://learn.microsoft.com/en-us/troubleshoot/sql/tools/replay-markup-language-utility)**
   
+ The folder **Windows Admin Center** contains json files with the configuration of performance counter. These files can only be used with Windows Admin Center
  - [Windows Admin Center](https://www.microsoft.com/en-us/windows-server/windows-admin-center)
+ The folder **SQL Query Stress** contains prepared configuration settings for each scenario which produce load test with SQLQueryStress from Adam Machanic
  - [SQLQueryStress](https://github.com/ErikEJ/SqlQueryStress)
+ The folder **SQL Extended Events** contains scripts for the implementation of extended events for the different scenarios
  All extended events are written for "LIVE WATCHING" and will have target file for saving the results.

# Scenario 01
The development team love to work with user definied functions (UDF).
So they decided to create an UDF which calculates the status of any customer by year.
The calculation is a simple math:

+ A customer: More or equal than 20 orders in a given year
+ B customer: 10 - 19 orders for a given year
+ C customer: 05 - 09 orders for a given year
+ D customer: 01 - 04 orders for a given year
+ Z customer: no orders for a given year

# Scenario 02
A software uses a table to queue jobs. Whenever a new job is to be started, its details are written to this table. The table grows very quickly, as up to 100,000 jobs can be scheduled in an hour.
For this reason, a background job runs to clean up the job_queue table.
As a rule, more jobs are queued at a high rate than are processed. For this reason, the software manufacturer has decided to parameterize the process.
The first parameter specifies how many jobs that have already been executed should be deleted. The second parameter specifies the batch size, which determines how many records should be deleted from the table at the same time.

# Scenario 03
New employees have to be onboarded once a month and employees who leave the company have to be offboarded.
For this, authorizations have to be adjusted for all accessible systems. Among other things, the authorizations for the SAP system repeatedly cause very long waiting times, which have had a significant impact on subsequent and parallel processes.
When analyzing the system, one query stood out because it sometimes ran for several minutes for one process run.

# Scenario 04

# Scenario 05

# Scenario 06

# Scenario 07

# Scenario 08
