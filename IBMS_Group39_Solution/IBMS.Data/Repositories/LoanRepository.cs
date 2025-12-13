using System.Collections.Generic;
using System.Data;
using Microsoft.Data.SqlClient;
using Dapper;
using IBMS.Core.Interfaces;
using IBMS.Core.Models;

namespace IBMS.Data.Repositories
{
    public class LoanRepository : ILoanRepository
    {
        private readonly string _connection;

        public LoanRepository(string connString)
        {
            _connection = connString;
        }

        private IDbConnection Conn => new SqlConnection(_connection);

        public List<Loan> GetAllLoans()
        {
            using (var db = Conn)
            {
                return db.Query<Loan>("SELECT * FROM dbo.Loan").AsList();
            }
        }


        public int UpdateLoanById(Loan l)
        {
            using (var db = Conn)
            {
                db.Execute("sp_UpdateLoan", new
                {
                    l.LoanID,
                    l.CustomerID,
                    l.AccountID,
                    l.PrincipalAmount,
                    l.InterestRate,
                    l.TermMonths,
                    l.StartDate,
                    l.EndDate,
                    l.Status
                }, commandType: CommandType.StoredProcedure);
            }
            return l.LoanID;
        }

        public int SaveLoanApplication(Loan l)
        {
            using (var db = Conn)
            {
                var p = new DynamicParameters();
                p.Add("@CustomerID", l.CustomerID);
                p.Add("@AccountID", l.AccountID);
                p.Add("@PrincipalAmount", l.PrincipalAmount);
                p.Add("@InterestRate", l.InterestRate);
                p.Add("@TermMonths", l.TermMonths);
                p.Add("@StartDate", l.StartDate);
                p.Add("@EndDate", l.EndDate);
                p.Add("@Status", l.Status);
                p.Add("@AppliedBy", l.AppliedBy);
                p.Add("@NewLoanID", dbType: DbType.Int32, direction: ParameterDirection.Output);

                db.Execute("sp_ApplyForLoan", p, commandType: CommandType.StoredProcedure);
                return p.Get<int>("@NewLoanID");
            }
        }
    }
}
