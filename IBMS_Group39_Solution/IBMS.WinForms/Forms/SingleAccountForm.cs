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
            bool isEdit = _existing != null;

            var acc = isEdit ? _existing : new Account();

            acc.CustomerID = _customerId;
            acc.AccountTypeID = (int)cmbAccountType.SelectedValue;
            acc.BranchID = (int)cmbBranch.SelectedValue;
            acc.Balance = decimal.TryParse(txtBalance.Text, out var b) ? b : 0;
            acc.Status = cmbStatus.SelectedItem?.ToString() ?? "Active";

            if (isEdit)
                _service.UpdateAccount(acc);
            else
                _service.CreateAccount(acc);

            DialogResult = DialogResult.OK;
        }
    }
}