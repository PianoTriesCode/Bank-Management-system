using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace IBMS.Core.Models
{
    [Table("Card")]
    public class Card
    {
        [Key]
        public int CardID { get; set; }

        [Required]
        [MaxLength(16)]
        public string? CardNumber { get; set; }

        public int AccountID { get; set; }

        [Required]
        [MaxLength(20)]
        public string? CardType { get; set; }

        public DateTime ExpiryDate { get; set; }
        
        [MaxLength(20)]
        public string? Status { get; set; }

        [MaxLength(3)]
        public string? CVV { get; set; }
    }
}