using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace IBMS.Core.Models
{
    [Table("ScheduledJob")]
    public class ScheduledJob
    {
        [Key]
        public int JobID { get; set; }

        [Required]
        [MaxLength(100)]
        public string? JobName { get; set; }

        [Required]
        [MaxLength(100)]
        public string? StoredProcedureName { get; set; }

        [Required]
        [MaxLength(20)]
        public string? Frequency { get; set; }

        public bool IsEnabled { get; set; }
        public DateTime? LastRun { get; set; }
        public DateTime? NextRun { get; set; }
    }
}