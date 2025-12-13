using System;
using System.Collections.Generic;
using System.Linq;
using Microsoft.EntityFrameworkCore;
using IBMS.Core.Interfaces;
using IBMS.Core.Models;

namespace IBMS.Data.Services
{
    public class BankingServiceLINQ : IBankingService
    {
        private readonly BankingContext _context;

        public BankingServiceLINQ(BankingContext context)
        {
            _context = context;
        }

        public Employee Login(int employeeId)
        {
            // LINQ: Simple lookup
            return _context.Employees
                .Include(e => e.Branch) // Eager load Branch info
                .FirstOrDefault(e => e.EmployeeID == employeeId);
        }

        public int CreateCustomer(Customer customer)
        {
            // LINQ: Add object to DbSet and Save
            customer.CreatedAt = DateTime.Now;
            _context.Customers.Add(customer);
            _context.SaveChanges();
            return customer.CustomerID;
        }

        public Customer GetCustomer(int customerId)
        {
            // LINQ: Find by Primary Key
            return _context.Customers.Find(customerId);
        }

        public List<Customer360ViewModel> GetAllCustomer360()
        {
            return _context.Customers
                .Select(c => new Customer360ViewModel
                {
                    CustomerID = c.CustomerID,
                    FullName = c.FullName,
                    Email = c.Email,
                    Phone = c.Phone,
                    Address = c.Address,
                    TotalAccounts = _context.Accounts.Count(a => a.CustomerID == c.CustomerID),
                    TotalBalance = _context.Accounts
                        .Where(a => a.CustomerID == c.CustomerID)
                        .Sum(a => (decimal?)a.Balance) ?? 0
                })
                .ToList();
        }

        public void UpdateCustomer(Customer c)
        {
            // throw new NotImplementedException("LINQ mode does not support UpdateCustomer yet.");
            _context.Customers.Attach(c);
            _context.Entry(c).State = EntityState.Modified;
            
            var audit = new AuditLog
            {
                EntityName = "Customer",
                EntityID = c.CustomerID.ToString(),
                Action = "UpdateCustomer",
                PerformedBy = "sa",
                Timestamp = DateTime.Now,
                Details = "Customer updated via LINQ"
            };
            _context.AuditLog.Add(audit);

            _context.SaveChanges();
        }
        public List<TransactionStatementViewModel> GetAccountStatement(int accountId)
        {
            var rawTransactions = _context.Transactions
            .Where(t => t.FromAccountID == accountId || t.ToAccountID == accountId)
            .OrderBy(t => t.Timestamp) // Ascending is required for the math loop
            .Select(t => new 
            {
                t.TransactionID,
                t.Timestamp,
                t.TransactionType,
                t.Amount,
                t.Reference,
                // Pre-calculate "Net Change" logic in the database query
                NetChange = (t.ToAccountID == accountId) ? t.Amount : -t.Amount
            })
            .ToList(); // <--- Data is pulled into memory here

        // 2. CALCULATE: Compute Running Balance using a C# loop
        var result = new List<TransactionStatementViewModel>();
        decimal runningBalance = 0;

        foreach (var t in rawTransactions)
        {
            runningBalance += t.NetChange;

            result.Add(new TransactionStatementViewModel
            {
                TransactionID = t.TransactionID,
                Timestamp = t.Timestamp,
                TransactionType = t.TransactionType,
                Amount = t.NetChange, // Shows + for Credit, - for Debit
                Reference = t.Reference ?? "",
                RunningBalance = runningBalance // Calculated in memory
            });
    }

        // 3. SORT: Reverse to show "Newest First" for the UI
        result.Reverse(); 

        return result;
        }

        public void DeleteCustomer(int id)
        {
            // throw new NotImplementedException("LINQ mode does not support DeleteCustomer yet.");
            var customer = _context.Customers.Find(id);
            if (customer == null)
                throw new Exception("Customer not found.");

            _context.Customers.Remove(customer);

            var audit = new AuditLog
            {
                EntityName = "Customer",
                EntityID = id.ToString(),
                Action = "DeleteCustomer",
                PerformedBy = "sa",
                Timestamp = DateTime.Now,
                Details = "Customer deleted via LINQ"
            };
            _context.AuditLog.Add(audit);

            _context.SaveChanges();
        }

        public List<CustomerViewModel> GetAllCustomers()
        {
            // LINQ: Projection (Select) to calculate totals in memory/query
            return _context.Customers
                .Select(c => new CustomerViewModel
                {
                    CustomerID = c.CustomerID,
                    FullName = c.FullName,
                    Email = c.Email,
                    // Sub-query to sum balances
                    TotalBalance = _context.Accounts
                        .Where(a => a.CustomerID == c.CustomerID)
                        .Sum(a => (decimal?)a.Balance) ?? 0
                })
                .ToList();
        }

        public List<Account> GetAccountsForCustomer(int customerId)
        {
            // LINQ: Filtering
            return _context.Accounts
                .Include(a => a.AccountType) // Join with AccountType
                .Where(a => a.CustomerID == customerId)
                .ToList();
        }

