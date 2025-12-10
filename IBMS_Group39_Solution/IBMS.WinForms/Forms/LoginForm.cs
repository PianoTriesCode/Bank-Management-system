using System;
using System.Drawing;
using System.Windows.Forms;
using IBMS.Data;
using IBMS.Core.Interfaces;

namespace IBMS.WinForms.Forms
{
    public class LoginForm : Form
    {
        private TextBox txtEmployeeId;
        private Label lblStatus;

        public LoginForm()
        {
            this.Text = "IBMS Login";
            this.Size = new Size(350, 220); // Slightly larger for error messages
            this.StartPosition = FormStartPosition.CenterScreen;

            var lbl = new Label { Text = "Employee ID:", Location = new Point(20, 30), AutoSize = true };
            txtEmployeeId = new TextBox { Location = new Point(100, 28), Width = 150, Text = "1" };
            var btnLogin = new Button { Text = "Login", Location = new Point(100, 70) };
            
            // Allow more space for error text
            lblStatus = new Label { Location = new Point(20, 110), Width = 300, Height = 60, ForeColor = Color.Red };

            btnLogin.Click += BtnLogin_Click;
            this.Controls.Add(lbl);
            this.Controls.Add(txtEmployeeId);
            this.Controls.Add(btnLogin);
            this.Controls.Add(lblStatus);
        }

        private void BtnLogin_Click(object sender, EventArgs e)
        {
            lblStatus.Text = "Connecting...";
            Application.DoEvents(); // Force UI update

            try
            {
                if (!int.TryParse(txtEmployeeId.Text, out int id))
                {
                    lblStatus.Text = "Please enter a valid numeric ID.";
                    return;
                }

                // Attempt login using LINQ service (safest default)
                IBankingService service = ServiceFactory.GetService(ServiceType.LINQ);
                var emp = service.Login(id);

                if (emp != null)
                {
                    this.Hide();
                    new DashboardForm(emp).ShowDialog();
                    this.Close();
                }
                else 
                {
                    lblStatus.Text = $"Login Failed: Employee ID {id} not found in database.";
                }
            }
            catch (Exception ex) 
            { 
                // Display the actual connection error details
                lblStatus.Text = $"System Error:\n{ex.Message}\n(Check App.config connection string)";
            }
        }
    }
}