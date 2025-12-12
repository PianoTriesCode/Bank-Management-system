using System.Collections.Generic;
using System.Data;
using Microsoft.Data.SqlClient;
using Dapper;
using IBMS.Core.Interfaces;
using IBMS.Core.Models;

namespace IBMS.Data.Repositories
{
    public class CustomerRepository : ICustomerRepository
    {
        private readonly string _connection;

        public CustomerRepository(string connString)
        {
            _connection = connString;
        }

        private IDbConnection Conn => new SqlConnection(_connection);

        public List<Customer360ViewModel> GetAllCustomer360()
        {
            using (var db = Conn)
            {
                return db.Query<Customer360ViewModel>("SELECT * FROM dbo.view_Customer360").AsList();
            }
        }

        public Customer GetById(int id)
        {
            string sql = "SELECT * FROM Customers WHERE CustomerID = @id";
            using (var db = Conn)
                return db.QuerySingle<Customer>(sql, new { id });
        }

        public int CreateCustomer(Customer c)
        {
            using (var db = Conn)
            {
                var p = new DynamicParameters();
                p.Add("@FullName", c.FullName);
                p.Add("@DOB", c.DOB);
                p.Add("@Email", c.Email);
                p.Add("@Phone", c.Phone);
                p.Add("@Address", c.Address);
                p.Add("@CreatedBy", c.CreatedBy);
                p.Add("@NewCustomerID", dbType: DbType.Int32, direction: ParameterDirection.Output);

                db.Execute("sp_CreateCustomer", p, commandType: CommandType.StoredProcedure);
                return p.Get<int>("@NewCustomerID");
            }
        }

        public void UpdateCustomer(Customer c)
        {
            using (var db = Conn)
            {
                db.Execute("sp_UpdateCustomer", new
                {
                    c.CustomerID,
                    c.FullName,
                    c.DOB,
                    c.Email,
                    c.Phone,
                    c.Address
                }, commandType: CommandType.StoredProcedure);
            }
        }

        public void DeleteCustomer(int id)
        {
            using (var db = Conn)
            {
                db.Execute("sp_DeleteCustomer", new { CustomerID = id },
                    commandType: CommandType.StoredProcedure);
            }
        }
    }
}
