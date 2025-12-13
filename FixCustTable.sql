-- =========== FIX CUSTOMER TABLE ===========
USE IBMS_Phase2;
GO

PRINT 'Fixing Customer table structure...';

-- Check if KYCStatus column exists, if not add it
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS 
               WHERE TABLE_NAME = 'Customer' AND COLUMN_NAME = 'KYCStatus')
BEGIN
    ALTER TABLE Customer ADD KYCStatus NVARCHAR(20) NOT NULL DEFAULT 'Pending';
    PRINT 'Added KYCStatus column to Customer table';
END

-- Check if KYCDocumentRef column exists, if not add it
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS 
               WHERE TABLE_NAME = 'Customer' AND COLUMN_NAME = 'KYCDocumentRef')
BEGIN
    ALTER TABLE Customer ADD KYCDocumentRef NVARCHAR(100) NULL;
    PRINT 'Added KYCDocumentRef column to Customer table';
END

PRINT 'Customer table structure fixed!';
GO