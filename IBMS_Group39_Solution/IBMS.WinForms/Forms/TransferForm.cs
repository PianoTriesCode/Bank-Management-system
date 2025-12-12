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

        private Label lblHeader;
        private ComboBox cmbFromAccount;
        private ComboBox cmbRecipientCustomer;
        private ComboBox cmbRecipientAccount;
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
            LoadCustomers();
        }

        private void InitializeComponent()
        {
            this.Text = "Fund Transfer";
            this.Size = new Size(420, 380);
            this.StartPosition = FormStartPosition.CenterParent;
            this.FormBorderStyle = FormBorderStyle.FixedDialog;
            this.MaximizeBox = false;
            this.MinimizeBox = false;

            string custName = _selectedCustomer != null ? _selectedCustomer.FullName : "Unknown";
            lblHeader = new Label 
            { 
                Text = $"Transferring for Client: {custName}", 
                Location = new Point(20, 20), 
                AutoSize = true, 
                Font = new Font(this.Font, FontStyle.Bold) 
            };

            var lblFrom = new Label { Text = "From Account:", Location = new Point(20, 60), AutoSize = true };
            cmbFromAccount = new ComboBox { Location = new Point(140, 58), Width = 240, DropDownStyle = ComboBoxStyle.DropDownList };

            // var lblTo = new Label { Text = "To Account ID:", Location = new Point(20, 100), AutoSize = true };
            // txtToAccount = new TextBox { Location = new Point(120, 98), Width = 230 };
            
            var lblCust = new Label { Text = "To Customer:", Location = new Point(20, 100), AutoSize = true };
            cmbRecipientCustomer = new ComboBox { Location = new Point(140, 98), Width = 240, DropDownStyle = ComboBoxStyle.DropDownList };
            cmbRecipientCustomer.SelectedIndexChanged += (s, e) => LoadRecipientAccounts();

            var lblRecAcc = new Label { Text = "To Account:", Location = new Point(20, 140), AutoSize = true };
            cmbRecipientAccount = new ComboBox { Location = new Point(140, 138), Width = 240, DropDownStyle = ComboBoxStyle.DropDownList };


            var lblAmt = new Label { Text = "Amount ($):", Location = new Point(20, 180), AutoSize = true };
            txtAmount = new TextBox { Location = new Point(140, 178), Width = 240 };

            var lblRef = new Label { Text = "Reference:", Location = new Point(20, 220), AutoSize = true };
            txtReference = new TextBox { Location = new Point(140, 218), Width = 240 };

            btnProcess = new Button { Text = "Transfer", Location = new Point(140, 260), Width = 100, BackColor = Color.LightGreen };
            btnProcess.Click += BtnProcess_Click;

            btnCancel = new Button { Text = "Cancel", Location = new Point(260, 260), Width = 100 };
            btnCancel.Click += (s, e) => this.Close();
            
            lblStatus = new Label { Location = new Point(20, 300), Width = 360, ForeColor = Color.Red, Height = 40 };
            
            cmbFromAccount.Format += (s, e) => 
            {
                if (e.ListItem is Account acc)
                {
                    e.Value = $"{acc.AccountNumber} (Bal: {acc.Balance:C})";
                }
            };

            this.Controls.Add(lblHeader);
            this.Controls.Add(lblFrom);
            this.Controls.Add(cmbFromAccount);
            this.Controls.Add(lblCust);
            this.Controls.Add(cmbRecipientCustomer);
            this.Controls.Add(lblRecAcc);
            this.Controls.Add(cmbRecipientAccount);
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

        private void LoadCustomers()
        {
            var customers = _bankingService.GetAllCustomers();

            cmbRecipientCustomer.DisplayMember = "FullName";
            cmbRecipientCustomer.ValueMember = "CustomerID";
            cmbRecipientCustomer.DataSource = customers;
        }

        private void LoadRecipientAccounts()
        {
            if (cmbRecipientCustomer.SelectedValue == null) return;

            int custId = (int)cmbRecipientCustomer.SelectedValue;
            var accounts = _bankingService.GetAccountsForCustomer(custId);

            cmbRecipientAccount.DisplayMember = "AccountNumber";
            cmbRecipientAccount.ValueMember = "AccountID";
            cmbRecipientAccount.DataSource = accounts;
        }
        
        private void BtnProcess_Click(object sender, EventArgs e)
        {
            try
            {
                lblStatus.Text = "";

                if (cmbFromAccount.SelectedValue == null)
                    throw new Exception("Select a source account.");

                int fromId = (int)cmbFromAccount.SelectedValue;

                if (cmbRecipientAccount.SelectedValue == null)
                    throw new Exception("Select a recipient account.");

                int toId = (int)cmbRecipientAccount.SelectedValue;

                if (!decimal.TryParse(txtAmount.Text, out decimal amount) || amount <= 0)
                    throw new Exception("Enter a valid positive amount.");

                string reference = txtReference.Text.Trim();
                string initiatedBy = $"Employee-{_currentUser.EmployeeID}";

                bool success = _bankingService.TransferFunds(fromId, toId, amount, reference);

                if (success)
                {
                    MessageBox.Show("Transfer Successful!", "Success",
                        MessageBoxButtons.OK, MessageBoxIcon.Information);
                    this.Close();
                }
                else
                {
                    lblStatus.Text = "Transfer failed. Check balance or account details.";
                }
            }
            catch (Exception ex)
            {
                lblStatus.Text = ex.Message;
            }
        }
    }
}