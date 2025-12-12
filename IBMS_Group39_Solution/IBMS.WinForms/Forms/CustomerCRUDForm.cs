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
            txtEmail.Text = _customer.Email;
            txtPhone.Text = _customer.Phone;
            txtAddress.Text = _customer.Address;
        }

        private void btnSave_Click(object sender, EventArgs e)
        {
            _customer.FullName = txtName.Text;
            _customer.Email = txtEmail.Text;
            _customer.Phone = txtPhone.Text;
            _customer.Address = txtAddress.Text;

            if (_isEdit)
                _service.UpdateCustomer(_customer);
            else
                _service.CreateCustomer(_customer);

            DialogResult = DialogResult.OK;
        }
    }
}