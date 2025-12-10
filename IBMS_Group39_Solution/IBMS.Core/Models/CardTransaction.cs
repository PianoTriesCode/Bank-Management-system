using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace IBMS.Core.Models
{
    [Table("CardTransaction")]
    public class CardTransaction
    {
        [Key]
        public long CardTxID { get; set; }

        public int CardID { get; set; }

        [Column(TypeName = "decimal(18,2)")]
        public decimal Amount { get; set; }

        [Required]
        [MaxLength(100)]
        public string? Merchant { get; set; }

        public DateTime Timestamp { get; set; }

        [MaxLength(50)]
        public string? AuthorizationCode { get; set; }
    }
}