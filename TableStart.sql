/* -----------------------------------------------------------
   PHASE 2: DATABASE CREATION SCRIPT
   Group: [Insert Group Number]
   Project: Integrated Banking Management System (IBMS)
   -----------------------------------------------------------
*/

-- Use the correct database (Uncomment if you created a specific DB)
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

-- 1. CLEANUP: Drop tables in reverse dependency order to avoid FK errors
DROP TABLE IF EXISTS AuditLog;
DROP TABLE IF EXISTS ScheduledJob;
DROP TABLE IF EXISTS LoanPayment;
DROP TABLE IF EXISTS Loan;
DROP TABLE IF EXISTS CardTransaction;
DROP TABLE IF EXISTS Card;
DROP TABLE IF EXISTS [Transaction]; -- Transaction is a reserved keyword, use brackets
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