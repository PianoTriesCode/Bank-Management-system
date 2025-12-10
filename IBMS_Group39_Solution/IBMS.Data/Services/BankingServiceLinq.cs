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
            // LINQ: Transaction Logic (Replicating the SP logic in C#)
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

        public List<Transaction> GetAccountStatement(int accountId)
        {
            // LINQ: Complex Filtering (From OR To)
            return _context.Transactions
                .Where(t => t.FromAccountID == accountId || t.ToAccountID == accountId)
                .OrderByDescending(t => t.Timestamp)
                .ToList();
        }
    }
}