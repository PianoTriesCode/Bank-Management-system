/* -----------------------------------------------------------
   PHASE 2: DATABASE CREATION SCRIPT
   Group: 39
   Members: Muhammad Sohaf Khan, Shaheer Hammad, Rafia Imran
   Project: Integrated Banking Management System (IBMS)
   -----------------------------------------------------------
*/

/* -----------------------------------------------------------
   SETTING UP THE DATABASE AND SCHEMA
   -----------------------------------------------------------
*/

-- Use the correct database
USE master;
GO
IF EXISTS (SELECT * FROM sys.databases WHERE name = 'IBMS_Phase2')
BEGIN
    ALTER DATABASE IBMS_Phase2 SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE IBMS_Phase2;
END
GO
CREATE DATABASE IBMS_Phase2;
GO
USE IBMS_Phase2;
GO

-- CLEANUP: Drop tables in reverse dependency order to avoid FK errors
DROP TABLE IF EXISTS AuditLog;
DROP TABLE IF EXISTS ScheduledJob;
DROP TABLE IF EXISTS LoanPayment;
DROP TABLE IF EXISTS Loan;
DROP TABLE IF EXISTS CardTransaction;
DROP TABLE IF EXISTS Card;
DROP TABLE IF EXISTS [Transaction]; -- Transaction is a reserved keyword that's why we use brackets
DROP TABLE IF EXISTS Account;
DROP TABLE IF EXISTS AccountType;
DROP TABLE IF EXISTS Beneficiary;
DROP TABLE IF EXISTS Customer;
ALTER TABLE Branch DROP CONSTRAINT IF EXISTS FK_Branch_Manager; -- Break circular dependency
DROP TABLE IF EXISTS Employee;
DROP TABLE IF EXISTS Branch;
GO

CREATE TABLE Branch (
    BranchID INT PRIMARY KEY IDENTITY(1,1),
    Name NVARCHAR(100) NOT NULL,
    Location NVARCHAR(255) NOT NULL,
    ManagerEmployeeID INT NULL -- FK added later due to circular dependency
);

CREATE TABLE Employee (
    EmployeeID INT PRIMARY KEY IDENTITY(1,1),
    FullName NVARCHAR(100) NOT NULL,
    Role NVARCHAR(50) NOT NULL, -- 'Manager', 'Teller', 'Admin'
    BranchID INT NOT NULL,
    CONSTRAINT FK_Employee_Branch FOREIGN KEY (BranchID) REFERENCES Branch(BranchID)
);

-- Now add the circular FK back to Branch
ALTER TABLE Branch
ADD CONSTRAINT FK_Branch_Manager FOREIGN KEY (ManagerEmployeeID) REFERENCES Employee(EmployeeID);

-- === CUSTOMER DOMAIN ===
CREATE TABLE Customer (
    CustomerID INT PRIMARY KEY IDENTITY(1,1),
    FullName NVARCHAR(100) NOT NULL,
    DOB DATE NOT NULL,
    Email NVARCHAR(100) NOT NULL UNIQUE,
    Phone NVARCHAR(20) NOT NULL,
    Address NVARCHAR(255) NOT NULL,
    CreatedAt DATETIME2 DEFAULT GETDATE()
);

CREATE TABLE Beneficiary (
    BeneficiaryID INT PRIMARY KEY IDENTITY(1,1),
    CustomerID INT NOT NULL,
    BeneficiaryAccountNumber NVARCHAR(20) NOT NULL,
    BankName NVARCHAR(100) NOT NULL,
    Nickname NVARCHAR(50),
    CONSTRAINT FK_Beneficiary_Customer FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID)
);

-- === ACCOUNTS ===
CREATE TABLE AccountType (
    AccountTypeID INT PRIMARY KEY IDENTITY(1,1),
    Name NVARCHAR(50) NOT NULL UNIQUE, -- 'Savings', 'Checking'
    InterestRate DECIMAL(5, 2) NOT NULL DEFAULT 0.00,
    MinBalance DECIMAL(18, 2) NOT NULL DEFAULT 0.00
);

CREATE TABLE Account (
    AccountID INT PRIMARY KEY IDENTITY(1,1),
    AccountNumber NVARCHAR(20) NOT NULL UNIQUE,
    CustomerID INT NOT NULL,
    AccountTypeID INT NOT NULL,
    BranchID INT NOT NULL,
    Balance DECIMAL(18, 2) NOT NULL DEFAULT 0.00,
    Status NVARCHAR(20) NOT NULL DEFAULT 'Active', -- 'Active', 'Frozen', 'Closed'
    CreatedDate DATETIME2 NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_Account_Customer FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID),
    CONSTRAINT FK_Account_Type FOREIGN KEY (AccountTypeID) REFERENCES AccountType(AccountTypeID),
    CONSTRAINT FK_Account_Branch FOREIGN KEY (BranchID) REFERENCES Branch(BranchID)
);

-- === TRANSACTIONS (The heavy lifter for 1 Million rows) ===
CREATE TABLE [Transaction] (
    TransactionID BIGINT PRIMARY KEY IDENTITY(1,1), -- BIGINT for scalability
    FromAccountID INT NULL, -- Null for Deposits
    ToAccountID INT NULL,   -- Null for Withdrawals
    Amount DECIMAL(18, 2) NOT NULL,
    TransactionType NVARCHAR(20) NOT NULL, -- 'Transfer', 'Deposit', 'Withdrawal', 'Fee', 'Interest'
    Status NVARCHAR(20) NOT NULL DEFAULT 'Completed',
    InitiatedBy NVARCHAR(100) NOT NULL, -- 'Customer-X', 'Employee-Y', 'System'
    Timestamp DATETIME2 NOT NULL DEFAULT GETDATE(),
    Reference NVARCHAR(100) NULL,
    CONSTRAINT FK_Trans_From FOREIGN KEY (FromAccountID) REFERENCES Account(AccountID),
    CONSTRAINT FK_Trans_To FOREIGN KEY (ToAccountID) REFERENCES Account(AccountID)
);

-- === CARDS ===
CREATE TABLE Card (
    CardID INT PRIMARY KEY IDENTITY(1,1),
    CardNumber NVARCHAR(16) NOT NULL UNIQUE,
    AccountID INT NOT NULL,
    CardType NVARCHAR(20) NOT NULL, -- 'Debit', 'Credit'
    ExpiryDate DATE NOT NULL,
    Status NVARCHAR(20) NOT NULL DEFAULT 'Active',
    CVV NVARCHAR(3) NOT NULL,
    CONSTRAINT FK_Card_Account FOREIGN KEY (AccountID) REFERENCES Account(AccountID)
);

CREATE TABLE CardTransaction (
    CardTxID BIGINT PRIMARY KEY IDENTITY(1,1),
    CardID INT NOT NULL,
    Amount DECIMAL(18, 2) NOT NULL,
    Merchant NVARCHAR(100) NOT NULL,
    Timestamp DATETIME2 NOT NULL DEFAULT GETDATE(),
    AuthorizationCode NVARCHAR(50) NOT NULL,
    CONSTRAINT FK_CardTx_Card FOREIGN KEY (CardID) REFERENCES Card(CardID)
);

-- === LOANS ===
CREATE TABLE Loan (
    LoanID INT PRIMARY KEY IDENTITY(1,1),
    CustomerID INT NOT NULL,
    AccountID INT NOT NULL, -- The account where funds are disbursed
    PrincipalAmount DECIMAL(18, 2) NOT NULL,
    InterestRate DECIMAL(5, 2) NOT NULL,
    TermMonths INT NOT NULL,
    StartDate DATE NOT NULL,
    EndDate DATE NULL,
    Status NVARCHAR(20) NOT NULL DEFAULT 'Applied', -- 'Approved', 'Active', 'Closed'
    CONSTRAINT FK_Loan_Customer FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID),
    CONSTRAINT FK_Loan_Account FOREIGN KEY (AccountID) REFERENCES Account(AccountID)
);

