using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace IBMS.Core.Models
{
    [Table("Beneficiary")]
    public class Beneficiary
    {
        [Key]
        public int BeneficiaryID { get; set; }

        public int CustomerID { get; set; }

        [Required]
        [MaxLength(20)]
        public string? BeneficiaryAccountNumber { get; set; }

        [Required]
        [MaxLength(100)]
        public string? BankName { get; set; }

        [MaxLength(50)]
        public string? Nickname { get; set; }
    }
}