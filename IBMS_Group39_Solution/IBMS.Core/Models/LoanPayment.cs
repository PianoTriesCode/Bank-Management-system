using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace IBMS.Core.Models
{
    [Table("LoanPayment")]
    public class LoanPayment
    {
        [Key]
        public int LoanPaymentID { get; set; }

        public int LoanID { get; set; }

        public DateTime PaymentDate { get; set; }
        public decimal Amount { get; set; }
        
        [MaxLength(50)]
        public string? PaymentMethod { get; set; }
    }
}