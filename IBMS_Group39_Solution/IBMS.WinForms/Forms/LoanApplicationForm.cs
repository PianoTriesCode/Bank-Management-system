using System;
using System.Collections.Generic;
using System.Linq;
using System.Windows.Forms;
using IBMS.Core.Interfaces;
using IBMS.Core.Models;

namespace IBMS.WinForms.Forms
{
    public partial class LoanApplicationForm : Form
    {
        private readonly IBankingService _service;
        private readonly Loan _loan = new Loan();

        private readonly List<int> _accountIds;
        private string _selectedAccountId;

        public LoanApplicationForm(IBankingService service, int customerId, List<int> accountIds, string currentUserName)
        {
            _service = service;
            _loan.CustomerID = customerId;
            _accountIds = accountIds;
            _selectedAccountId = accountIds.First().ToString();
            _loan.AppliedBy = string.IsNullOrWhiteSpace(currentUserName) ? "Admin" : currentUserName;

            InitializeComponent();
            PopulateAccountDropdown();
            UpdateEndDate(null, null);
        }

        private void LoadFields()
        {
            if (int.TryParse(txtAccount.Text, out int accId))
                _loan.AccountID = accId;

            _loan.PrincipalAmount = txtPrincipalAmount.Value;
            _loan.InterestRate = txtInterest.Value;
            _loan.TermMonths = (int)txtNoOfMonths.Value;
            _loan.StartDate = dtpStartDate.Value;
            _loan.EndDate = dtpEndDate.Value;
            _loan.StatusEnum = LoanStatus.Applied;
        }

        private void btnSave_Click(object sender, EventArgs e)
        {
            LoadFields();
            _service.SaveLoanApplication(_loan);

            DialogResult = DialogResult.OK;
        }
    }
}
