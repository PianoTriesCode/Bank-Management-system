using IBMS.Core.Interfaces;
using IBMS.Data.Services;
using IBMS.Data.Repositories;
using Microsoft.EntityFrameworkCore;

namespace IBMS.Data
{
    public enum ServiceType
    {
        LINQ,
        StoredProcedure
    }

    public static class ServiceFactory
    {
        public static IBankingService GetService(ServiceType type)
        {
            var context = new BankingContext();

            switch (type)
            {
                case ServiceType.LINQ:
                    return new BankingServiceLINQ(context);
                
                case ServiceType.StoredProcedure:
                    return new BankingServiceSP(
                        context,
                        new CustomerRepository(context.Database.GetDbConnection().ConnectionString)
                        // new AccountRepository(context.Database.GetConnectionString()),
                        // new TransactionRepository(context.Database.GetConnectionString())
                    );
                
                default:
                    throw new System.ArgumentException("Invalid Service Type");
            }
        }
    }
}