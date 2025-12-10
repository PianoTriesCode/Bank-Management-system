using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace IBMS.Core.Models
{
    [Table("Branch")]
    public class Branch
    {
        [Key]
        public int BranchID { get; set; }

        [Required]
        [MaxLength(100)]
        public string? Name { get; set; }

        [Required]
        [MaxLength(255)]
        public string? Location { get; set; }

        public int? ManagerEmployeeID { get; set; }
    }
}