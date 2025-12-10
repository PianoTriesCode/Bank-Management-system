using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace IBMS.Core.Models
{
    [Table("Employee")]
    public class Employee
    {
        [Key]
        public int EmployeeID { get; set; }

        [Required]
        [MaxLength(100)]
        public string? FullName { get; set; }

        [Required]
        [MaxLength(50)]
        public string? Role { get; set; } // Manager, Teller, Admin

        public int BranchID { get; set; }

        [ForeignKey("BranchID")]
        public virtual Branch? Branch { get; set; }
    }
}