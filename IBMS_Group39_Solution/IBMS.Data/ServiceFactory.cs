using IBMS.Core.Interfaces;
using IBMS.Data.Services; // We will create these next

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
                    return new BankingServiceSP(context);
                
                default:
                    throw new System.ArgumentException("Invalid Service Type");
            }
        }
    }
}