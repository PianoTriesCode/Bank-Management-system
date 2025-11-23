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
SELECT *
FROM dbo.view_CustomerEditable
WHERE Email = 'sohaf@email.com';

SELECT TOP (10) * FROM AuditLog;

INSERT INTO dbo.view_CustomerEditable (FullName, Email, Phone)
VALUES ('Sohaf', 'sohaf@email.com', '67420');

SELECT *
FROM dbo.view_CustomerEditable
WHERE Email = 'sohaf@email.com';

SELECT *
FROM Customer
WHERE Email = 'sohaf@email.com';

SELECT TOP (10) * FROM AuditLog;

UPDATE dbo.view_CustomerEditable
SET Phone = '6767-42',
    Address = '467-Gulbahar'
WHERE Email = 'sohaf@email.com';

SELECT *
FROM Customer
WHERE Email = 'sohaf@email.com';

SELECT TOP 10 * FROM AuditLog ORDER BY Timestamp DESC;

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
DECLARE @NewCustomerID INT;

EXEC dbo.sp_CreateCustomer
    @FullName = 'Shaheer Hammad',
    @DOB = '1980-06-07',
    @Email = 'shamala@example.com',
    @Phone = '123-456-789',
    @Address = '123 Baker Road',
    @NewCustomerID = @NewCustomerID OUTPUT;

SELECT @NewCustomerID AS NewCustomerID;

SELECT *
FROM Customer
WHERE Email = 'shamala@example.com';

SELECT TOP 10 * FROM AuditLog ORDER BY Timestamp DESC;


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
EXEC dbo.sp_GetCustomerByID @CustomerID = 10002;

-- =========== UPDATE Customer using Stored Procedure ===========
IF OBJECT_ID('dbo.sp_UpdateCustomer', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_UpdateCustomer;
GO
CREATE PROCEDURE dbo.sp_UpdateCustomer
    @CustomerID INT,
    @FullName NVARCHAR(100) = NULL,
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
EXEC dbo.sp_UpdateCustomer
    @CustomerID = 10003,
    @Phone = '555-999-888',
    @Address = '22 Buldak Noodles';

SELECT *
FROM Customer
WHERE Email = 'shamala@example.com';

SELECT TOP 10 * FROM AuditLog ORDER BY Timestamp DESC;

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
EXEC dbo.sp_DeleteCustomer
    @CustomerID = 10002;

SELECT *
FROM Customer
WHERE Email = 'shamala@example.com';

SELECT TOP 10 * FROM AuditLog ORDER BY Timestamp DESC;


-- --------------------------------------------------------------------
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
SELECT * FROM dbo.view_ActiveAccountsByBranch ORDER BY BranchID, AccountID;

DECLARE @TxID BIGINT;

EXEC dbo.sp_TransferFunds
    @FromAccountID = 20,
    @ToAccountID = 32,
    @Amount = 924.00,
    @InitiatedBy = 'admin_user',
    @Reference = 'Test transfer',
    @NewTransactionID = @TxID OUTPUT;

SELECT @TxID AS NewTransactionID;

SELECT TOP 10 * FROM AuditLog ORDER BY Timestamp DESC;

SELECT * FROM dbo.view_ActiveAccountsByBranch ORDER BY BranchID, AccountID;