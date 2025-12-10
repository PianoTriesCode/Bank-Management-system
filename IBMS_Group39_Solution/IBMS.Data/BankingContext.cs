using Microsoft.EntityFrameworkCore;
using IBMS.Core.Models;

namespace IBMS.Data
{
    public class BankingContext : DbContext
    {
        // Update with your actual connection string
        private const string ConnectionString = "Server=localhost;Database=IBMS_Phase2;Trusted_Connection=True;TrustServerCertificate=True;";

        public DbSet<Customer> Customers { get; set; }
        public DbSet<Account> Accounts { get; set; }
        public DbSet<AccountType> AccountTypes { get; set; }
        public DbSet<Transaction> Transactions { get; set; }
        public DbSet<Employee> Employees { get; set; }
        public DbSet<Branch> Branches { get; set; }

        protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
        {
            if (!optionsBuilder.IsConfigured)
            {
                optionsBuilder.UseSqlServer(ConnectionString);
            }
        }
    }
}