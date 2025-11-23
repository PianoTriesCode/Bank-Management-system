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