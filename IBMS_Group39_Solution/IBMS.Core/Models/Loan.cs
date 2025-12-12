using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace IBMS.Core.Models
{
    [Table("Loan")]
    public class Loan
    {
        [Key]
        public int LoanID { get; set; }

        public int CustomerID { get; set; }
        public int AccountID { get; set; }

        public decimal PrincipalAmount { get; set; }
        public decimal InterestRate { get; set; }
        public int TermMonths { get; set; }
        
        public DateTime StartDate { get; set; }
        public DateTime? EndDate { get; set; }

        [MaxLength(20)]
        public string? Status { get; set; }
    }
}