        public decimal GetTotalAssets(int customerId)
        {
            // LINQ: Aggregation
            return _context.Accounts
                .Where(a => a.CustomerID == customerId && a.Status == "Active")
                .Sum(a => (decimal?)a.Balance) ?? 0;
        }

        public bool TransferFunds(int fromAccId, int toAccId, decimal amount, string initiatedBy)
        {
            // LINQ: Transaction Logic
            using (var transaction = _context.Database.BeginTransaction())
            {
                try
                {
                    var fromAcc = _context.Accounts.Find(fromAccId);
                    var toAcc = _context.Accounts.Find(toAccId);

                    // Validations
                    if (fromAcc == null || toAcc == null) throw new Exception("Invalid Account ID");
                    if (fromAcc.Balance < amount) throw new Exception("Insufficient Funds");
                    if (fromAcc.Status != "Active" || toAcc.Status != "Active") throw new Exception("Account not Active");

                    // Logic
                    fromAcc.Balance -= amount;
                    toAcc.Balance += amount;

                    // Audit/Log
                    var trans = new Transaction
                    {
                        FromAccountID = fromAccId,
                        ToAccountID = toAccId,
                        Amount = amount,
                        TransactionType = "Transfer",
                        Status = "Completed",
                        InitiatedBy = initiatedBy,
                        Timestamp = DateTime.Now,
                        Reference = "LINQ Transfer"
                    };
                    _context.Transactions.Add(trans);

                    _context.SaveChanges();

                    var audit = new AuditLog
                    {
                        EntityName = "Transaction",
                        EntityID = trans.TransactionID.ToString(),
                        Action = "TransferFunds",
                        PerformedBy = initiatedBy,
                        Timestamp = DateTime.Now,
                        Details = "Transfer of "+amount+" from Account "+fromAccId+" to "+toAccId+" via LINQ service"
                    };
                    _context.AuditLog.Add(audit);
                    
                    _context.SaveChanges(); // Persist updates
                    transaction.Commit(); // Commit transaction
                    return true;
                }
                catch (Exception)
                {
                    transaction.Rollback(); // Rollback on error
                    return false;
                }
            }
        }

        public List<CustomerAccountSummary> GetCustomerAccountSummary(int customerId)
        {
            return _context.Customers
                .Where(c => c.CustomerID == customerId)
                .SelectMany(c => _context.Accounts.Where(a => a.CustomerID == c.CustomerID)
                    .Select(a => new CustomerAccountSummary
                    {
                        CustomerID = c.CustomerID,
                        FullName = c.FullName,
                        Email = c.Email,
                        Phone = c.Phone,
                        Address = c.Address,
                        AccountID = a.AccountID,
                        AccountNumber = a.AccountNumber,
                        AccountTypeID = a.AccountTypeID,
                        Balance = a.Balance
                    })
                ).ToList();
        }

        public List<int> GetCustomerAccountIds(int customerId)
        {
            return _context.Accounts
                .Where(a => a.CustomerID == customerId)
                .Select(a => a.AccountID)
                .ToList();
        }        
        public List<Transaction> GetArchivedTransactions()
        {
            // Returns an empty list of Transactions to satisfy the interface.
            // (If you have a separate archive table later, you can query it here).
            return _context.Transactions
            .FromSqlRaw("SELECT TOP 1000 * FROM dbo.Transaction_Partitioned ORDER BY Timestamp DESC")
            .AsNoTracking()
            .ToList();
        }


        public List<AuditLog> GetAuditLogs() 
        {
            return _context.AuditLog
                .OrderByDescending(a => a.Timestamp)
                .ToList();
        }

        public List<Customer360ViewModel> SearchCustomersByName(string fullName)
        {
            return _context.Customers
                .Where(c => c.FullName.Contains(fullName))
                .Select(c => new Customer360ViewModel
                {
                    CustomerID = c.CustomerID,
                    FullName = c.FullName,
                    Email = c.Email,
                    Phone = c.Phone,
                    Address = c.Address,
                    TotalAccounts = _context.Accounts.Count(a => a.CustomerID == c.CustomerID),
                    TotalBalance = _context.Accounts
                        .Where(a => a.CustomerID == c.CustomerID)
                        .Sum(a => (decimal?)a.Balance) ?? 0
                })
                .ToList();
        }

        public int SaveLoanApplication(Loan loan)
        {
            _context.Loans.Add(loan);
            _context.SaveChanges();
            return 0;
        }

        public int UpdateLoanApplication(int loanId, LoanStatus statusEnum)
        {
            var loan = _context.Loans.FirstOrDefault(l => l.LoanID == loanId);
            if (loan == null) return 0;
            loan.StatusEnum = statusEnum;
            return _context.SaveChanges();
        }

        public List<Loan> GetAllLoans()
        {
            return _context.Loans.ToList();
        }
    }
}