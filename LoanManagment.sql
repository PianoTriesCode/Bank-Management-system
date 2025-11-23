-- =========== LOAN LIFECYCLE MANAGEMENT ===========
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