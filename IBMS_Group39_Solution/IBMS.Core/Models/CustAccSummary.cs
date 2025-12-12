namespace IBMS.Core.Models
{
    public class CustomerAccountSummary
    {
        // Customer Info
        public int CustomerID { get; set; }
        public string? FullName { get; set; }
        public string? Email { get; set; }
        public string? Phone { get; set; }
        public string? Address { get; set; }

        // Account Info (nullable because of LEFT JOIN)
        public int? AccountID { get; set; }
        public string? AccountNumber { get; set; }
        public int? AccountTypeID { get; set; }
        public decimal? Balance { get; set; }
    }
}