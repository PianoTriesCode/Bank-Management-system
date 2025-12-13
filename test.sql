SELECT name FROM sys.databases WHERE name = 'IBMS_Phase2';
GO

-- If it exists, check what tables are there
USE IBMS_Phase2;
GO
SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES;
GO