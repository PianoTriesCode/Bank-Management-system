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
        // private readonly IAccountRepository _accountRepo;
        // private readonly ITransactionRepository _transactionRepo;


        public BankingServiceSP(
            BankingContext context,
            ICustomerRepository customerRepo
            // IAccountRepository accountRepo,
            // ITransactionRepository transactionRepo
            )
        {
            _context = context;
            _customerRepo = customerRepo;
            // _accountRepo = accountRepo;
            // _transactionRepo = transactionRepo;
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

        // public int CreateCustomer(Customer customer)
        // {
        //     // Calls 'sp_CreateCustomer' with an Output parameter
        //     var pFullName = new SqlParameter("@FullName", customer.FullName);
        //     var pDOB = new SqlParameter("@DOB", customer.DOB);
        //     var pEmail = new SqlParameter("@Email", customer.Email);
        //     var pPhone = new SqlParameter("@Phone", customer.Phone);
        //     var pAddress = new SqlParameter("@Address", customer.Address);
            
        //     var pNewID = new SqlParameter("@NewCustomerID", SqlDbType.Int);
        //     pNewID.Direction = ParameterDirection.Output;

        //     _context.Database.ExecuteSqlRaw(
        //         "EXEC sp_CreateCustomer @FullName, @DOB, @Email, @Phone, @Address, @NewCustomerID OUT",
        //         pFullName, pDOB, pEmail, pPhone, pAddress, pNewID);

        //     return (int)pNewID.Value;
        // }

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

        public List<Customer360ViewModel> GetAllCustomer360()
            => _customerRepo.GetAllCustomer360();

        public int CreateCustomer(Customer c)
            => _customerRepo.CreateCustomer(c);

        public void UpdateCustomer(Customer c)
            => _customerRepo.UpdateCustomer(c);

        public void DeleteCustomer(int id)
            => _customerRepo.DeleteCustomer(id);

        public List<CustomerViewModel> GetAllCustomers()
        {
            // Calls the View 'view_Customer360'
            // Since this View doesn't match a DB Table exactly, we use raw ADO.NET
            // to map it to our ViewModel manually.
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
            // EF Core doesn't map Scalar Functions easily in LINQ, so we use ADO.NET
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

        public List<Transaction> GetAccountStatement(int accountId)
        {
            // Calls the CTE-based SP 'sp_GetAccountStatementWithRunningBalance'
            var param = new SqlParameter("@AccountID", accountId);

            // Note: The SP returns extra columns (RunningBalance) that aren't in the Model.
            // EF Core will simply ignore columns that don't match properties in the 'Transaction' class.
            return _context.Transactions
                .FromSqlRaw("EXEC sp_GetAccountStatementWithRunningBalance @AccountID", param)
                .ToList();
        }
    }
}