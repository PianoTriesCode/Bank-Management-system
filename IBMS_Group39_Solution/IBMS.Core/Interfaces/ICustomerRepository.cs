using System.Collections.Generic;
using IBMS.Core.Models;

namespace IBMS.Core.Interfaces
{
    public interface ICustomerRepository
    {
        List<Customer360ViewModel> GetAllCustomer360();
        List<CustomerAccountSummary> GetCustomerAccountSummary(int customerId);
        Customer GetById(int id);
        int CreateCustomer(Customer c);
        void UpdateCustomer(Customer c);
        void DeleteCustomer(int id);
    }
}
