using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace IBMS.Core.Models
{
    [Table("Transaction")]
    public class Transaction
    {
        [Key]
        public long TransactionID { get; set; }

        public int? FromAccountID { get; set; }
        public int? ToAccountID { get; set; }

        [Column(TypeName = "decimal(18,2)")]
        public decimal Amount { get; set; }

        [Required]
        [MaxLength(20)]
        public string? TransactionType { get; set; }

        [MaxLength(20)]
        public string? Status { get; set; }

        [MaxLength(100)]
        public string? InitiatedBy { get; set; }

        public DateTime Timestamp { get; set; }
        public string? Reference { get; set; }
    }
}