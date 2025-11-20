/* -----------------------------------------------------------
   PHASE 2: COMPLETE DATABASE SCRIPT (SCHEMA + DATA)
   Project: Integrated Banking Management System (IBMS)
   Group: 39
   -----------------------------------------------------------
*/

-- UNCOMMENT THE SECTION BELOW IF YOU NEED TO CREATE THE DB FRESH
/*
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
*/

-- ===================================================================================
-- SECTION 1: CLEANUP (DROP TABLES)
-- Drops tables in reverse dependency order to prevent Foreign Key errors
-- ===================================================================================
PRINT 'Cleaning up old objects...';
DROP TABLE IF EXISTS AuditLog;
DROP TABLE IF EXISTS ScheduledJob;
DROP TABLE IF EXISTS LoanPayment;
DROP TABLE IF EXISTS Loan;
DROP TABLE IF EXISTS CardTransaction;
DROP TABLE IF EXISTS Card;
DROP TABLE IF EXISTS [Transaction];
DROP TABLE IF EXISTS Account;
DROP TABLE IF EXISTS AccountType;
DROP TABLE IF EXISTS Beneficiary;
DROP TABLE IF EXISTS Customer;
ALTER TABLE Branch DROP CONSTRAINT IF EXISTS FK_Branch_Manager; -- Break circular link
DROP TABLE IF EXISTS Employee;
DROP TABLE IF EXISTS Branch;
GO

-- ===================================================================================
-- SECTION 2: TABLE CREATION (DDL)
-- Creates tables based on the entities in Group 39 Project Proposal
-- ===================================================================================
PRINT 'Creating Database Schema...';

-- 1. BRANCH (Physical Locations)
CREATE TABLE Branch (
    BranchID INT PRIMARY KEY IDENTITY(1,1),
    Name NVARCHAR(100) NOT NULL,
    Location NVARCHAR(255) NOT NULL,
    ManagerEmployeeID INT NULL -- Nullable initially to allow Employee creation first
);

-- 2. EMPLOYEE (Staff)
CREATE TABLE Employee (
    EmployeeID INT PRIMARY KEY IDENTITY(1,1),
    FullName NVARCHAR(100) NOT NULL,
    Role NVARCHAR(50) NOT NULL, -- 'Manager', 'Teller', 'Admin'
    BranchID INT NOT NULL,
    CONSTRAINT FK_Employee_Branch FOREIGN KEY (BranchID) REFERENCES Branch(BranchID)
);

-- Add the Foreign Key for Branch Manager now that Employee exists
ALTER TABLE Branch
ADD CONSTRAINT FK_Branch_Manager FOREIGN KEY (ManagerEmployeeID) REFERENCES Employee(EmployeeID);

-- 3. CUSTOMER (Core Identity)
CREATE TABLE Customer (
    CustomerID INT PRIMARY KEY IDENTITY(1,1),
    FullName NVARCHAR(100) NOT NULL,
    DOB DATE NOT NULL,
    Email NVARCHAR(100) NOT NULL UNIQUE,
    Phone NVARCHAR(20) NOT NULL,
    Address NVARCHAR(255) NOT NULL,
    KYCStatus NVARCHAR(20) NOT NULL DEFAULT 'Pending', -- 'Pending', 'Verified', 'Rejected'
    KYCDocumentRef NVARCHAR(100) NULL,
    CreatedAt DATETIME2 DEFAULT GETDATE()
);

-- 4. BENEFICIARY (Saved Payees)
CREATE TABLE Beneficiary (
    BeneficiaryID INT PRIMARY KEY IDENTITY(1,1),
    CustomerID INT NOT NULL,
    BeneficiaryAccountNumber NVARCHAR(20) NOT NULL,
    BankName NVARCHAR(100) NOT NULL,
    Nickname NVARCHAR(50),
    CONSTRAINT FK_Beneficiary_Customer FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID)
);

-- 5. ACCOUNT TYPE (Lookup Table)
CREATE TABLE AccountType (
    AccountTypeID INT PRIMARY KEY IDENTITY(1,1),
    Name NVARCHAR(50) NOT NULL UNIQUE, -- 'Savings', 'Checking', 'Business'
    InterestRate DECIMAL(5, 2) NOT NULL DEFAULT 0.00,
    MinBalance DECIMAL(18, 2) NOT NULL DEFAULT 0.00
);