CREATE TABLE LoanPayment (
    LoanPaymentID INT PRIMARY KEY IDENTITY(1,1),
    LoanID INT NOT NULL,
    PaymentDate DATETIME2 NOT NULL DEFAULT GETDATE(),
    Amount DECIMAL(18, 2) NOT NULL,
    PaymentMethod NVARCHAR(50) NOT NULL, -- 'AccountTransfer', 'Cash'
    CONSTRAINT FK_LoanPayment_Loan FOREIGN KEY (LoanID) REFERENCES Loan(LoanID)
);

-- === SYSTEM & AUDIT ===
CREATE TABLE ScheduledJob (
    JobID INT PRIMARY KEY IDENTITY(1,1),
    JobName NVARCHAR(100) NOT NULL UNIQUE,
    StoredProcedureName NVARCHAR(100) NOT NULL,
    Frequency NVARCHAR(20) NOT NULL,
    IsEnabled BIT NOT NULL DEFAULT 1,
    LastRun DATETIME2 NULL,
    NextRun DATETIME2 NULL
);

CREATE TABLE AuditLog (
    AuditID BIGINT PRIMARY KEY IDENTITY(1,1),
    EntityName NVARCHAR(100) NOT NULL,
    EntityID NVARCHAR(100) NOT NULL,
    Action NVARCHAR(50) NOT NULL,
    PerformedBy NVARCHAR(100) NOT NULL,
    Timestamp DATETIME2 NOT NULL DEFAULT GETDATE(),
    Details NVARCHAR(MAX) NULL
);
GO

PRINT 'Database Schema Created Successfully.';

/* -----------------------------------------------------------------
   POPULATING THE DATABASE FULL OF DATA (GOAL OF 1 MILLION VALUES)
   -----------------------------------------------------------------
*/

USE IBMS_Phase2;
GO
SET NOCOUNT ON;

PRINT '>>> Step 1: Seeding Static Data...';

-- 1. Seed Account Types (The Products)
-- We need different rules for different accounts.
IF NOT EXISTS (SELECT 1 FROM AccountType)
BEGIN
    INSERT INTO AccountType (Name, InterestRate, MinBalance)
    VALUES 
    ('Standard Savings', 1.50, 100.00),
    ('High-Yield Savings', 4.25, 5000.00),
    ('Student Checking', 0.05, 0.00),
    ('Standard Checking', 0.10, 500.00),
    ('Business Premium', 0.50, 10000.00);
    
    PRINT '   + Inserted 5 Account Types.';
END

IF NOT EXISTS (SELECT 1 FROM ScheduledJob)
BEGIN
    INSERT INTO ScheduledJob (JobName, StoredProcedureName, Frequency, IsEnabled)
    VALUES 
    ('Daily Interest Calculation', 'sp_CalculateDailyInterest', 'Daily', 1),
    ('Monthly Maintenance Fee', 'sp_ApplyMonthlyFees', 'Monthly', 1),
    ('Loan Payment Processor', 'sp_ProcessAutoPayments', 'Daily', 1),
    ('Dormant Account Check', 'sp_CheckDormancy', 'Weekly', 1);

    PRINT '   + Inserted 4 System Jobs.';
END

IF NOT EXISTS (SELECT 1 FROM Branch)
BEGIN
    INSERT INTO Branch (Name, Location)
    VALUES 
    ('Headquarters', '101 Wall St, New York, NY'),
    ('Downtown Hub', '450 5th Ave, New York, NY'),
    ('Westside Branch', '880 W 42nd St, New York, NY'),
    ('Brooklyn Operations', '12 Atlantic Ave, Brooklyn, NY'),
    ('Queens Community', '500 Queens Blvd, Queens, NY'),
    ('Tech Campus Kiosk', '1000 Innovation Dr, San Jose, CA'),
    ('London Overseas', '1 Canary Wharf, London, UK'),
    ('Toronto Plaza', '200 Bay St, Toronto, ON'),
    ('Singapore FinTech', '10 Marina Blvd, Singapore'),
    ('Virtual Branch', '000 Server Room, Cloud');

    PRINT '   + Inserted 10 Branches (Managers Pending).';
END

PRINT '>>> Step 2: Seeding Population...';

-- 1. GENERATE EMPLOYEES (50 Staff Members)
DECLARE @i INT = 1;
DECLARE @TotalEmployees INT = 50;
DECLARE @RandBranchID INT;
DECLARE @FirstName NVARCHAR(50);
DECLARE @LastName NVARCHAR(50);

WHILE @i <= @TotalEmployees
BEGIN
    -- Randomly assign to Branch 1-10
    SET @RandBranchID = (ABS(CHECKSUM(NEWID())) % 10) + 1;
    
    INSERT INTO Employee (FullName, Role, BranchID)
    VALUES (
        'Employee_' + CAST(@i AS NVARCHAR(10)), -- Generic Name
        CASE WHEN @i % 5 = 0 THEN 'Manager' ELSE 'Teller' END, -- Every 5th is a Manager (logic only)
        @RandBranchID
    );

    SET @i = @i + 1;
END
PRINT '   + Inserted 50 Employees.';

UPDATE B
SET B.ManagerEmployeeID = E.EmployeeID
FROM Branch B
CROSS APPLY (
    SELECT TOP 1 EmployeeID 
    FROM Employee 
    WHERE BranchID = B.BranchID 
    ORDER BY EmployeeID ASC -- Just pick the first one found
) E;

PRINT '   + Circular Dependency Resolved: Managers assigned to Branches.';

-- 3. GENERATE CUSTOMERS (10,000 Rows)
SET @i = 1;
DECLARE @TotalCustomers INT = 10000;

WHILE @i <= @TotalCustomers
BEGIN
    INSERT INTO Customer (FullName, DOB, Email, Phone, Address)
    VALUES (
        'Customer_' + CAST(@i AS NVARCHAR(10)), -- Name: Customer_101
        DATEADD(DAY, -ABS(CHECKSUM(NEWID()) % 10000), '2000-01-01'), -- Random DOB approx 25-50 years old
        'user' + CAST(@i AS NVARCHAR(10)) + '@ibms-demo.com', -- Unique Email: user101@ibms-demo.com
        '555-' + RIGHT('0000' + CAST(ABS(CHECKSUM(NEWID()) % 10000) AS NVARCHAR(4)), 4), -- Random Phone
        CAST(ABS(CHECKSUM(NEWID()) % 999) AS NVARCHAR(10)) + ' Random St, City ' + CAST(@i % 50 AS NVARCHAR(5)) -- Random Address
    );

    SET @i = @i + 1;
END
PRINT '   + Inserted 10,000 Customers.';
SET @i = 1;
DECLARE @TotalBeneficiaries INT = 2500;
DECLARE @RandCustID INT;

WHILE @i <= @TotalBeneficiaries
BEGIN
    -- Pick a random customer ID between 1 and 10000
    SET @RandCustID = (ABS(CHECKSUM(NEWID())) % 10000) + 1;

    INSERT INTO Beneficiary (CustomerID, BeneficiaryAccountNumber, BankName, Nickname)
    VALUES (
        @RandCustID,
        'EXT-' + CAST(ABS(CHECKSUM(NEWID())) AS NVARCHAR(15)), -- Random Account Num
        CASE (ABS(CHECKSUM(NEWID())) % 3) 
            WHEN 0 THEN 'Chase' 
            WHEN 1 THEN 'BoA' 
            ELSE 'Wells Fargo' 
        END,
        'Friend_' + CAST(@i AS NVARCHAR(10))
    );

    SET @i = @i + 1;
END
PRINT '   + Inserted 2,500 Beneficiaries.';

PRINT '>>> Step 2 Complete.';
GO

/*
   -----------------------------------------------------------
   SEEDING SCRIPT: STEP 3 - ACCOUNTS, CARDS & LOANS
   Tables: Account, Card, Loan, LoanPayment
   -----------------------------------------------------------
*/

USE IBMS_Phase2;
GO
SET NOCOUNT ON;

PRINT '>>> Step 3: Seeding Financial Products...';

-- 1. CREATE CHECKING ACCOUNTS (One for every Customer)
-- Optimization: Using Set-Based Insert (Faster than loops)
INSERT INTO Account (AccountNumber, CustomerID, AccountTypeID, BranchID, Balance, Status)
SELECT 
    'CK-' + CAST(100000 + CustomerID AS NVARCHAR(20)), -- Generates CK-100001, CK-100002...
    CustomerID,
    4, -- Assuming ID 4 is 'Standard Checking' from Step 1
    (ABS(CHECKSUM(NEWID())) % 10) + 1, -- Random Branch 1-10
    CAST(ABS(CHECKSUM(NEWID()) % 50000) + 500 AS DECIMAL(18,2)), -- Random Balance $500 - $50,000
    'Active'
