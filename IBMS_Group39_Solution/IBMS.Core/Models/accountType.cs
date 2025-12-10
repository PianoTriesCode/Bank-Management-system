using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace IBMS.Core.Models
{
    [Table("AccountType")]
    public class AccountType
    {
        [Key]
        public int AccountTypeID { get; set; }

        [Required]
        [MaxLength(50)]
        public string? Name { get; set; }

        public decimal InterestRate { get; set; }
        public decimal MinBalance { get; set; }
    }
}