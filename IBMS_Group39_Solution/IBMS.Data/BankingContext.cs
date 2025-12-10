using Microsoft.EntityFrameworkCore;
using IBMS.Core.Models;

namespace IBMS.Data
{
    public class BankingContext : DbContext
    {
        // HARDCODED FALLBACK: This matches your specific Docker setup from the screenshot
        private const string ConnectionString = "Server=localhost;Database=IBMS_Phase2;User Id=sa;Password=YourStrong!Passw0rd;TrustServerCertificate=True;";

        public DbSet<Customer> Customers { get; set; }
        public DbSet<Account> Accounts { get; set; }
        public DbSet<AccountType> AccountTypes { get; set; }
        public DbSet<Transaction> Transactions { get; set; }
        public DbSet<Employee> Employees { get; set; }
        public DbSet<Branch> Branches { get; set; }

        // Standard constructor
        public BankingContext()
        {
        }

        // Constructor accepting options (good practice)
        public BankingContext(DbContextOptions<BankingContext> options) : base(options)
        {
        }

        protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
        {
            if (!optionsBuilder.IsConfigured)
            {
                // Force usage of the correct connection string
                optionsBuilder.UseSqlServer(ConnectionString);
            }
        }
    }
}