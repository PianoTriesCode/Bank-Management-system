using System;
using System.Windows.Forms;
using System.Collections.Generic;

namespace IBMS.WinForms.Forms
{
    public partial class LoanApplicationForm : Form
    {
        private Label lblCustomerId;
        private Label lblAccount;
        private Label lblPrincipalAmount;
        private Label lblInterest;
        private Label lblNoOfMonths;
        private Label lblStartDate;
        private Label lblEndDate;

        private ComboBox txtAccount;
        private NumericUpDown txtPrincipalAmount;
        private NumericUpDown txtInterest;
        private NumericUpDown txtNoOfMonths;
        private DateTimePicker dtpStartDate;
        private DateTimePicker dtpEndDate;

        private Button btnSave;
        private Button btnCancel;

        private void InitializeComponent()
        {
            lblCustomerId = new Label { Location = new System.Drawing.Point(25, 25), AutoSize = true };
            lblAccount = new Label { Location = new System.Drawing.Point(25, 75), AutoSize = true, Text = "Choose Account:" };
            lblPrincipalAmount = new Label { Location = new System.Drawing.Point(25, 125), AutoSize = true, Text = "Principal Amount:" };
            lblInterest = new Label { Location = new System.Drawing.Point(25, 175), AutoSize = true, Text = "Interest (%):" };
            lblNoOfMonths = new Label { Location = new System.Drawing.Point(25, 225), AutoSize = true, Text = "No. of Months:" };
            lblStartDate = new Label { Location = new System.Drawing.Point(25, 275), AutoSize = true, Text = "Start Date:" };
            lblEndDate = new Label { Location = new System.Drawing.Point(25, 325), AutoSize = true, Text = "End Date:" };

            txtAccount = new ComboBox
            {
                Location = new System.Drawing.Point(200, 72),
                Size = new System.Drawing.Size(150, 23),
                DropDownStyle = ComboBoxStyle.DropDownList
            };

            txtPrincipalAmount = new NumericUpDown
            {
                Location = new System.Drawing.Point(200, 122),
                Size = new System.Drawing.Size(150, 23),
                Minimum = 0,
                Maximum = decimal.MaxValue,
                DecimalPlaces = 2,
                ThousandsSeparator = true
            };

            txtInterest = new NumericUpDown
            {
                Location = new System.Drawing.Point(200, 172),
                Size = new System.Drawing.Size(150, 23),
                Minimum = 0,
                Maximum = 100,
                DecimalPlaces = 2
            };

            txtNoOfMonths = new NumericUpDown
            {
                Location = new System.Drawing.Point(200, 222),
                Size = new System.Drawing.Size(150, 23),
                Minimum = 1,
                Maximum = 600
            };
            txtNoOfMonths.ValueChanged += UpdateEndDate;

            dtpStartDate = new DateTimePicker
            {
                Location = new System.Drawing.Point(200, 272),
                Size = new System.Drawing.Size(150, 23),
                Format = DateTimePickerFormat.Short
            };
            dtpStartDate.ValueChanged += UpdateEndDate;

            dtpEndDate = new DateTimePicker
            {
                Location = new System.Drawing.Point(200, 322),
                Size = new System.Drawing.Size(150, 23),
                Format = DateTimePickerFormat.Short,
                Enabled = false
            };

            btnSave = new Button
            {
                Text = "Save",
                Location = new System.Drawing.Point(250, 372),
                Size = new System.Drawing.Size(100, 30)
            };
            btnSave.Click += btnSave_Click;

            btnCancel = new Button
            {
                Text = "Cancel",
                Location = new System.Drawing.Point(25, 372),
                Size = new System.Drawing.Size(100, 30),
                DialogResult = DialogResult.Cancel
            };

            // Form settings
            ClientSize = new System.Drawing.Size(400, 450);
            Text = "Loan Application";
            FormBorderStyle = FormBorderStyle.FixedDialog;
            MaximizeBox = false;
            StartPosition = FormStartPosition.CenterParent;

            lblCustomerId.Text = $"Customer ID: {_loan.CustomerID}";

            // Add controls
            Controls.Add(lblCustomerId);
            Controls.Add(lblAccount);
            Controls.Add(lblPrincipalAmount);
            Controls.Add(lblInterest);
            Controls.Add(lblNoOfMonths);
            Controls.Add(lblStartDate);
            Controls.Add(lblEndDate);
            Controls.Add(txtAccount);
            Controls.Add(txtPrincipalAmount);
            Controls.Add(txtInterest);
            Controls.Add(txtNoOfMonths);
            Controls.Add(dtpStartDate);
            Controls.Add(dtpEndDate);
            Controls.Add(btnSave);
            Controls.Add(btnCancel);
        }

        private void PopulateAccountDropdown()
        {
            txtAccount.Items.Clear();
            foreach (int accId in _accountIds)
                txtAccount.Items.Add(accId);

            if (txtAccount.Items.Count > 0)
                txtAccount.SelectedIndex = 0;
        }

        private void UpdateEndDate(object sender, EventArgs e)
        {
            dtpEndDate.Value = dtpStartDate.Value.AddMonths((int)txtNoOfMonths.Value);
        }
    }
}
