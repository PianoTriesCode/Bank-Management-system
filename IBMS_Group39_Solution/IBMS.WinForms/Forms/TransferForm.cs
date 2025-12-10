using System;
using System.Windows.Forms;
using System.Drawing;
using IBMS.Core.Interfaces;
using IBMS.Core.Models;

namespace IBMS.WinForms.Forms
{
    public class TransferForm : Form
    {
        private IBankingService _bankingService;
        private Employee _currentUser;
        private CustomerViewModel _selectedCustomer; 

        private Label lblCustomer;
        private ComboBox cmbFromAccount;
        private TextBox txtToAccount;
        private TextBox txtAmount;
        private TextBox txtReference;
        private Button btnProcess;
        private Button btnCancel;
        private Label lblStatus;

        public TransferForm(IBankingService service, Employee user, object selectedCustomerObj)
        {
            _bankingService = service;
            _currentUser = user;
            _selectedCustomer = selectedCustomerObj as CustomerViewModel;

            InitializeComponent();
            LoadAccounts();
        }

        private void InitializeComponent()
        {
            this.Text = "Fund Transfer";
            this.Size = new Size(400, 360);
            this.StartPosition = FormStartPosition.CenterParent;
            this.FormBorderStyle = FormBorderStyle.FixedDialog;
            this.MaximizeBox = false;
            this.MinimizeBox = false;

            string custName = _selectedCustomer != null ? _selectedCustomer.FullName : "Unknown";
            lblCustomer = new Label 
            { 
                Text = $"Transferring for Client: {custName}", 
                Location = new Point(20, 20), 
                AutoSize = true, 
                Font = new Font(this.Font, FontStyle.Bold) 
            };

            var lblFrom = new Label { Text = "From Account:", Location = new Point(20, 60), AutoSize = true };
            cmbFromAccount = new ComboBox { Location = new Point(120, 58), Width = 230, DropDownStyle = ComboBoxStyle.DropDownList };

            var lblTo = new Label { Text = "To Account ID:", Location = new Point(20, 100), AutoSize = true };
            txtToAccount = new TextBox { Location = new Point(120, 98), Width = 230 };
            
            var lblAmt = new Label { Text = "Amount ($):", Location = new Point(20, 140), AutoSize = true };
            txtAmount = new TextBox { Location = new Point(120, 138), Width = 230 };

            var lblRef = new Label { Text = "Reference:", Location = new Point(20, 180), AutoSize = true };
            txtReference = new TextBox { Location = new Point(120, 178), Width = 230 };

            btnProcess = new Button { Text = "Transfer", Location = new Point(120, 220), Width = 100, BackColor = Color.LightGreen };
            btnCancel = new Button { Text = "Cancel", Location = new Point(250, 220), Width = 100 };
            
            lblStatus = new Label { Location = new Point(20, 260), Width = 340, ForeColor = Color.Red, Height = 40 };

            btnProcess.Click += BtnProcess_Click;
            btnCancel.Click += (s, e) => this.Close();
            
            cmbFromAccount.Format += (s, e) => 
            {
                if (e.ListItem is Account acc)
                {
                    e.Value = $"{acc.AccountNumber} (Bal: {acc.Balance:C})";
                }
            };

            this.Controls.Add(lblCustomer);
            this.Controls.Add(lblFrom);
            this.Controls.Add(cmbFromAccount);
            this.Controls.Add(lblTo);
            this.Controls.Add(txtToAccount);
            this.Controls.Add(lblAmt);
            this.Controls.Add(txtAmount);
            this.Controls.Add(lblRef);
            this.Controls.Add(txtReference);
            this.Controls.Add(btnProcess);
            this.Controls.Add(btnCancel);
            this.Controls.Add(lblStatus);
        }

        private void LoadAccounts()
        {
            if (_selectedCustomer == null)
            {
                lblStatus.Text = "No customer selected.";
                btnProcess.Enabled = false;
                return;
            }

            try
            {
                var accounts = _bankingService.GetAccountsForCustomer(_selectedCustomer.CustomerID);
                
                if (accounts.Count == 0)
                {
                    MessageBox.Show("This customer has no active accounts.", "Warning");
                    this.Close();
                    return;
                }

                cmbFromAccount.DataSource = accounts;
                cmbFromAccount.DisplayMember = "AccountNumber"; 
                cmbFromAccount.ValueMember = "AccountID";
            }
            catch (Exception ex)
            {
                MessageBox.Show("Error loading accounts: " + ex.Message);
            }
        }

        private void BtnProcess_Click(object sender, EventArgs e)
        {
            try
            {
                lblStatus.Text = "";

                if (cmbFromAccount.SelectedItem == null) throw new Exception("Select a source account.");
                
                // Fix for CS8605: Check for null before casting
                if (cmbFromAccount.SelectedValue == null) throw new Exception("Invalid Account selection.");
                int fromId = (int)cmbFromAccount.SelectedValue;

                if (string.IsNullOrWhiteSpace(txtToAccount.Text)) throw new Exception("Enter destination account ID.");
                
                if (!decimal.TryParse(txtAmount.Text, out decimal amount) || amount <= 0) 
                    throw new Exception("Enter a valid positive amount.");

                if (!int.TryParse(txtToAccount.Text, out int toId))
                    throw new Exception("Target Account ID must be a number.");

                string refMsg = txtReference.Text;
                string initiatedBy = $"Employee-{_currentUser.EmployeeID}";

                bool success = _bankingService.TransferFunds(fromId, toId, amount, initiatedBy);

                if (success)
                {
                    MessageBox.Show("Transfer Successful!", "Success", MessageBoxButtons.OK, MessageBoxIcon.Information);
                    this.Close();
                }
                else
                {
                    lblStatus.Text = "Transfer Failed. Check logs or balance.";
                }
            }
            catch (Exception ex)
            {
                lblStatus.Text = ex.Message;
            }
        }
    }
}