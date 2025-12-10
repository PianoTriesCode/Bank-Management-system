using System;
using System.Linq;
using IBMS.Data;
using Microsoft.EntityFrameworkCore;

namespace IBMS.TestConnection
{
    class Program
    {
        static void Main(string[] args)
        {
            Console.WriteLine("Testing Database Connection...");

            try
            {
                using (var context = new BankingContext())
                {
                    // Attempt to open connection explicitly to fail fast if config is wrong
                    context.Database.OpenConnection();
                    Console.WriteLine("Connection Opened Successfully!");

                    // Try a simple query
                    int employeeCount = context.Employees.Count();
                    Console.WriteLine($"Found {employeeCount} employees in the database.");

                    context.Database.CloseConnection();
                }
                
                Console.WriteLine("Test Passed: Database is accessible.");
            }
            catch (Exception ex)
            {
                Console.WriteLine("Test Failed: Could not connect to database.");
                Console.WriteLine($"Error: {ex.Message}");
                if (ex.InnerException != null)
                {
                    Console.WriteLine($"Inner Error: {ex.InnerException.Message}");
                }
            }
        }
    }
}