using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace IBMS.Core.Models
{
    [Table("AuditLog")]
    public class AuditLog
    {
        [Key]
        public long AuditID { get; set; }

        [Required]
        [MaxLength(100)]
        public string? EntityName { get; set; }

        [Required]
        [MaxLength(100)]
        public string? EntityID { get; set; }

        [Required]
        [MaxLength(50)]
        public string? Action { get; set; }

        [Required]
        [MaxLength(100)]
        public string PerformedBy { get; set; }

        public DateTime Timestamp { get; set; }
        public string? Details { get; set; }
    }
}