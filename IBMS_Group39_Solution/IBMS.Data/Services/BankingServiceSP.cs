using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using IBMS.Core.Interfaces;
using IBMS.Core.Models;

namespace IBMS.Data.Services
{
    public class BankingServiceSP : IBankingService
    {
        private readonly BankingContext _context;
        private readonly ICustomerRepository _customerRepo;

        private readonly ILoanRepository _loanRepo;

        public BankingServiceSP(
            BankingContext context,
            ICustomerRepository customerRepo,
            ILoanRepository loanRepo
            )
        {
            _context = context;
            _customerRepo = customerRepo;
            _loanRepo = loanRepo;
        }

        public Employee Login(int employeeId)
        {
            // Calls the Stored Procedure 'sp_EmployeeLogin'
            var param = new SqlParameter("@EmployeeID", employeeId);

            // Using FromSqlRaw to map the result to the Employee entity
            // Note: The SP must return columns matching the Employee table
            return _context.Employees
                .FromSqlRaw("EXEC sp_EmployeeLogin @EmployeeID", param)
                .AsEnumerable()
                .FirstOrDefault();
        }

        // Gets the data for a specific customer
        public Customer GetCustomer(int customerId)
        {
            // Calls 'sp_GetCustomerByID'
            var param = new SqlParameter("@CustomerID", customerId);
            
            var customer = _context.Customers
                .FromSqlRaw("EXEC sp_GetCustomerByID @CustomerID", param)
                .AsEnumerable()
                .FirstOrDefault();

            return customer;
        }
        public List<Transaction> GetArchivedTransactions()
        {
            // This reads specifically from the 'Transaction_Partitioned' table
            // SQL Server handles fetching from the correct year-based filegroup
            return _context.Transactions
                .FromSqlRaw("EXEC sp_GetArchivedTransactions")
                .AsNoTracking() // Recommended for read-only lists to improve performance
                .ToList();
        }
        public List<TransactionStatementViewModel> GetAccountStatement(int accountId)
        {
            var result = new List<TransactionStatementViewModel>();
            var conn = _context.Database.GetDbConnection();

            try
            {
                if (conn.State != ConnectionState.Open) conn.Open();
                using (var cmd = conn.CreateCommand())
                {
                    // Call the CTE Stored Procedure
                    cmd.CommandText = "EXEC sp_GetAccountStatementWithRunningBalance @AccountID";
                    var p = cmd.CreateParameter();
                    p.ParameterName = "@AccountID";
                    p.Value = accountId;
                    cmd.Parameters.Add(p);

                    using (var reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            result.Add(new TransactionStatementViewModel
                            {
                                TransactionID = reader.GetInt64(reader.GetOrdinal("TransactionID")),
                                Timestamp = reader.GetDateTime(reader.GetOrdinal("Timestamp")),
                                TransactionType = reader.GetString(reader.GetOrdinal("TransactionType")),
                                Amount = reader.GetDecimal(reader.GetOrdinal("Amount")),
                                Reference = reader.IsDBNull(reader.GetOrdinal("Reference")) ? "" : reader.GetString(reader.GetOrdinal("Reference")),
                                
                                // Capturing the CTE calculation
                                RunningBalance = reader.GetDecimal(reader.GetOrdinal("RunningBalance"))
                            });
                        }
                    }
                }
            }
            finally
            {
                if (conn.State == ConnectionState.Open) conn.Close();
            }

            return result;
        }

        // Uses the 360 view defined in our SQL file as the basis for results that are displayed.
        public List<Customer360ViewModel> GetAllCustomer360()
            => _customerRepo.GetAllCustomer360();

        // Calls the stored procedure to create a customer
        public int CreateCustomer(Customer c)
            => _customerRepo.CreateCustomer(c);

        // Calls the stored procedure to update a customer
        public void UpdateCustomer(Customer c)
            => _customerRepo.UpdateCustomer(c);

        // Calls the stored procedure to delete a customer
        public void DeleteCustomer(int id)
            => _customerRepo.DeleteCustomer(id);

        // 
        public List<CustomerViewModel> GetAllCustomers()
        {
            var result = new List<CustomerViewModel>();
            var conn = _context.Database.GetDbConnection();
            
            try
            {
                if (conn.State != ConnectionState.Open) conn.Open();
                using (var cmd = conn.CreateCommand())
                {
                    cmd.CommandText = "SELECT CustomerID, FullName, Email, TotalBalance FROM view_Customer360";
                    using (var reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            result.Add(new CustomerViewModel
                            {
                                CustomerID = reader.GetInt32(0),
                                FullName = reader.GetString(1),
                                Email = reader.GetString(2),
                                TotalBalance = reader.GetDecimal(3)
                            });
                        }
                    }
                }
            }
            finally
            {
                if (conn.State == ConnectionState.Open) conn.Close();
            }

