/* -----------------------------------------------------------
   PHASE 3: SQL FEATURE ADD-ONS
   Project: Integrated Banking Management System (IBMS)
   Group: 39
   
   Objective: Implement missing mandatory SQL features for Phase 3
   (Scalar Functions, CTEs, Partition Data) to support the App.
   -----------------------------------------------------------
*/

USE IBMS_Phase2;
GO

-- ===================================================================================
-- FEATURE 1: SCALAR USER-DEFINED FUNCTION (UDF)
-- Requirement: User-Defined Functions
-- Purpose: Calculates total assets for a customer. Used in the C# Dashboard.
-- ===================================================================================
CREATE OR ALTER FUNCTION dbo.fn_GetTotalCustomerAssets
(
    @CustomerID INT
)
RETURNS DECIMAL(18,2)
AS
BEGIN
    DECLARE @Total DECIMAL(18,2);

    SELECT @Total = SUM(Balance)
    FROM Account
    WHERE CustomerID = @CustomerID AND Status = 'Active';

    RETURN ISNULL(@Total, 0.00);
END;
GO

-- Usage Test:
-- SELECT dbo.fn_GetTotalCustomerAssets(1);

-- ===================================================================================
-- FEATURE 2: COMMON TABLE EXPRESSION (CTE)
-- Requirement: Common Table Expressions (CTEs)
-- Purpose: Generates a hierarchical report or running balance. 
--          This SP will be used by the "Account Statement" feature in the App.
-- ===================================================================================
CREATE OR ALTER PROCEDURE dbo.sp_GetAccountStatementWithRunningBalance
    @AccountID INT
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH TransactionData AS (
        SELECT 
            TransactionID,
            Timestamp,
            TransactionType,
            Amount,
            -- Determine if it's credit or debit logic
            CASE 
                WHEN ToAccountID = @AccountID THEN Amount  -- Money coming in (Credit)
                WHEN FromAccountID = @AccountID THEN -Amount -- Money going out (Debit)
                ELSE 0 
            END AS NetChange,
            Reference
        FROM [Transaction]
        WHERE FromAccountID = @AccountID OR ToAccountID = @AccountID
    )
    SELECT 
        TransactionID,
        Timestamp,
        TransactionType,
        NetChange AS Amount,
        Reference,
        -- Window function to calculate running total over time
        SUM(NetChange) OVER (ORDER BY Timestamp ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as RunningBalance
    FROM TransactionData
    ORDER BY Timestamp DESC;
END;
GO

-- Usage Test:
-- EXEC sp_GetAccountStatementWithRunningBalance @AccountID = 1;

-- ===================================================================================
-- FEATURE 3: POPULATE PARTITIONED TABLE
-- Requirement: Table Partitioning
-- Purpose: Your previous script created 'Transaction_Partitioned' but left it empty.
--          This copies data so you can demonstrate the partitioning feature.
-- ===================================================================================
PRINT 'Populating Partitioned Table for Demonstration...';

INSERT INTO Transaction_Partitioned (
    FromAccountID, ToAccountID, Amount, TransactionType, 
    Status, InitiatedBy, Timestamp, Reference
)
SELECT 
    FromAccountID, ToAccountID, Amount, TransactionType, 
    Status, InitiatedBy, Timestamp, Reference
FROM [Transaction];

PRINT 'Partitioned Table Populated.';

-- Usage Test (Verify data distribution across partitions):
/*
SELECT 
    $PARTITION.PF_TransactionByYear(Timestamp) AS PartitionNumber, 
    COUNT(*) AS RowCount
FROM Transaction_Partitioned
GROUP BY $PARTITION.PF_TransactionByYear(Timestamp)
ORDER BY PartitionNumber;
*/
GO

-- ===================================================================================
-- FEATURE 4: LOGIN & AUTHENTICATION SP
-- Purpose: Needed for the "Login Form" in your C# Application.
-- ===================================================================================
CREATE OR ALTER PROCEDURE dbo.sp_EmployeeLogin
    @EmployeeID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT E.EmployeeID, E.FullName, E.Role, B.BranchID, B.Name AS BranchName
    FROM Employee E
    JOIN Branch B ON E.BranchID = B.BranchID
    WHERE E.EmployeeID = @EmployeeID;
END;
GO