using System;
using System.Collections.Generic;
using System.Drawing;
using System.Windows.Forms;
using IBMS.Core.Models;
using IBMS.Core.Interfaces;

namespace IBMS.WinForms.Forms
{
    public class LoansListForm : Form
    {
        private DataGridView gridLoans;
        private IBankingService _service;

        public LoansListForm(List<Loan> loans, IBankingService service)
        {
            _service = service;

            this.Text = "All Loans";
            this.Size = new Size(900, 500);
            this.StartPosition = FormStartPosition.CenterParent;

            gridLoans = new DataGridView
            {
                Dock = DockStyle.Fill,
                ReadOnly = false,
                AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill,
                SelectionMode = DataGridViewSelectionMode.FullRowSelect,
                DataSource = loans,
                AllowUserToAddRows = false,
                EnableHeadersVisualStyles = false
            };

            // Hide StatusEnum column
            if (gridLoans.Columns.Contains("StatusEnum"))
                gridLoans.Columns["StatusEnum"].Visible = false;

            // Action button column
            DataGridViewButtonColumn actionCol = new DataGridViewButtonColumn
            {
                HeaderText = "Action",
                Name = "Action",
                Text = "Approve / Reject",
                UseColumnTextForButtonValue = true,
                AutoSizeMode = DataGridViewAutoSizeColumnMode.None,
                Width = 140,
                Frozen = true // pins column to the left
            };

            actionCol.DefaultCellStyle.BackColor = Color.LightBlue;
            actionCol.DefaultCellStyle.ForeColor = Color.DarkBlue;
            actionCol.DefaultCellStyle.Font = new Font("Segoe UI", 9, FontStyle.Bold);

            gridLoans.Columns.Insert(0, actionCol);

            gridLoans.CellFormatting += GridLoans_CellFormatting;
            gridLoans.CellContentClick += GridLoans_CellContentClick;

            this.Controls.Add(gridLoans);
        }

        private void GridLoans_CellFormatting(object sender, DataGridViewCellFormattingEventArgs e)
        {
            if (gridLoans.Columns[e.ColumnIndex].Name == "Action")
            {
                var loan = gridLoans.Rows[e.RowIndex].DataBoundItem as Loan;
                if (loan == null) return;

                e.Value = (loan.StatusEnum == LoanStatus.Applied) ? "Approve / Reject" : "Only for Applied Loan";
            }
        }

        private void GridLoans_CellContentClick(object sender, DataGridViewCellEventArgs e)
        {
            if (gridLoans.Columns[e.ColumnIndex].Name != "Action")
                return;

            var loan = gridLoans.Rows[e.RowIndex].DataBoundItem as Loan;
            if (loan == null) return;

            if (loan.StatusEnum != LoanStatus.Applied)
            {
                MessageBox.Show("Only applied loans can be updated.", "Info", MessageBoxButtons.OK, MessageBoxIcon.Information);
                return;
            }

            var choice = MessageBox.Show(
                "Approve this loan?\n\nYes = Approve\nNo = Reject",
                "Loan Decision",
                MessageBoxButtons.YesNoCancel,
                MessageBoxIcon.Question);

            if (choice == DialogResult.Cancel)
                return;

            var newStatus = (choice == DialogResult.Yes) ? LoanStatus.Approved : LoanStatus.Rejected;

            try
            {
                _service.UpdateLoanApplication(loan.LoanID, newStatus);

                MessageBox.Show("Loan status updated successfully.", "Success", MessageBoxButtons.OK, MessageBoxIcon.Information);

                // Update the underlying object and refresh the grid
                loan.StatusEnum = newStatus;
                gridLoans.Refresh();
            }
            catch (Exception ex)
            {
                MessageBox.Show("Error updating loan: " + ex.Message, "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }
    }
}
