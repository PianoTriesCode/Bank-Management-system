using System.Collections.Generic;
using IBMS.Core.Models;

namespace IBMS.Core.Interfaces
{
    public interface ILoanRepository
    {
        List<Loan> GetAllLoans();
        int SaveLoanApplication(Loan l);
        int UpdateLoanById(Loan l);
    }
}
