using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace IBMS.Core.Models
{
    [Table("Loan")]
    public class Loan
    {
        [Key]
        public int LoanID { get; set; }

        public int CustomerID { get; set; }
        public int AccountID { get; set; }

        public decimal PrincipalAmount { get; set; }
        public decimal InterestRate { get; set; }
        public int TermMonths { get; set; }
        public string AppliedBy { get; set; }
        public DateTime StartDate { get; set; }
        public DateTime? EndDate { get; set; }

        public string Status { get; set; } = "Applied";

        [NotMapped]
        public LoanStatus StatusEnum
        {
            get
            {
                if (Enum.TryParse<LoanStatus>(Status, true, out var parsed))
                    return parsed;

                return LoanStatus.Applied;
            }
            set => Status = value.ToString();
        }
    }
};

public enum LoanStatus
{
    Applied = 1,
    Approved = 2,
    Rejected = 3,
    Active = 4,
    Closed = 5
};

public static class LoanStatusHelper
{
    public static string GetDisplayName(LoanStatus status)
    {
        return status switch
        {
            LoanStatus.Applied => "Applied",
            LoanStatus.Approved => "Approved",
            LoanStatus.Rejected => "Rejected",
            LoanStatus.Active => "Active",
            LoanStatus.Closed => "Closed",
            _ => status.ToString()
        };
    }
    
    public static Dictionary<int, string> GetAllStatuses()
    {
        return Enum.GetValues(typeof(LoanStatus))
            .Cast<LoanStatus>()
            .ToDictionary(
                s => (int)s,
                s => GetDisplayName(s)
            );
    }
}