-- 6. ACCOUNT (Financial Container)
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

-- 7. TRANSACTION (The Ledger - Scalability Target)
CREATE TABLE [Transaction] (
    TransactionID BIGINT PRIMARY KEY IDENTITY(1,1), -- BIGINT for >1 Million rows
    FromAccountID INT NULL, -- Null for Cash Deposits
    ToAccountID INT NULL,   -- Null for Cash Withdrawals
    Amount DECIMAL(18, 2) NOT NULL,
    TransactionType NVARCHAR(20) NOT NULL, -- 'Transfer', 'Deposit', 'Withdrawal', 'Fee', 'Interest'
    Status NVARCHAR(20) NOT NULL DEFAULT 'Completed',
    InitiatedBy NVARCHAR(100) NOT NULL, -- 'Customer-1', 'Employee-5', 'System'
    Timestamp DATETIME2 NOT NULL DEFAULT GETDATE(),
    Reference NVARCHAR(100) NULL,
    CONSTRAINT FK_Trans_From FOREIGN KEY (FromAccountID) REFERENCES Account(AccountID),
    CONSTRAINT FK_Trans_To FOREIGN KEY (ToAccountID) REFERENCES Account(AccountID)
);

-- 8. CARD (Debit/Credit)
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

-- 9. CARD TRANSACTION (POS usage)
CREATE TABLE CardTransaction (
    CardTxID BIGINT PRIMARY KEY IDENTITY(1,1),
    CardID INT NOT NULL,
    Amount DECIMAL(18, 2) NOT NULL,
    Merchant NVARCHAR(100) NOT NULL,
    Timestamp DATETIME2 NOT NULL DEFAULT GETDATE(),
    AuthorizationCode NVARCHAR(50) NOT NULL,
    CONSTRAINT FK_CardTx_Card FOREIGN KEY (CardID) REFERENCES Card(CardID)
);

-- 10. LOAN (Lending Portfolio)
CREATE TABLE Loan (
    LoanID INT PRIMARY KEY IDENTITY(1,1),
    CustomerID INT NOT NULL,
    AccountID INT NOT NULL, -- Account where funds are disbursed
    PrincipalAmount DECIMAL(18, 2) NOT NULL,
    InterestRate DECIMAL(5, 2) NOT NULL,
    TermMonths INT NOT NULL,
    StartDate DATE NOT NULL,
    EndDate DATE NULL,
    Status NVARCHAR(20) NOT NULL DEFAULT 'Applied', -- 'Approved', 'Active', 'Closed'
    CONSTRAINT FK_Loan_Customer FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID),
    CONSTRAINT FK_Loan_Account FOREIGN KEY (AccountID) REFERENCES Account(AccountID)
);

-- 11. LOAN PAYMENT (Repayment tracking)
CREATE TABLE LoanPayment (
    LoanPaymentID INT PRIMARY KEY IDENTITY(1,1),
    LoanID INT NOT NULL,
    PaymentDate DATETIME2 NOT NULL DEFAULT GETDATE(),
    Amount DECIMAL(18, 2) NOT NULL,
    PaymentMethod NVARCHAR(50) NOT NULL, -- 'AccountTransfer', 'Cash'
    CONSTRAINT FK_LoanPayment_Loan FOREIGN KEY (LoanID) REFERENCES Loan(LoanID)
);

-- 12. SCHEDULED JOB (Automation Config)
CREATE TABLE ScheduledJob (
    JobID INT PRIMARY KEY IDENTITY(1,1),
    JobName NVARCHAR(100) NOT NULL UNIQUE,
    StoredProcedureName NVARCHAR(100) NOT NULL,
    Frequency NVARCHAR(20) NOT NULL, -- 'Daily', 'Monthly'
    IsEnabled BIT NOT NULL DEFAULT 1,
    LastRun DATETIME2 NULL,
    NextRun DATETIME2 NULL
);

-- 13. AUDIT LOG (Compliance)
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
