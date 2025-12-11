📚 Digital Library Management System (LMS)

A robust, database-driven application designed to automate and centralize the core functions of a physical library. This system manages books, members, loans, and fines, replacing inefficient manual record-keeping with a modern .NET interface and SQL Server backend.

🚀 Overview

This project demonstrates a multi-layered software architecture that allows for dynamic switching between two different business logic implementations: LINQ (Entity Framework) and Stored Procedures. It uses the Factory Design Pattern to swap these implementations at runtime without restarting the application.

Key Objectives

Automate Circulation: Streamline checking books in and out.

Centralize Data: A single source of truth for the catalog and member records.

Ensure Accountability: Automated fine calculation for overdue items.

Technical Showcase: Comparison of ORM (LINQ) vs. Traditional SQL (Stored Procedures) performance and implementation.

✨ Features

📖 Catalog Management: Full CRUD operations for Books, Authors, and Categories.

🔄 Circulation Control: Atomic transactions for borrowing and returning books.

💰 Fine Management: Automated calculation of overdue fines based on return dates.

🔍 Search & Discovery: Dynamic filtering to find books by Title, Author, or Genre.

reservations: (Optional) Queue system for reserving books that are currently on loan.

⚙️ Runtime Logic Switching: Toggle between LINQ and Stored Procedure logic instantly via the Dashboard.

🛠️ Tech Stack

Frontend: Windows Forms (.NET Framework/Core)

Backend: Microsoft SQL Server

ORM: Entity Framework Core

Language: C#

Design Pattern: Factory Pattern, Repository Pattern

📋 Prerequisites

Before running this project, ensure you have the following installed:

.NET SDK (Recommended: .NET 6.0 or later)

SQL Server (LocalDB, Express, or Docker container)

SQL Server Management Studio (SSMS) or Azure Data Studio

Visual Studio 2022 or VS Code

⚙️ Installation & Setup

Follow these steps to get a local copy up and running.

1. Clone the Repository

git clone [https://github.com/YOUR_USERNAME/Library-Management-System.git](https://github.com/YOUR_USERNAME/Library-Management-System.git)
cd Library-Management-System


2. Database Setup

Open SSMS or your preferred SQL tool.

Connect to your local SQL Server instance.

Open the script located at Database/LMS_Schema_And_Seed.sql.

Execute the script. This will:

Create the LMS_DB database.

Create all tables (Books, Members, Loans, etc.).

Create necessary Stored Procedures.

Seed the database with sample data (Books, Authors, Members).

3. Configure Connection String

Navigate to the UI project folder (e.g., LMS.WinForms).

Open App.config.

Update the connection string to match your local server:

<connectionStrings>
    <add name="LMSConnection" 
         connectionString="Server=localhost;Database=LMS_DB;Trusted_Connection=True;TrustServerCertificate=True;" 
         providerName="System.Data.SqlClient" />
</connectionStrings>


Note: If using Docker or SQL Authentication, replace Trusted_Connection=True with User Id=sa;Password=YourStrong!Password;.

4. Build and Run

Open the solution in Visual Studio or use the CLI:

dotnet build
dotnet run --project LMS.WinForms