            return result;
        }

        public List<Account> GetAccountsForCustomer(int customerId)
        {
            var param = new SqlParameter("@CustomerID", customerId);

            return _context.Accounts
                .FromSqlRaw(@"
                    SELECT 
                        AccountID,
                        AccountNumber,
                        CustomerID,
                        AccountTypeID,
                        BranchID,
                        Balance,
                        Status,
                        CreatedDate
                    FROM Account
                    WHERE CustomerID = @CustomerID
                ", param)
                .AsNoTracking()
                .ToList();
        }

        public decimal GetTotalAssets(int customerId)
        {
            // Calls the Scalar Function 'fn_GetTotalCustomerAssets'
            var conn = _context.Database.GetDbConnection();
            try
            {
                if (conn.State != ConnectionState.Open) conn.Open();
                using (var cmd = conn.CreateCommand())
                {
                    cmd.CommandText = "SELECT dbo.fn_GetTotalCustomerAssets(@CustomerID)";
                    var p = cmd.CreateParameter();
                    p.ParameterName = "@CustomerID";
                    p.Value = customerId;
                    cmd.Parameters.Add(p);

                    var result = cmd.ExecuteScalar();
                    return result == DBNull.Value ? 0m : (decimal)result;
                }
            }
            finally
            {
                if (conn.State == ConnectionState.Open) conn.Close();
            }
        }

        public bool TransferFunds(int fromAccId, int toAccId, decimal amount, string initiatedBy)
        {
            // Calls the Atomic Stored Procedure 'sp_TransferFunds'
            var pFrom = new SqlParameter("@FromAccountID", fromAccId);
            var pTo = new SqlParameter("@ToAccountID", toAccId);
            var pAmt = new SqlParameter("@Amount", amount);
            var pInit = new SqlParameter("@InitiatedBy", initiatedBy ?? (object)DBNull.Value);
            var pRef = new SqlParameter("@Reference", "SP Transfer via App");
            
            var pNewTxID = new SqlParameter("@NewTransactionID", SqlDbType.BigInt);
            pNewTxID.Direction = ParameterDirection.Output;

            try 
            {
                _context.Database.ExecuteSqlRaw(
                    "EXEC sp_TransferFunds @FromAccountID, @ToAccountID, @Amount, @InitiatedBy, @Reference, @NewTransactionID OUT",
                    pFrom, pTo, pAmt, pInit, pRef, pNewTxID);
                
                // If the output parameter is set, the transaction succeeded
                return pNewTxID.Value != DBNull.Value;
            }
            catch(Exception)
            {
                // SP will raise an error if funds are insufficient or accounts are invalid
                return false;
            }
        }

        public List<CustomerAccountSummary> GetCustomerAccountSummary(int customerId)
        {
            return _customerRepo.GetCustomerAccountSummary(customerId);
        }


        public List<AuditLog> GetAuditLogs()
        {
            var logs = new List<AuditLog>();
            var conn = _context.Database.GetDbConnection();

            try
            {
                if (conn.State != ConnectionState.Open)
                    conn.Open();

                using (var cmd = conn.CreateCommand())
                {
                    cmd.CommandText = "GetAllAuditLogs";
                    cmd.CommandType = CommandType.StoredProcedure;

                    using (var reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            logs.Add(new AuditLog
                            {
                                AuditID = reader.GetInt64(0),
                                EntityName = reader.GetString(1),
                                EntityID = reader.GetString(2),
                                Action = reader.GetString(3),
                                PerformedBy = reader.GetString(4),
                                Timestamp = reader.GetDateTime(5),
                                Details = reader.IsDBNull(6) ? null : reader.GetString(6)
                            });
                        }
                    }
                }
            }
            finally
            {
                if (conn.State == ConnectionState.Open)
                    conn.Close();
            }

            return logs;
        }

        public List<Customer360ViewModel> SearchCustomersByName(string fullName)
        {
            var param = new SqlParameter("@FullName", fullName ?? "");

            return _context.Customer360ViewModels
                .FromSqlRaw("EXEC dbo.sp_SearchCustomersByName @FullName", param)
                .ToList();
        }

        public int SaveLoanApplication(Loan loan)
        {
            return _loanRepo.SaveLoanApplication(loan);
        }

        public List<int> GetCustomerAccountIds(int customerId)
        {
            return _customerRepo.GetCustomerAccountIds(customerId);
        }

        public List<Loan> GetAllLoans()
        {
            return _loanRepo.GetAllLoans();
        }

        public int UpdateLoanApplication(int loanId, LoanStatus loanStatus)
        { 
            var loan = _context.Loans.FirstOrDefault(l => l.LoanID == loanId);
            if (loan == null) return 0;
            loan.StatusEnum = loanStatus;
            return _loanRepo.UpdateLoanById(loan);
        }
    }
}