FROM Customer;

PRINT '   + Created Checking Accounts for all Customers.';

-- 2. CREATE SAVINGS ACCOUNTS (For ~50% of Customers)
INSERT INTO Account (AccountNumber, CustomerID, AccountTypeID, BranchID, Balance, Status)
SELECT 
    'SV-' + CAST(200000 + CustomerID AS NVARCHAR(20)), 
    CustomerID,
    1, -- Assuming ID 1 is 'Standard Savings'
    (ABS(CHECKSUM(NEWID())) % 10) + 1,
    CAST(ABS(CHECKSUM(NEWID()) % 100000) + 1000 AS DECIMAL(18,2)),
    'Active'
FROM Customer
WHERE (CustomerID % 2) = 0; -- Only even numbered IDs get savings

PRINT '   + Created Savings Accounts for 50% of Customers.';

-- 3. ISSUE DEBIT CARDS
-- Logic: Issue a card only for Checking Accounts (AccountTypeID = 4)
INSERT INTO Card (CardNumber, AccountID, CardType, ExpiryDate, Status, CVV)
SELECT 
    -- Generate a pseudo-valid 16-digit number: 4000 + AccountID padded
    '4000' + RIGHT('000000000000' + CAST(AccountID AS NVARCHAR(12)), 12), 
    AccountID,
    'Debit',
    DATEADD(YEAR, 3, GETDATE()), -- Expires 3 years from now
    'Active',
    CAST(100 + (ABS(CHECKSUM(NEWID())) % 899) AS NVARCHAR(3)) -- Random CVV 100-999
FROM Account
WHERE AccountTypeID = 4;

PRINT '   + Issued Debit Cards for all Checking Accounts.';

-- 4. GENERATE LOANS (For ~5% of Customers)
-- This requires a Cursor/Loop because we need to generate Payments for each loan immediately
DECLARE @LoanCustID INT;
DECLARE @LoanAccountID INT;
DECLARE @NewLoanID INT;
DECLARE @LoanAmount DECIMAL(18,2);
DECLARE @Counter INT = 0;

-- Select random 5% of customers who have a checking account
DECLARE LoanCursor CURSOR FOR
SELECT TOP 5 PERCENT CustomerID, AccountID 
FROM Account 
WHERE AccountTypeID = 4 -- Use their checking account for funds
ORDER BY NEWID(); -- Randomize

OPEN LoanCursor;
FETCH NEXT FROM LoanCursor INTO @LoanCustID, @LoanAccountID;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @LoanAmount = CAST(ABS(CHECKSUM(NEWID()) % 20000) + 5000 AS DECIMAL(18,2)); -- $5k-$25k

    -- A. Create the Loan
    INSERT INTO Loan (CustomerID, AccountID, PrincipalAmount, InterestRate, TermMonths, StartDate, Status)
    VALUES (
        @LoanCustID, 
        @LoanAccountID, 
        @LoanAmount, 
        5.5, 
        24, 
        DATEADD(MONTH, -6, GETDATE()), -- Loan started 6 months ago
        'Active'
    );

    SET @NewLoanID = SCOPE_IDENTITY();

    -- C. Create 5 Historical Payments for this loan
    DECLARE @p INT = 1;
    WHILE @p <= 5
    BEGIN
        INSERT INTO LoanPayment (LoanID, PaymentDate, Amount, PaymentMethod)
        VALUES (
            @NewLoanID,
            DATEADD(MONTH, -@p, GETDATE()), -- 1 month ago, 2 months ago...
            (@LoanAmount / 24), -- Rough monthly payment
            'AccountTransfer'
        );
        SET @p = @p + 1;
    END

    SET @Counter = @Counter + 1;
    FETCH NEXT FROM LoanCursor INTO @LoanCustID, @LoanAccountID;
END

CLOSE LoanCursor;
DEALLOCATE LoanCursor;

PRINT '   + Created ' + CAST(@Counter AS NVARCHAR(10)) + ' Loans with historical payments.';
PRINT '>>> Step 3 Complete.';
GO

/*
   -----------------------------------------------------------
   SEEDING SCRIPT: STEP 4 - HIGH VOLUME TRANSACTIONS
   Tables: [Transaction], CardTransaction
   Goal: Reach ~1 Million Total Rows
   -----------------------------------------------------------
*/

PRINT '>>> Step 4: Generating High Volume Transaction Data...';
PRINT '    (This may take 30-60 seconds. Please wait.)';

-- 1. GET REFERENCE DATA (To ensure FK validity)
DECLARE @MaxAccountID INT = (SELECT MAX(AccountID) FROM Account);
DECLARE @MaxCardID INT = (SELECT MAX(CardID) FROM Card);

-- 2. GENERATE BANK TRANSACTIONS (~800,000 Rows)
-- We use a "Batch" approach to be fast.
DECLARE @BatchSize INT = 1000;
DECLARE @TargetRows INT = 800000;
DECLARE @CurrentRows INT = 0;

WHILE @CurrentRows < @TargetRows
BEGIN
    -- Insert 1,000 rows at a time using a "Virtual Table" technique
    INSERT INTO [Transaction] (FromAccountID, ToAccountID, Amount, TransactionType, Status, InitiatedBy, Timestamp, Reference)
    SELECT TOP (@BatchSize)
        -- Random 'From' Account (1 to Max)
        (ABS(CHECKSUM(NEWID())) % @MaxAccountID) + 1,
        
        -- Random 'To' Account (1 to Max)
        (ABS(CHECKSUM(NEWID())) % @MaxAccountID) + 1,
        
        -- Random Amount ($10 to $1000)
        CAST((ABS(CHECKSUM(NEWID())) % 990) + 10 AS DECIMAL(18,2)),
        
        -- Random Type
        CASE (ABS(CHECKSUM(NEWID())) % 3)
            WHEN 0 THEN 'Transfer'
            WHEN 1 THEN 'Deposit'
            ELSE 'Withdrawal'
        END,
        
        'Completed',
        'System_Seeder',
        
        -- Random Date (Within last 2 years)
        DATEADD(HOUR, -ABS(CHECKSUM(NEWID()) % 17000), GETDATE()),
        
        'REF-' + LEFT(NEWID(), 8) -- Random GUID snippet
    FROM sys.all_columns AS a -- Using system tables just to get a source of 1000 rows quickly
    CROSS JOIN sys.all_columns AS b;

    SET @CurrentRows = @CurrentRows + @BatchSize;
    
    -- PrintING progress every 100k rows
    IF @CurrentRows % 100000 = 0
        PRINT '    ... Inserted ' + CAST(@CurrentRows AS VARCHAR) + ' Bank Transactions.';
END

-- 3. GENERATE CARD TRANSACTIONS (~200,000 Rows)
SET @CurrentRows = 0;
SET @TargetRows = 200000;

WHILE @CurrentRows < @TargetRows
BEGIN
    INSERT INTO CardTransaction (CardID, Amount, Merchant, Timestamp, AuthorizationCode)
    SELECT TOP (@BatchSize)
        -- Random CardID
        (ABS(CHECKSUM(NEWID())) % @MaxCardID) + 1,
        
        -- Random Amount ($5 to $200)
        CAST((ABS(CHECKSUM(NEWID())) % 195) + 5 AS DECIMAL(18,2)),
        
        -- Random Merchant
        CASE (ABS(CHECKSUM(NEWID())) % 5)
            WHEN 0 THEN 'Amazon'
            WHEN 1 THEN 'Uber'
            WHEN 2 THEN 'Starbucks'
            WHEN 3 THEN 'Walmart'
            ELSE 'Netflix'
        END,
        
        -- Random Date
        DATEADD(HOUR, -ABS(CHECKSUM(NEWID()) % 17000), GETDATE()),
        
        -- Random Auth Code
        LEFT(NEWID(), 6)
    FROM sys.all_columns AS a
    CROSS JOIN sys.all_columns AS b;

    SET @CurrentRows = @CurrentRows + @BatchSize;
    
    IF @CurrentRows % 50000 = 0
        PRINT '    ... Inserted ' + CAST(@CurrentRows AS VARCHAR) + ' Card Transactions.';
