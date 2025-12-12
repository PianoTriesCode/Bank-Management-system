using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Microsoft.EntityFrameworkCore.Metadata;
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
        public DbSet<AuditLog> AuditLog { get; set; }
        public DbSet<Customer360ViewModel> Customer360ViewModels { get; set; }
        public DbSet<AccountType> accountTypes { get; set; }
        public DbSet<Branch> branch { get; set; }



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

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            var entityType = modelBuilder.Entity<Customer>().Metadata;
            EntityTypeBuilder.HasTrigger(entityType, "trigger_Customer_AfterInsert");

            modelBuilder.Entity<Customer360ViewModel>(entity =>
            {
                entity.HasNoKey();
                entity.ToView(null);
            });
        }
    }
}