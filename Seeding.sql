USE IBMS_Phase2; -- Ensure we are in the right DB
GO
SET NOCOUNT ON; -- Prevents console clutter

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

    -- B. Get the ID of the loan we just made
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
    
    -- Optional: Print progress every 100k rows
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