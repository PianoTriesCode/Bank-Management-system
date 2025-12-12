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

        // private void LoadAccounts()
        // {
        //     try
        //     {
        //         var accounts = _service.GetAccountsForCustomer(_cust.CustomerID);
        //         if (accounts.Count == 0)
        //         {
        //             MessageBox.Show("No accounts found.");
        //             this.Close();
        //             return;
        //         }
        //         cmbAcc.DataSource = accounts;
        //         cmbAcc.DisplayMember = "AccountNumber";
        //         cmbAcc.ValueMember = "AccountID";
        //     }
        //     catch (Exception ex) { MessageBox.Show(ex.Message); }
        // }

        private void LoadAccounts()
        {
            try
            {
                var accounts = _service.GetAccountsForCustomer(_cust.CustomerID);
                if (accounts == null || accounts.Count == 0)
                {
                    MessageBox.Show("No accounts found.");
                    this.Close();
                    return;
                }

                // Use a BindingSource to avoid odd binding-state issues
                var bs = new BindingSource();
                bs.DataSource = accounts;

                // Set DisplayMember and ValueMember BEFORE assigning DataSource to the ComboBox
                cmbAcc.DisplayMember = "AccountNumber";
                cmbAcc.ValueMember = "AccountID";

                // Clear any previous binding then assign the BindingSource
                cmbAcc.DataSource = null;
                cmbAcc.DataSource = bs;

                // Force refresh
                cmbAcc.Refresh();
            }
            catch (Exception ex)
            {
                MessageBox.Show("LoadAccounts error: " + ex.Message);
            }
        }

        private void LoadTransactions()
        {
            if (cmbAcc.SelectedValue == null) return;

            try
            {
                object sel = cmbAcc.SelectedValue;

                // Diagnostic: show the runtime type if it isn't an int or Account
                if (sel is int accIdInt)
                {
                    grid.DataSource = _service.GetAccountStatement(accIdInt);
                    return;
                }

                if (sel is long accIdLong) // in case it's long/BigInt
                {
                    grid.DataSource = _service.GetAccountStatement(Convert.ToInt32(accIdLong));
                    return;
                }

                if (sel is Account accObj)
                {
                    grid.DataSource = _service.GetAccountStatement(accObj.AccountID);
                    return;
                }

                // Final attempt: try to convert it (handles boxed numeric types or string numbers)
                try
                {
                    int accId = Convert.ToInt32(sel);
                    grid.DataSource = _service.GetAccountStatement(accId);
                    return;
                }
                catch
                {
                    MessageBox.Show("Unexpected SelectedValue type: " + (sel?.GetType().FullName ?? "null")
                                    + "\nValue.ToString(): " + (sel?.ToString() ?? "null"));
                    return;
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show("LoadTransactions error: " + ex.Message);
            }
        }

        // private void LoadTransactions()
        // {
        //     if (cmbAcc.SelectedValue == null) return;
        //     try
        //     {
        //         int accId = (int)cmbAcc.SelectedValue;
        //         grid.DataSource = _service.GetAccountStatement(accId);
        //     }
        //     catch (Exception ex) { MessageBox.Show(ex.Message); }
        // }
    }
}