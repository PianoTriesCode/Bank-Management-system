using System;
using System.Drawing;
using System.Windows.Forms;
using IBMS.Core.Interfaces;
using IBMS.Core.Models;

namespace IBMS.WinForms.Forms
{
    public class StatementForm : Form
    {
        private IBankingService _service;
        private CustomerViewModel _cust;
        private ComboBox cmbAcc;
        private DataGridView grid;

        public StatementForm(IBankingService s, CustomerViewModel c)
        {
            _service = s; 
            _cust = c;
            InitializeComponent();
            LoadAccounts();
        }

        private void InitializeComponent()
        {
            this.Text = $"Statement - {_cust.FullName}";
            this.Size = new Size(600, 400);
            this.StartPosition = FormStartPosition.CenterParent;
            
            var lbl = new Label { Text = "Select Account:", Location = new Point(10, 15), AutoSize = true };
            
            cmbAcc = new ComboBox { Location = new Point(100, 12), Width = 200, DropDownStyle = ComboBoxStyle.DropDownList };
            cmbAcc.SelectedIndexChanged += (s, e) => LoadTransactions();

            grid = new DataGridView { Location = new Point(10, 50), Size = new Size(560, 300), Anchor = AnchorStyles.Top | AnchorStyles.Bottom | AnchorStyles.Left | AnchorStyles.Right, ReadOnly = true, AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill };
            
            this.Controls.Add(lbl);
            this.Controls.Add(cmbAcc);
            this.Controls.Add(grid);
        }

        private void LoadAccounts()
        {
            try
            {
                var accounts = _service.GetAccountsForCustomer(_cust.CustomerID);
                if (accounts.Count == 0)
                {
                    MessageBox.Show("No accounts found.");
                    this.Close();
                    return;
                }
                cmbAcc.DataSource = accounts;
                cmbAcc.DisplayMember = "AccountNumber";
                cmbAcc.ValueMember = "AccountID";
            }
            catch (Exception ex) { MessageBox.Show(ex.Message); }
        }

        private void LoadTransactions()
        {
            if (cmbAcc.SelectedValue == null) return;
            try
            {
                int accId = (int)cmbAcc.SelectedValue;
                grid.DataSource = _service.GetAccountStatement(accId);
            }
            catch (Exception ex) { MessageBox.Show(ex.Message); }
        }
    }
}