namespace IBMS.Core.Models
{
    public class Customer360ViewModel
    {
        public int CustomerID { get; set; }
        public string? FullName { get; set; }
        public string? Email { get; set; }
        public string? Phone { get; set; }
        public string? Address { get; set; }
        public int TotalAccounts { get; set; }
        public decimal TotalBalance { get; set; }
    }
}
