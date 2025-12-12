using System;
using System.Windows.Forms;
using IBMS.Core.Interfaces;
using IBMS.Core.Models;

namespace IBMS.WinForms.Forms
{
    public class SingleAccountForm : Form
    {
        private readonly IBankingService _service;
        private readonly int _customerId;
        private readonly Account? _existing;

        private ComboBox cmbAccountType;
        private ComboBox cmbBranch;
        private TextBox txtBalance;
        private ComboBox cmbStatus;

        private Button btnSave;
        private Button btnCancel;
        private TextBox txtAccountNumber;

        public SingleAccountForm(IBankingService service, int customerId, Account? existing = null)
        {
            _service = service;
            _customerId = customerId;
            _existing = existing;

            InitializeComponent();
            LoadDropdowns();

            if (_existing != null)
                LoadExistingData();
        }

        private void InitializeComponent()
        {
            
            this.Text = _existing == null ? "Add Account" : "Edit Account";
            this.Size = new Size(400, 350);
            

            cmbAccountType = new ComboBox { Location = new Point(20, 20), Width = 220 };
            cmbBranch = new ComboBox { Location = new Point(20, 60), Width = 220 };
            txtBalance = new TextBox { Location = new Point(20, 100), Width = 220 };
            cmbStatus = new ComboBox { Location = new Point(20, 140), Width = 220 };
            cmbStatus.Items.AddRange(new[] { "Active", "Frozen", "Closed" });

            btnSave = new Button { Text = "Save", Location = new Point(20, 190), Width = 100 };
            btnCancel = new Button { Text = "Cancel", Location = new Point(150, 190), Width = 100 };

            txtAccountNumber = new TextBox { Location = new Point(20, 180), Width = 220, PlaceholderText = "Account Number" };
            this.Controls.Add(txtAccountNumber);

            btnSave.Click += BtnSave_Click;
            btnCancel.Click += (s, e) => DialogResult = DialogResult.Cancel;

            this.Controls.Add(cmbAccountType);
            this.Controls.Add(cmbBranch);
            this.Controls.Add(txtBalance);
            this.Controls.Add(cmbStatus);
            this.Controls.Add(btnSave);
            this.Controls.Add(btnCancel);
        }

        private void LoadDropdowns()
        {
            cmbAccountType.DataSource = _service.GetAllAccountTypes();
            cmbAccountType.DisplayMember = "Name";
            cmbAccountType.ValueMember = "AccountTypeID";

            cmbBranch.DataSource = _service.GetAllBranches();
            cmbBranch.DisplayMember = "Name";
            cmbBranch.ValueMember = "BranchID";
        }

        private void LoadExistingData()
        {
            cmbAccountType.SelectedValue = _existing.AccountTypeID;
            cmbBranch.SelectedValue = _existing.BranchID;
            txtBalance.Text = _existing.Balance.ToString();
            cmbStatus.SelectedItem = _existing.Status;
        }

        private void BtnSave_Click(object sender, EventArgs e)
        {
            // 1. Validate Account Number
            if (string.IsNullOrWhiteSpace(txtAccountNumber.Text))
            {
                MessageBox.Show("Account Number is required.", "Validation Error", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                txtAccountNumber.Focus();
                return;
            }

            // 2. Validate Balance (Stop the silent failure)
            if (!decimal.TryParse(txtBalance.Text, out decimal balance) || balance < 0)
            {
                MessageBox.Show("Please enter a valid non-negative balance.", "Validation Error", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                txtBalance.Focus();
                return;
            }

            // 3. Validate Dropdowns
            if (cmbAccountType.SelectedValue == null || cmbBranch.SelectedValue == null)
            {
                MessageBox.Show("Please select a valid Account Type and Branch.", "Validation Error", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            bool isEdit = _existing != null;
            var acc = isEdit ? _existing : new Account();

            acc.CustomerID = _customerId;
            acc.AccountTypeID = (int)cmbAccountType.SelectedValue;
            acc.BranchID = (int)cmbBranch.SelectedValue;
            acc.Balance = balance; // Use the parsed variable
            acc.Status = cmbStatus.SelectedItem?.ToString() ?? "Active";
            acc.AccountNumber = txtAccountNumber.Text.Trim(); // Trim whitespace

            try 
            {
                if (isEdit)
                    _service.UpdateAccount(acc);
                else
                    _service.CreateAccount(acc);

                DialogResult = DialogResult.OK;
            }
            catch (Exception ex)
            {
                MessageBox.Show("Error saving account: " + ex.Message);
            }
        }
    }
}