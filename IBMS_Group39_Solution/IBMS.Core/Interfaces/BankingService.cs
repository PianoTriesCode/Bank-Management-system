using System.Collections.Generic;
using IBMS.Core.Models;

namespace IBMS.Core.Interfaces
{
    public interface IBankingService
    {
        // --- Authentication ---
        // Uses: sp_EmployeeLogin vs LINQ Query
        Employee Login(int employeeId);

        // --- Customer Management ---
        // Uses: sp_CreateCustomer vs EF .Add()
        int CreateCustomer(Customer customer);
        
        // Uses: sp_GetCustomerByID vs EF .Find()
        Customer GetCustomer(int customerId);
        
        // Uses: view_Customer360 vs LINQ Join
        List<CustomerViewModel> GetAllCustomers();

        // --- Account Management ---
        // Uses: View or LINQ Where
        List<Account> GetAccountsForCustomer(int customerId);
        
        // Uses: Scalar Function fn_GetTotalCustomerAssets vs LINQ Sum
        decimal GetTotalAssets(int customerId);

        // --- Transactions (The Critical Logic) ---
        // Uses: sp_TransferFunds vs EF TransactionScope
        bool TransferFunds(int fromAccId, int toAccId, decimal amount, string initiatedBy);

        // Uses: CTE sp_GetAccountStatement vs LINQ
        List<Transaction> GetAccountStatement(int accountId);
    }
    
    // Helper VM for the Dashboard Grid
    public class CustomerViewModel 
    {
        public int CustomerID { get; set; }
        public string? FullName { get; set; }
        public string? Email { get; set; }
        public decimal TotalBalance { get; set; }
    }
}