END

PRINT '>>> Step 4 Complete.';
GO

-- === FINAL VERIFICATION ===
PRINT '==========================================';
PRINT 'FINAL DATABASE ROW COUNTS:';
SELECT 'Customers' as TableName, COUNT(*) as Count FROM Customer
UNION ALL
SELECT 'Accounts', COUNT(*) FROM Account
UNION ALL
SELECT 'Cards', COUNT(*) FROM Card
UNION ALL
SELECT 'Loans', COUNT(*) FROM Loan
UNION ALL
SELECT 'Bank Transactions', COUNT(*) FROM [Transaction]
UNION ALL
SELECT 'Card Transactions', COUNT(*) FROM CardTransaction;
PRINT '==========================================';

/* ------------------------------
   FEATURES AND FUCTIONALITIES
   ------------------------------
*/

USE IBMS_Phase2;
GO
SET NOCOUNT ON;
GO

-- =========== Quick peek: first 10 rows of each main table ===========
PRINT '--- Quick reference: TOP 10 rows from main tables ---';
SELECT TOP (10) * FROM Customer;
SELECT TOP (10) * FROM Account;
SELECT TOP (10) * FROM AccountType;
SELECT TOP (10) * FROM Beneficiary;
SELECT TOP (10) * FROM [Transaction];
SELECT TOP (10) * FROM Card;
SELECT TOP (10) * FROM CardTransaction;
SELECT TOP (10) * FROM Loan;
SELECT TOP (10) * FROM LoanPayment;
SELECT TOP (10) * FROM Employee;
SELECT TOP (10) * FROM Branch;
SELECT TOP (10) * FROM AuditLog;
PRINT '--- End quick reference ---';
GO

-- =========== Nonclustered index on Account(CustomerID) to speed lookups ===========
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'INDEX_Account_CustomerID' AND object_id = OBJECT_ID('Account'))
BEGIN
    CREATE NONCLUSTERED INDEX INDEX_Account_CustomerID ON Account(CustomerID);
END
GO

-- =========== Filtered index example on Account(Status) for active accounts only ===========
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'INDEX_Account_Active' AND object_id = OBJECT_ID('Account'))
BEGIN
    CREATE NONCLUSTERED INDEX INDEX_Account_Active ON Account(Status)
    WHERE Status = 'Active';
END
GO

-- =========== Inline table-valued function to show summary ===========
IF OBJECT_ID('dbo.func_CustomerSummary', 'IF') IS NOT NULL
    DROP FUNCTION dbo.func_CustomerSummary;
GO
CREATE FUNCTION dbo.func_CustomerSummary(@CustomerID INT)
RETURNS TABLE
AS
RETURN
(
    SELECT
        C.CustomerID,
        C.FullName,
        C.Email,
        C.Phone,
        C.Address,
        AccountID = A.AccountID,
        A.AccountNumber,
        A.AccountTypeID,
        A.Balance
    FROM Customer C
    LEFT JOIN Account A ON A.CustomerID = C.CustomerID
    WHERE C.CustomerID = @CustomerID
);
GO

-- =========== view_Customer360 - aggregated view showing customer + accounts + totals ===========
IF OBJECT_ID('dbo.view_Customer360', 'V') IS NOT NULL
    DROP VIEW dbo.view_Customer360;
GO
CREATE VIEW dbo.view_Customer360
AS
SELECT
    C.CustomerID,
    C.FullName,
    C.Email,
    C.Phone,
    C.Address,
    TotalAccounts = COUNT(A.AccountID),
    TotalBalance = ISNULL(SUM(A.Balance), 0.00)
FROM Customer C
LEFT JOIN Account A ON A.CustomerID = C.CustomerID
GROUP BY
    C.CustomerID, C.FullName, C.Email, C.Phone, C.Address;
GO

-- To see reults
SELECT * FROM dbo.view_Customer360;

-- =========== view_ActiveAccountsByBranch - gives view of active accounts in all branches ===========
IF OBJECT_ID('dbo.view_ActiveAccountsByBranch', 'V') IS NOT NULL
    DROP VIEW dbo.view_ActiveAccountsByBranch;
GO
CREATE VIEW dbo.view_ActiveAccountsByBranch
AS
SELECT
    B.BranchID, B.Name AS BranchName,
    A.AccountID, A.AccountNumber, A.CustomerID, A.Balance, A.Status
FROM Branch B
JOIN Account A ON A.BranchID = B.BranchID
WHERE A.Status = 'Active';
GO

-- To see results, sorted by BranchID and AccountID
SELECT * FROM dbo.view_ActiveAccountsByBranch ORDER BY BranchID, AccountID;

-- =========== Simple view for allowing editing of only a subset of customer fields ===========
IF OBJECT_ID('dbo.view_CustomerEditable', 'V') IS NOT NULL
    DROP VIEW dbo.view_CustomerEditable;
GO
CREATE VIEW dbo.view_CustomerEditable
AS
SELECT CustomerID, FullName, Email, Phone, Address FROM Customer;
GO

-- Instead-of trigger to allow updates/inserts via the view and write audit entries
IF OBJECT_ID('dbo.trigger_view_CustomerEditable', 'TR') IS NOT NULL
    DROP TRIGGER dbo.trigger_view_CustomerEditable;
GO
CREATE TRIGGER dbo.trigger_view_CustomerEditable
ON dbo.view_CustomerEditable
INSTEAD OF UPDATE, INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- Handle INSERTS through view -> insert into Customer
    IF EXISTS (SELECT 1 FROM inserted)
    BEGIN
        INSERT INTO Customer (FullName, DOB, Email, Phone, Address)
        SELECT
            ISNULL(FullName, 'Unknown'),
            DATEADD(YEAR, -25, GETDATE()), -- placeholder DOB if none provided (must be handled by app)
            Email,
            Phone,
            ISNULL(Address, '')
        FROM inserted
        WHERE NOT EXISTS (SELECT 1 FROM Customer C WHERE C.Email = inserted.Email);
    END

    -- Handle UPDATE
    IF EXISTS (SELECT 1 FROM deleted) AND EXISTS (SELECT 1 FROM inserted)
    BEGIN
        UPDATE C
        SET
            FullName = I.FullName,
            Email = I.Email,
            Phone = I.Phone,
            Address = I.Address
        FROM Customer C
        JOIN inserted I ON C.CustomerID = I.CustomerID;

        -- Log the update for each changed row
        INSERT INTO AuditLog (EntityName, EntityID, Action, PerformedBy, Timestamp, Details)
        SELECT
            'Customer',
            CAST(I.CustomerID AS NVARCHAR(100)),
            'Update via view_CustomerEditable',
            ISNULL(SUSER_SNAME(), 'UnknownUser'),
            GETDATE(),
            'Updated FullName/Email/Phone/Address'
        FROM inserted I;
    END
END;
GO

-- =========== AFTER TRIGGERS: After INSERT on Customer -> write AuditLog ===========
IF OBJECT_ID('dbo.trigger_Customer_AfterInsert', 'TR') IS NOT NULL
    DROP TRIGGER dbo.trigger_Customer_AfterInsert;
GO
CREATE TRIGGER dbo.trigger_Customer_AfterInsert
ON Customer
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO AuditLog (EntityName, EntityID, Action, PerformedBy, Timestamp, Details)
    SELECT
        'Customer',
        CAST(i.CustomerID AS NVARCHAR(100)),
        'CreateCustomer',
        ISNULL(SUSER_SNAME(), 'Seeder_or_App'),
        GETDATE(),
        'New customer created via sp or UI'
    FROM inserted i;
END;
GO

-- TESTING INSERT AND UPDATE USING TRIGGERS
-- SELECT *
-- FROM dbo.view_CustomerEditable
-- WHERE Email = 'sohaf@email.com';

-- SELECT TOP (10) * FROM AuditLog;

-- INSERT INTO dbo.view_CustomerEditable (FullName, Email, Phone)
-- VALUES ('Sohaf', 'sohaf@email.com', '67420');

