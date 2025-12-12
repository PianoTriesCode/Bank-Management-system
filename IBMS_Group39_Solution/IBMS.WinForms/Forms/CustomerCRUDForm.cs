using System;
using System.Windows.Forms;
using IBMS.Core.Interfaces;
using IBMS.Core.Models;

namespace IBMS.WinForms.Forms
{
    public partial class CustomerCrudForm : Form
    {
        private readonly IBankingService _service;
        private readonly Customer _customer;
        private readonly bool _isEdit;

        public CustomerCrudForm(IBankingService service, Customer? customer = null)
        {
            _service = service;
            _customer = customer ?? new Customer();
            _isEdit = customer != null;

            InitializeComponent();
            LoadFields();
        }

        private void LoadFields()
        {
            if (!_isEdit) return;

            txtName.Text = _customer.FullName;
            dtpDOB.Value = _customer.DOB != default(DateTime) ? _customer.DOB : DateTime.Today;
            txtEmail.Text = _customer.Email;
            txtPhone.Text = _customer.Phone;
            txtAddress.Text = _customer.Address;
        }

       private void btnSave_Click(object sender, EventArgs e)
        {
            if (string.IsNullOrWhiteSpace(txtName.Text))
            {
                MessageBox.Show("Full Name is required.", "Validation Error", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                txtName.Focus();
                return;
            }
            if (string.IsNullOrWhiteSpace(txtEmail.Text) || !txtEmail.Text.Contains("@") || !txtEmail.Text.Contains("."))
            {
                MessageBox.Show("Please enter a valid Email address.", "Validation Error", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                txtEmail.Focus();
                return;
            }

            if (string.IsNullOrWhiteSpace(txtPhone.Text) || txtPhone.Text.Length < 7)
            {
                MessageBox.Show("Please enter a valid Phone number.", "Validation Error", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                txtPhone.Focus();
                return;
            }

            if (dtpDOB.Value > DateTime.Today)
            {
                MessageBox.Show("Date of Birth cannot be in the future.", "Validation Error", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            _customer.FullName = txtName.Text.Trim();
            _customer.DOB = dtpDOB.Value;
            _customer.Email = txtEmail.Text.Trim();
            _customer.Phone = txtPhone.Text.Trim();
            _customer.Address = txtAddress.Text.Trim();

            try
            {
                if (_isEdit)
                    _service.UpdateCustomer(_customer);
                else
                    _service.CreateCustomer(_customer);

                DialogResult = DialogResult.OK;
            }
            catch (Exception ex)
            {
                MessageBox.Show("Error saving customer: " + ex.Message);
            }
        }
    }
}