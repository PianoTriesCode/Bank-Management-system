using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace IBMS.Core.Models
{
    [Table("Account")]
    public class Account
    {
        [Key]
        public int AccountID { get; set; }

        [Required]
        [MaxLength(20)]
        public string? AccountNumber { get; set; }

        public int CustomerID { get; set; }
        public int AccountTypeID { get; set; }
        public int BranchID { get; set; }

        [Column(TypeName = "decimal(18,2)")]
        public decimal Balance { get; set; }

        [MaxLength(20)]
        public string? Status { get; set; } // Active, Frozen, Closed

        public DateTime CreatedDate { get; set; }

        // Navigation Properties (Optional, useful for LINQ)
        [ForeignKey("AccountTypeID")]
        public virtual AccountType? AccountType { get; set; }
    }
}