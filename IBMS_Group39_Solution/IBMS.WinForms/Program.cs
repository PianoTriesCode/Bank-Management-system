using System;
using System.Windows.Forms;
using IBMS.WinForms.Forms;

namespace IBMS.WinForms
{
    static class Program
    {
        [STAThread]
        static void Main()
        {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            
            // Start with the Login Form
            Application.Run(new LoginForm());
        }
    }
}