-- SELECT *
-- FROM dbo.view_CustomerEditable
-- WHERE Email = 'sohaf@email.com';

-- SELECT *
-- FROM Customer
-- WHERE Email = 'sohaf@email.com';

-- SELECT TOP (10) * FROM AuditLog;

-- UPDATE dbo.view_CustomerEditable
-- SET Phone = '6767-42',
--     Address = '467-Gulbahar'
-- WHERE Email = 'sohaf@email.com';

-- SELECT *
-- FROM Customer
-- WHERE Email = 'sohaf@email.com';

-- SELECT TOP 10 * FROM AuditLog ORDER BY Timestamp DESC;

-- =========== Create Customer using Stored Procedure ===========
IF OBJECT_ID('dbo.sp_CreateCustomer', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_CreateCustomer;
GO
CREATE PROCEDURE dbo.sp_CreateCustomer
    @FullName NVARCHAR(100),
    @DOB DATE,
    @Email NVARCHAR(100),
    @Phone NVARCHAR(20),
    @Address NVARCHAR(255),
    @NewCustomerID INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRAN;

        IF EXISTS (SELECT 1 FROM Customer WHERE Email = @Email)
        BEGIN
            RAISERROR('A customer with this email already exists.', 16, 1);
            ROLLBACK TRAN;
            RETURN;
        END

        INSERT INTO Customer (FullName, DOB, Email, Phone, Address, CreatedAt)
        VALUES (@FullName, @DOB, @Email, @Phone, @Address, GETDATE());

        SET @NewCustomerID = SCOPE_IDENTITY();

        INSERT INTO AuditLog (EntityName, EntityID, Action, PerformedBy, Timestamp, Details)
        VALUES ('Customer', CAST(@NewCustomerID AS NVARCHAR(100)), 'sp_CreateCustomer', ISNULL(SUSER_SNAME(), 'Seeder_or_App'), GETDATE(),
                'Customer created');

        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRAN;
        DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR('Error in sp_CreateCustomer: %s', 16, 1, @ErrMsg);
    END CATCH
END;
GO

-- TESTING STORED PROCEDURE FOR CREATION
-- DECLARE @NewCustomerID INT;

-- EXEC dbo.sp_CreateCustomer
--     @FullName = 'Shaheer Hammad',
--     @DOB = '1980-06-07',
--     @Email = 'shamala@example.com',
--     @Phone = '123-456-789',
--     @Address = '123 Baker Road',
--     @NewCustomerID = @NewCustomerID OUTPUT;

-- SELECT @NewCustomerID AS NewCustomerID;

-- SELECT *
-- FROM Customer
-- WHERE Email = 'shamala@example.com';

-- SELECT TOP 10 * FROM AuditLog ORDER BY Timestamp DESC;


-- =========== READ Customer using Stored Procedure ===========
IF OBJECT_ID('dbo.sp_GetCustomerByID', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_GetCustomerByID;
GO
CREATE PROCEDURE dbo.sp_GetCustomerByID
    @CustomerID INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Return customer basic row
    SELECT * FROM Customer WHERE CustomerID = @CustomerID;

    -- Return accounts using the inline table value function defined above
    SELECT * FROM dbo.func_CustomerSummary(@CustomerID);

    -- Return summary totals
    SELECT
        TotalAccounts = COUNT(A.AccountID),
        TotalBalance = ISNULL(SUM(A.Balance), 0.00)
    FROM Account A
    WHERE A.CustomerID = @CustomerID;
END;
GO

-- Testing READ
-- EXEC dbo.sp_GetCustomerByID @CustomerID = 10002;

-- =========== UPDATE Customer using Stored Procedure ===========
IF OBJECT_ID('dbo.sp_UpdateCustomer', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_UpdateCustomer;
GO
CREATE PROCEDURE dbo.sp_UpdateCustomer
    @CustomerID INT,
    @FullName NVARCHAR(100) = NULL,
    @DOB DATE = NULL,
    @Email NVARCHAR(100) = NULL,
    @Phone NVARCHAR(20) = NULL,
    @Address NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRAN;

        UPDATE Customer
        SET
            FullName = ISNULL(@FullName, FullName),
            DOB = ISNULL(@DOB, DOB),
            Email = ISNULL(@Email, Email),
            Phone = ISNULL(@Phone, Phone),
            Address = ISNULL(@Address, Address)
        WHERE CustomerID = @CustomerID;

        INSERT INTO AuditLog (EntityName, EntityID, Action, PerformedBy, Timestamp, Details)
        VALUES ('Customer', CAST(@CustomerID AS NVARCHAR(100)), 'sp_UpdateCustomer', ISNULL(SUSER_SNAME(), 'Seeder_or_App'), GETDATE(),
                'Fields updated via sp_UpdateCustomer');

        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRAN;
        THROW;
    END CATCH
END;
GO

-- Testing Update
-- EXEC dbo.sp_UpdateCustomer
--     @CustomerID = 10003,
--     @Phone = '555-999-888',
--     @Address = '22 Buldak Noodles';

-- SELECT *
-- FROM Customer
-- WHERE Email = 'shamala@example.com';

-- SELECT TOP 10 * FROM AuditLog ORDER BY Timestamp DESC;

-- =========== DELETE Customer using Stored Procedure ===========
IF OBJECT_ID('dbo.sp_DeleteCustomer', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_DeleteCustomer;
GO
CREATE PROCEDURE dbo.sp_DeleteCustomer
    @CustomerID INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRAN;

        -- Prevent delete if they have active accounts (business rule)
        IF EXISTS (SELECT 1 FROM Account WHERE CustomerID = @CustomerID AND Status = 'Active')
        BEGIN
            RAISERROR('Cannot delete customer with active accounts. Close accounts first.', 16, 1);
            ROLLBACK TRAN;
            RETURN;
        END

        DELETE FROM Beneficiary WHERE CustomerID = @CustomerID;
        DELETE FROM Customer WHERE CustomerID = @CustomerID;

        INSERT INTO AuditLog (EntityName, EntityID, Action, PerformedBy, Timestamp, Details)
        VALUES ('Customer', CAST(@CustomerID AS NVARCHAR(100)), 'sp_DeleteCustomer', ISNULL(SUSER_SNAME(), 'Seeder_or_App'), GETDATE(),
                'Customer deleted via sp_DeleteCustomer');

        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRAN;
        THROW;
    END CATCH
END;
GO

-- Testing Delete
-- EXEC dbo.sp_DeleteCustomer
--     @CustomerID = 10002;

-- SELECT *
-- FROM Customer
-- WHERE Email = 'shamala@example.com';

-- SELECT TOP 10 * FROM AuditLog ORDER BY Timestamp DESC;

-- --------------------------------------------------------------------
-- FOR ATOMIC TRNASFER OF FUNDS
-- Stored Procedure: sp_TransferFunds
--  - Parameters:
--      @FromAccountID, @ToAccountID, @Amount, @InitiatedBy, @Reference
--      @NewTransactionID OUTPUT
--  - Behavior:
--      * Locks both account rows with UPDLOCK, ROWLOCK (ordered by AccountID to reduce deadlocks) to achieve consistency
--      * Verifies both accounts exist and are Active
--      * Checks sufficient balance on FromAccount
--      * Updates balances in the same transaction
--      * Inserts a single record into [Transaction]
--      * Writes an AuditLog entry
--      * Retries up to 3 times on deadlock (error 1205)
-- --------------------------------------------------------------------

IF OBJECT_ID('dbo.sp_TransferFunds', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_TransferFunds;
GO

CREATE PROCEDURE dbo.sp_TransferFunds
    @FromAccountID INT,
    @ToAccountID INT,
    @Amount DECIMAL(18,2),
    @InitiatedBy NVARCHAR(100) = NULL,
    @Reference NVARCHAR(200) = NULL,
    @NewTransactionID BIGINT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF @FromAccountID IS NULL OR @ToAccountID IS NULL
    BEGIN
        RAISERROR('FromAccountID and ToAccountID must be provided.', 16, 1);
        RETURN;
    END

    IF @Amount IS NULL OR @Amount <= 0
    BEGIN
        RAISERROR('Amount must be a positive value.', 16, 1);
        RETURN;
    END

    IF @FromAccountID = @ToAccountID
    BEGIN
        RAISERROR('FromAccountID and ToAccountID cannot be the same.', 16, 1);
        RETURN;
    END

    DECLARE @attempt INT = 1;
    DECLARE @maxAttempts INT = 3;
    DECLARE @delay NVARCHAR(8) = '00:00:00.200'; -- delay in case of deadlock before retrying

    DECLARE @errnum INT;
    DECLARE @errmsg NVARCHAR(4000);

    SET @NewTransactionID = NULL;

    WHILE @attempt <= @maxAttempts
    BEGIN
        BEGIN TRY
            BEGIN TRAN;

            -- Lock both account rows in a stable order to reduce deadlocks.
            -- UPDLOCK obtains update locks, ROWLOCK uses row-level.
            -- We select both rows in one statement to ensure ordering.
            DECLARE @A1 INT = CASE WHEN @FromAccountID < @ToAccountID THEN @FromAccountID ELSE @ToAccountID END;
            DECLARE @A2 INT = CASE WHEN @FromAccountID < @ToAccountID THEN @ToAccountID ELSE @FromAccountID END;

            SELECT AccountID, Balance, Status
            FROM dbo.Account WITH (ROWLOCK, UPDLOCK)
            WHERE AccountID IN (@A1, @A2)
            ORDER BY AccountID;

            -- Re-read balances into local variables
            DECLARE @FromBalance DECIMAL(18,2);
            DECLARE @ToBalance DECIMAL(18,2);
            DECLARE @FromStatus NVARCHAR(50);
            DECLARE @ToStatus NVARCHAR(50);

            SELECT @FromBalance = Balance, @FromStatus = Status
            FROM dbo.Account WITH (ROWLOCK, UPDLOCK)
            WHERE AccountID = @FromAccountID;

            SELECT @ToBalance = Balance, @ToStatus = Status
            FROM dbo.Account WITH (ROWLOCK, UPDLOCK)
            WHERE AccountID = @ToAccountID;

            -- Validate if both accounts exist
            IF @FromBalance IS NULL
            BEGIN
                RAISERROR('FromAccountID does not exist.', 16, 1);
                ROLLBACK TRAN;
                RETURN;
            END
            IF @ToBalance IS NULL
            BEGIN
                RAISERROR('ToAccountID does not exist.', 16, 1);
                ROLLBACK TRAN;
                RETURN;
            END

            -- Validate if both accounts are Active
            IF ISNULL(@FromStatus,'') <> 'Active'
            BEGIN
                RAISERROR('From account is not Active.', 16, 1);
                ROLLBACK TRAN;
                RETURN;
            END
            IF ISNULL(@ToStatus,'') <> 'Active'
            BEGIN
                RAISERROR('To account is not Active.', 16, 1);
                ROLLBACK TRAN;
                RETURN;
            END

            -- Checking for sufficient funds
            IF @FromBalance < @Amount
            BEGIN
                RAISERROR('Insufficient funds on source account.', 16, 1);
                ROLLBACK TRAN;
                RETURN;
            END

            -- Updating balances
            UPDATE dbo.Account
            SET Balance = Balance - @Amount
            WHERE AccountID = @FromAccountID;

            UPDATE dbo.Account
            SET Balance = Balance + @Amount
            WHERE AccountID = @ToAccountID;

            INSERT INTO dbo.[Transaction] (FromAccountID, ToAccountID, Amount, TransactionType, Status, InitiatedBy, Timestamp, Reference)
            VALUES (@FromAccountID, @ToAccountID, @Amount, 'Transfer', 'Completed', ISNULL(@InitiatedBy, SUSER_SNAME()), SYSUTCDATETIME(), @Reference);

            SET @NewTransactionID = SCOPE_IDENTITY();

            -- Audit log entry
            INSERT INTO dbo.AuditLog (EntityName, EntityID, Action, PerformedBy, Timestamp, Details)
            VALUES ('Transaction', CAST(@NewTransactionID AS NVARCHAR(100)), 'sp_TransferFunds', ISNULL(@InitiatedBy, SUSER_SNAME()), GETDATE(),
                    CONCAT('Transfer of ', FORMAT(@Amount, 'N2'), ' from Account ', @FromAccountID, ' to ', @ToAccountID, '; TxID=', CAST(@NewTransactionID AS NVARCHAR(50))));

            COMMIT TRAN;

            BREAK;
        END TRY
        BEGIN CATCH
            SET @errnum = ERROR_NUMBER();
            SET @errmsg = ERROR_MESSAGE();

            IF XACT_STATE() <> 0
            BEGIN
                ROLLBACK TRAN;
            END

            -- Deadlock (1205) - retry
            IF @errnum = 1205 AND @attempt < @maxAttempts
            BEGIN
                SET @attempt = @attempt + 1;
                WAITFOR DELAY @delay; -- wait before trying again
                CONTINUE;
            END
            ELSE
            BEGIN
                RAISERROR('Transfer failed: %s (Err=%d)', 16, 1, @errmsg, @errnum);
                RETURN;
            END
        END CATCH
    END

    -- If @NewTransactionID null, means all attempts failed
    IF @NewTransactionID IS NULL
    BEGIN
        RAISERROR('Transfer did not complete after retries.', 16, 1);
    END
END;
GO

-- TESTING ATOMIC TRANSACTION
-- SELECT * FROM dbo.view_ActiveAccountsByBranch ORDER BY BranchID, AccountID;

-- DECLARE @TxID BIGINT;

-- EXEC dbo.sp_TransferFunds
--     @FromAccountID = 20,
--     @ToAccountID = 32,
--     @Amount = 924.00,
--     @InitiatedBy = 'admin_user',
--     @Reference = 'Test transfer',
--     @NewTransactionID = @TxID OUTPUT;

-- SELECT @TxID AS NewTransactionID;

-- SELECT TOP 10 * FROM AuditLog ORDER BY Timestamp DESC;

-- SELECT * FROM dbo.view_ActiveAccountsByBranch ORDER BY BranchID, AccountID;

-- =========== PARTITION FUNCTIONALITY FOR TRANSACTIONS ===========
-- Create partition function by year (Range RIGHT = include boundary in higher partition)
IF NOT EXISTS (SELECT * FROM sys.partition_functions WHERE name = 'PF_TransactionByYear')
BEGIN
    CREATE PARTITION FUNCTION PF_TransactionByYear (DATETIME2)
    AS RANGE RIGHT FOR VALUES (
        '2019-01-01', '2020-01-01', '2021-01-01', '2022-01-01', '2023-01-01', '2024-01-01', '2025-01-01', '2026-01-01'
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.partition_schemes WHERE name = 'PS_TransactionByYear')
BEGIN
    -- Map all partitions to PRIMARY filegroup for simplicity (adjust for real deployment)
    CREATE PARTITION SCHEME PS_TransactionByYear
    AS PARTITION PF_TransactionByYear
    ALL TO ([PRIMARY]);
END
GO

IF OBJECT_ID('dbo.Transaction_Partitioned', 'U') IS NOT NULL
    DROP TABLE dbo.Transaction_Partitioned;
GO
CREATE TABLE dbo.Transaction_Partitioned
(
    TransactionID BIGINT NOT NULL IDENTITY(1,1),
    FromAccountID INT NULL,
    ToAccountID INT NULL,
    Amount DECIMAL(18,2) NOT NULL,
    TransactionType NVARCHAR(20) NOT NULL,
    Status NVARCHAR(20) NOT NULL DEFAULT 'Completed',
    InitiatedBy NVARCHAR(100) NOT NULL,
    Timestamp DATETIME2 NOT NULL,
    Reference NVARCHAR(100) NULL,

    CONSTRAINT PK_Transaction_Partitioned PRIMARY KEY (Timestamp, TransactionID)
) ON PS_TransactionByYear(Timestamp);
GO

-- Checking if it was made successfully
SELECT
    TransactionID,
    Timestamp,
    $PARTITION.PF_TransactionByYear(Timestamp) AS PartitionNumber
FROM dbo.Transaction_Partitioned
ORDER BY PartitionNumber, Timestamp;

SELECT 
    p.partition_number,
    p.rows
FROM sys.partitions p
JOIN sys.objects o ON p.object_id = o.object_id
WHERE o.name = 'Transaction_Partitioned'
  AND p.index_id IN (0, 1);

SELECT TOP 20 *
FROM dbo.[Transaction]
ORDER BY TransactionID DESC;
GO


-- ===============================
-- ====== Helper Functions =======
-- ===============================
CREATE PROCEDURE GetAllAuditLogs
AS
BEGIN
    SELECT 
        AuditID,
        EntityName,
        EntityID,
        Action,
        PerformedBy,
        Timestamp,
        Details
    FROM AuditLog
    ORDER BY Timestamp DESC;
END;
GO

-- Loan Management

USE IBMS_Phase2;
GO

PRINT '>>> Implementing Loan Lifecycle Management...';

IF OBJECT_ID('dbo.sp_ApplyForLoan', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_ApplyForLoan;
GO
CREATE PROCEDURE dbo.sp_ApplyForLoan
    @CustomerID INT,
    @AccountID INT,
    @PrincipalAmount DECIMAL(18, 2),
    @InterestRate DECIMAL(5, 2),
    @TermMonths INT,
    @AppliedBy NVARCHAR(100),
    @NewLoanID INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRAN;

        IF NOT EXISTS (SELECT 1 FROM Customer WHERE CustomerID = @CustomerID)
        BEGIN
            RAISERROR('Invalid Customer ID.', 16, 1);
            ROLLBACK TRAN;
            RETURN;
        END

        IF NOT EXISTS (SELECT 1 FROM Account WHERE AccountID = @AccountID AND CustomerID = @CustomerID)
        BEGIN
            RAISERROR('Account does not belong to the specified customer.', 16, 1);
            ROLLBACK TRAN;
            RETURN;
        END

        INSERT INTO Loan (CustomerID, AccountID, PrincipalAmount, InterestRate, TermMonths, StartDate, Status)
        VALUES (@CustomerID, @AccountID, @PrincipalAmount, @InterestRate, @TermMonths, GETDATE(), 'Applied');

        SET @NewLoanID = SCOPE_IDENTITY();

        INSERT INTO AuditLog (EntityName, EntityID, Action, PerformedBy, Timestamp, Details)
        VALUES ('Loan', CAST(@NewLoanID AS NVARCHAR(100)), 'ApplyForLoan', @AppliedBy, GETDATE(),
                CONCAT('Loan Application: $', @PrincipalAmount, ' for ', @TermMonths, ' months at ', @InterestRate, '%'));

        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRAN;
        THROW;
    END CATCH
END;
GO

CREATE PROCEDURE sp_ApproveLoan
    @LoanID INT,
    @ApprovedBy NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRAN;

        DECLARE @PrincipalAmount DECIMAL(18,2);

        SELECT @PrincipalAmount = PrincipalAmount
        FROM Loan 
        WHERE LoanID = @LoanID AND Status = 'Applied';

        IF @@ROWCOUNT = 0
            THROW 50003, 'Loan not found or not in Applied status.', 1;

    
        UPDATE Loan 
        SET Status = 'Approved',
            StartDate = GETDATE(),
            EndDate = DATEADD(MONTH, TermMonths, GETDATE())
        WHERE LoanID = @LoanID;

        -- Audit log
        INSERT INTO AuditLog (EntityName, EntityID, Action, PerformedBy, Timestamp, Details)
        VALUES ('Loan', @LoanID, 'ApproveLoan', @ApprovedBy, GETDATE(),
                CONCAT('Loan Approved: $', @PrincipalAmount));

        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRAN;
        THROW;
    END CATCH
END;
GO

CREATE PROCEDURE sp_RejectLoan
    @LoanID INT,
    @RejectedBy NVARCHAR(100),
    @RejectionReason NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRAN;

        UPDATE Loan 
        SET Status = 'Rejected'
        WHERE LoanID = @LoanID AND Status = 'Applied';

        IF @@ROWCOUNT = 0
            THROW 50004, 'Loan not found or not in Applied status.', 1;

        INSERT INTO AuditLog (EntityName, EntityID, Action, PerformedBy, Timestamp, Details)
        VALUES ('Loan', @LoanID, 'RejectLoan', @RejectedBy, GETDATE(),
                CONCAT('Loan Rejected: ', @RejectionReason));

        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRAN;
        THROW;
    END CATCH
END;
GO


CREATE PROCEDURE sp_DisburseLoan
    @LoanID INT,
    @DisbursedBy NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRAN;

        DECLARE @AccountID INT, @PrincipalAmount DECIMAL(18,2);

       
        SELECT @AccountID = AccountID, @PrincipalAmount = PrincipalAmount
        FROM Loan 
        WHERE LoanID = @LoanID AND Status = 'Approved';

        IF @@ROWCOUNT = 0
            THROW 50005, 'Loan not found or not in Approved status.', 1;

     
        UPDATE Account SET Balance = Balance + @PrincipalAmount WHERE AccountID = @AccountID;
        UPDATE Loan SET Status = 'Active' WHERE LoanID = @LoanID;


        INSERT INTO [Transaction] (ToAccountID, Amount, TransactionType, Status, InitiatedBy, Reference)
        VALUES (@AccountID, @PrincipalAmount, 'LoanDisbursement', 'Completed', @DisbursedBy, CONCAT('LOAN-', @LoanID));


        INSERT INTO AuditLog (EntityName, EntityID, Action, PerformedBy, Timestamp, Details)
        VALUES ('Loan', @LoanID, 'DisburseLoan', @DisbursedBy, GETDATE(),
                CONCAT('Loan Disbursed: $', @PrincipalAmount, ' to Account ', @AccountID));

        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRAN;
        THROW;
    END CATCH
END;
GO


CREATE PROCEDURE sp_ProcessLoanPayment
    @LoanID INT,
    @PaymentAmount DECIMAL(18,2),
    @PaymentMethod NVARCHAR(50),
    @ProcessedBy NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRAN;

        DECLARE @AccountID INT, @PrincipalAmount DECIMAL(18,2), @Status NVARCHAR(20);


        SELECT @AccountID = AccountID, @PrincipalAmount = PrincipalAmount, @Status = Status
        FROM Loan WHERE LoanID = @LoanID;

        IF @@ROWCOUNT = 0
            THROW 50006, 'Loan not found.', 1;

        IF @Status != 'Active'
            THROW 50007, 'Loan is not active.', 1;

        IF @PaymentMethod = 'AccountTransfer'
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM Account WHERE AccountID = @AccountID AND Balance >= @PaymentAmount)
                THROW 50008, 'Insufficient balance for loan payment.', 1;

            UPDATE Account SET Balance = Balance - @PaymentAmount WHERE AccountID = @AccountID;


            INSERT INTO [Transaction] (FromAccountID, Amount, TransactionType, Status, InitiatedBy, Reference)
            VALUES (@AccountID, @PaymentAmount, 'LoanPayment', 'Completed', @ProcessedBy, CONCAT('LOAN-PMT-', @LoanID));
        END


        INSERT INTO LoanPayment (LoanID, PaymentDate, Amount, PaymentMethod)
        VALUES (@LoanID, GETDATE(), @PaymentAmount, @PaymentMethod);


        DECLARE @TotalPaid DECIMAL(18,2);
        SELECT @TotalPaid = ISNULL(SUM(Amount), 0) FROM LoanPayment WHERE LoanID = @LoanID;

        IF @TotalPaid >= @PrincipalAmount
        BEGIN
            UPDATE Loan SET Status = 'Closed' WHERE LoanID = @LoanID;
        END

        -- Audit log
        INSERT INTO AuditLog (EntityName, EntityID, Action, PerformedBy, Timestamp, Details)
        VALUES ('Loan', @LoanID, 'ProcessLoanPayment', @ProcessedBy, GETDATE(),
                CONCAT('Payment: $', @PaymentAmount, ' via ', @PaymentMethod, ' | Total Paid: $', @TotalPaid));

        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRAN;
        THROW;
    END CATCH
END;
GO


CREATE PROCEDURE sp_CalculateLoanBalance
    @LoanID INT,
    @CurrentBalance DECIMAL(18,2) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @PrincipalAmount DECIMAL(18,2), @TotalPaid DECIMAL(18,2);
    
    SELECT @PrincipalAmount = PrincipalAmount 
    FROM Loan 
    WHERE LoanID = @LoanID;
    
    SELECT @TotalPaid = ISNULL(SUM(Amount), 0) 
    FROM LoanPayment 
    WHERE LoanID = @LoanID;
    
    SET @CurrentBalance = @PrincipalAmount - @TotalPaid;
END;
GO


CREATE PROCEDURE sp_GetLoanDetails
    @LoanID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        L.*,
        C.FullName AS CustomerName,
        A.AccountNumber
    FROM Loan L
    JOIN Customer C ON L.CustomerID = C.CustomerID
    JOIN Account A ON L.AccountID = A.AccountID
    WHERE L.LoanID = @LoanID;

    SELECT *
    FROM LoanPayment
    WHERE LoanID = @LoanID
    ORDER BY PaymentDate DESC;
    
    DECLARE @CurrentBalance DECIMAL(18,2);
    EXEC sp_CalculateLoanBalance @LoanID, @CurrentBalance OUTPUT;
    
    SELECT @CurrentBalance AS CurrentBalance;
END;
GO


CREATE PROCEDURE sp_GetCustomerLoans
    @CustomerID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        L.LoanID,
        L.PrincipalAmount,
        L.InterestRate,
        L.TermMonths,
        L.StartDate,
        L.EndDate,
        L.Status,
        A.AccountNumber,
        TotalPaid = ISNULL(SUM(LP.Amount), 0),
        RemainingBalance = L.PrincipalAmount - ISNULL(SUM(LP.Amount), 0)
    FROM Loan L
    JOIN Account A ON L.AccountID = A.AccountID
    LEFT JOIN LoanPayment LP ON L.LoanID = LP.LoanID
    WHERE L.CustomerID = @CustomerID
    GROUP BY L.LoanID, L.PrincipalAmount, L.InterestRate, L.TermMonths, 
             L.StartDate, L.EndDate, L.Status, A.AccountNumber
    ORDER BY L.StartDate DESC;
END;
GO


CREATE PROCEDURE sp_GetLoansByStatus
    @Status NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        L.LoanID,
        C.FullName AS CustomerName,
        L.PrincipalAmount,
        L.InterestRate,
        L.TermMonths,
        L.StartDate,
        A.AccountNumber
    FROM Loan L
    JOIN Customer C ON L.CustomerID = C.CustomerID
    JOIN Account A ON L.AccountID = A.AccountID
    WHERE L.Status = @Status
    ORDER BY L.StartDate DESC;
END;
GO


CREATE PROCEDURE sp_ProcessDueLoanPayments
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @ProcessingDate DATE = GETDATE();
    
    -- This would typically integrate with a payment scheduling system
    -- For now, it's a placeholder for batch processing logic
    PRINT 'Due loan payment processing completed for: ' + CAST(@ProcessingDate AS NVARCHAR(20));
    
    -- Audit log
    INSERT INTO AuditLog (EntityName, EntityID, Action, PerformedBy, Timestamp, Details)
    VALUES ('System', '0', 'ProcessDueLoanPayments', 'System', GETDATE(),
            'Batch payment processing completed');
END;
GO


CREATE PROCEDURE sp_UpdateOverdueLoans
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE L
    SET Status = 'Overdue'
    FROM Loan L
    WHERE L.Status = 'Active'
      AND L.EndDate < GETDATE()
      AND NOT EXISTS (
          SELECT 1 FROM LoanPayment LP 
          WHERE LP.LoanID = L.LoanID 
          AND LP.PaymentDate >= DATEADD(DAY, -30, GETDATE())
      );
    
    PRINT 'Overdue loans updated: ' + CAST(@@ROWCOUNT AS NVARCHAR(10));
END;
GO


CREATE PROCEDURE sp_GetLoanPortfolioSummary
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        Status,
        COUNT(*) AS LoanCount,
        SUM(PrincipalAmount) AS TotalPrincipal,
        AVG(InterestRate) AS AvgInterestRate
    FROM Loan
    GROUP BY Status;
    
    SELECT 
        SUM(L.PrincipalAmount - ISNULL(LP.TotalPaid, 0)) AS TotalOutstandingBalance
    FROM Loan L
    LEFT JOIN (
        SELECT LoanID, SUM(Amount) AS TotalPaid
        FROM LoanPayment
        GROUP BY LoanID
    ) LP ON L.LoanID = LP.LoanID
    WHERE L.Status IN ('Active', 'Approved');
END;
GO


CREATE PROCEDURE sp_GetLoanPaymentReport
    @StartDate DATE = NULL,
    @EndDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    IF @StartDate IS NULL SET @StartDate = DATEADD(MONTH, -1, GETDATE());
    IF @EndDate IS NULL SET @EndDate = GETDATE();
    
    SELECT 
        LP.LoanPaymentID,
        LP.LoanID,
        C.FullName AS CustomerName,
        LP.PaymentDate,
        LP.Amount,
        LP.PaymentMethod,
        L.PrincipalAmount
    FROM LoanPayment LP
    JOIN Loan L ON LP.LoanID = L.LoanID
    JOIN Customer C ON L.CustomerID = C.CustomerID
    WHERE LP.PaymentDate BETWEEN @StartDate AND @EndDate
    ORDER BY LP.PaymentDate DESC;
END;
GO


CREATE PROCEDURE sp_CalculateMonthlyPayment
    @PrincipalAmount DECIMAL(18,2),
    @InterestRate DECIMAL(5,2),
    @TermMonths INT,
    @MonthlyPayment DECIMAL(18,2) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @MonthlyRate DECIMAL(10,6) = @InterestRate / 100 / 12;
    
    IF @MonthlyRate = 0
        SET @MonthlyPayment = @PrincipalAmount / @TermMonths;
    ELSE
        SET @MonthlyPayment = @PrincipalAmount * @MonthlyRate * POWER(1 + @MonthlyRate, @TermMonths) 
                            / (POWER(1 + @MonthlyRate, @TermMonths) - 1);
END;
GO


CREATE PROCEDURE sp_ClosePaidOffLoans
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE L
    SET Status = 'Closed'
    FROM Loan L
    WHERE L.Status = 'Active'
      AND L.PrincipalAmount <= (
          SELECT ISNULL(SUM(Amount), 0) 
          FROM LoanPayment 
          WHERE LoanID = L.LoanID
      );
    
    PRINT 'Closed paid-off loans: ' + CAST(@@ROWCOUNT AS NVARCHAR(10));
END;
GO

PRINT '>>> Loan Management complete';

USE IBMS_Phase2;
GO


CREATE PROCEDURE sp_LogAudit
    @EntityName NVARCHAR(100),
    @EntityID NVARCHAR(100),
    @Action NVARCHAR(50),
    @PerformedBy NVARCHAR(100),
    @Details NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO AuditLog (EntityName, EntityID, Action, PerformedBy, Timestamp, Details)
    VALUES (@EntityName, @EntityID, @Action, @PerformedBy, GETDATE(), @Details);
END;
GO

CREATE PROCEDURE sp_LogCustomerAction
    @CustomerID INT,
    @Action NVARCHAR(50),
    @PerformedBy NVARCHAR(100),
    @Details NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    EXEC sp_LogAudit 'Customer', @CustomerID, @Action, @PerformedBy, @Details;
END;
GO

CREATE PROCEDURE sp_LogAccountAction
    @AccountID INT,
    @Action NVARCHAR(50),
    @PerformedBy NVARCHAR(100),
    @Details NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    EXEC sp_LogAudit 'Account', @AccountID, @Action, @PerformedBy, @Details;
END;
GO

CREATE PROCEDURE sp_LogTransactionAction
    @TransactionID BIGINT,
    @Action NVARCHAR(50),
    @PerformedBy NVARCHAR(100),
    @Details NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    EXEC sp_LogAudit 'Transaction', @TransactionID, @Action, @PerformedBy, @Details;
END;
GO

CREATE PROCEDURE sp_LogLoanAction
    @LoanID INT,
    @Action NVARCHAR(50),
    @PerformedBy NVARCHAR(100),
    @Details NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    EXEC sp_LogAudit 'Loan', @LoanID, @Action, @PerformedBy, @Details;
END;
GO