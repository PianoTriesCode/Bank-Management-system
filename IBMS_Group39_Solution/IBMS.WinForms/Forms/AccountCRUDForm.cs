using System;
using System.Windows.Forms;
using IBMS.Core.Interfaces;
using IBMS.Core.Models;
using IBMS.WinForms.Forms;

public class AccountCrudForm : Form
{
    private readonly IBankingService _service;
    private readonly int _customerId;

    private DataGridView gridAccounts;
    private Button btnAdd;
    private Button btnEdit;
    private Button btnDelete;

    public AccountCrudForm(IBankingService service, int customerId)
    {
        _service = service;
        _customerId = customerId;

        InitializeComponent();
        LoadAccounts();
    }

    private void InitializeComponent()
    {
        this.Text = "Manage Accounts";
        this.Size = new Size(750, 500);
        this.StartPosition = FormStartPosition.CenterParent;

        gridAccounts = new DataGridView
        {
            Dock = DockStyle.Top,
            Height = 350,
            AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill,
            SelectionMode = DataGridViewSelectionMode.FullRowSelect,
            ReadOnly = true,
            MultiSelect = false
        };

        btnAdd = new Button { Text = "Add Account", Location = new Point(20, 370), Width = 150 };
        btnEdit = new Button { Text = "Edit Account", Location = new Point(200, 370), Width = 150 };
        btnDelete = new Button { Text = "Delete Account", Location = new Point(380, 370), Width = 150 };

        btnAdd.Click += BtnAdd_Click;
        btnEdit.Click += BtnEdit_Click;
        btnDelete.Click += BtnDelete_Click;

        this.Controls.Add(gridAccounts);
        this.Controls.Add(btnAdd);
        this.Controls.Add(btnEdit);
        this.Controls.Add(btnDelete);
    }

    private void LoadAccounts()
    {
        var accounts = _service.GetAccountsForCustomer(_customerId);
        gridAccounts.DataSource = accounts;
    }

    private Account? GetSelectedAccount()
    {
        if (gridAccounts.SelectedRows.Count == 0)
            return null;

        return gridAccounts.SelectedRows[0].DataBoundItem as Account;
    }

    private void BtnAdd_Click(object sender, EventArgs e)
    {
        var form = new SingleAccountForm(_service, _customerId);
        if (form.ShowDialog() == DialogResult.OK)
            LoadAccounts();
    }

    private void BtnEdit_Click(object sender, EventArgs e)
    {
        var acc = GetSelectedAccount();
        if (acc == null)
        {
            MessageBox.Show("Please select an account.");
            return;
        }

        var form = new SingleAccountForm(_service, _customerId, acc);
        if (form.ShowDialog() == DialogResult.OK)
            LoadAccounts();
    }

    private void BtnDelete_Click(object sender, EventArgs e)
    {
        var acc = GetSelectedAccount();
        if (acc == null)
        {
            MessageBox.Show("Please select an account.");
            return;
        }

        if (MessageBox.Show("Delete this account?", "Confirm", MessageBoxButtons.YesNo) == DialogResult.Yes)
        {
            _service.DeleteAccount(acc.AccountID);
            LoadAccounts();
        }
    }
}