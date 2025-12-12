namespace IBMS.Core.Models
{
    public class Customer360ViewModel
    {
        public int CustomerID { get; set; }
        public string FullName { get; set; }
        public string Email { get; set; }
        public string Phone { get; set; }
        public string BranchName { get; set; }
        public decimal TotalBalance { get; set; }
        public string Status { get; set; }
        public string Accounts { get; set; }
    }
}
