using System;
using System.Collections.Generic;
using System.Drawing;
using System.Windows.Forms;
using IBMS.Core.Models;

namespace IBMS.WinForms.Forms
{
    public class AccountSummaryForm : Form
    {
        private DataGridView gridSummary;

        public AccountSummaryForm(List<CustomerAccountSummary> summary)
        {
            InitializeComponent();
            gridSummary.DataSource = summary;
        }

        private void InitializeComponent()
        {
            this.Text = "Account Summary";
            this.Size = new Size(700, 400);
            this.StartPosition = FormStartPosition.CenterParent;

            gridSummary = new DataGridView
            {
                Dock = DockStyle.Fill,
                AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill,
                ReadOnly = true,
                SelectionMode = DataGridViewSelectionMode.FullRowSelect,
                MultiSelect = false,
            };

            this.Controls.Add(gridSummary);
        }
    }
}
