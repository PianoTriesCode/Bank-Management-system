using System;

namespace IBMS.Core.Models
{
    public class TransactionStatementViewModel
    {
        public long TransactionID { get; set; }
        public DateTime Timestamp { get; set; }
        public string? TransactionType { get; set; }
        public decimal Amount { get; set; }
        public string? Reference { get; set; }
        
        // This is the special column from the CTE
        public decimal RunningBalance { get; set; }
    }
}