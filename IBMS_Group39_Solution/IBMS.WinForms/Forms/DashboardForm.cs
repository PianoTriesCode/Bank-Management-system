using System;
using System.Windows.Forms;
using System.Drawing;
using System.Collections.Generic;
using IBMS.Core.Models;
using IBMS.Core.Interfaces;
using IBMS.Data;

namespace IBMS.WinForms.Forms
{
    public class DashboardForm : Form
    {
        private Employee _currentUser;
        private IBankingService _bankingService;
        
        // UI Controls
        private GroupBox grpMode;
        private RadioButton rbLinq;
        private RadioButton rbSP;
        private Label lblModeStatus;
        
        private DataGridView gridCustomers;
        private Button btnRefresh;
        private Button btnTransfer;
        private Button btnStatement;
        private Button btnAdd;
        private Button btnEdit;
        private Button btnDelete;


        public DashboardForm(Employee user)
        {
            _currentUser = user;
            InitializeComponent();
            InitializeLogic();
        }

        private void InitializeLogic()
        {
            // Default to LINQ on startup
            rbLinq.Checked = true;
            SetServiceMode(); 
            LoadCustomers();
        }

        private void InitializeComponent()
        {
            this.Text = $"IBMS Dashboard - Logged in as: {_currentUser.FullName}";
            this.Size = new Size(800, 600);
            this.StartPosition = FormStartPosition.CenterScreen;

            // --- 1. Mode Selection (The Factory Pattern UI) ---
            grpMode = new GroupBox { Text = "Business Logic Mode", Location = new Point(12, 12), Size = new Size(300, 60) };
            rbLinq = new RadioButton { Text = "LINQ / Entity Framework", Location = new Point(15, 25), AutoSize = true };
            rbSP = new RadioButton { Text = "Stored Procedures", Location = new Point(160, 25), AutoSize = true };
            
            rbLinq.CheckedChanged += (s, e) => SetServiceMode();
            rbSP.CheckedChanged += (s, e) => SetServiceMode();

            grpMode.Controls.Add(rbLinq);
            grpMode.Controls.Add(rbSP);

            lblModeStatus = new Label { Text = "Current Mode: LINQ", Location = new Point(330, 35), AutoSize = true, Font = new Font(this.Font, FontStyle.Bold) };

            // --- 2. Action Buttons ---
            btnRefresh = new Button { Text = "Refresh List", Location = new Point(12, 90), Width = 100 };
            btnRefresh.Click += (s, e) => LoadCustomers();

            btnTransfer = new Button { Text = "Transfer Funds", Location = new Point(120, 90), Width = 120, BackColor = Color.LightBlue };
            btnTransfer.Click += BtnTransfer_Click;

            btnStatement = new Button { Text = "View Statement", Location = new Point(250, 90), Width = 120 };
            btnStatement.Click += BtnStatement_Click;

            btnAdd = new Button { Text = "Add Customer", Location = new Point(380, 90), Width = 120 };
            btnAdd.Click += (s,e)=> {
                var f = new CustomerCrudForm(_bankingService);
                if (f.ShowDialog() == DialogResult.OK)
                    LoadCustomers();
            };

            btnAdd = new Button { Text = "Update Customer", Location = new Point(510, 90), Width = 120 };
            btnEdit.Click += (s,e)=> {
                var cust = GetSelectedCustomer();
                if (cust == null) return;

                var customerData = _bankingService.GetCustomerById(cust.CustomerID);
                var f = new CustomerCrudForm(_bankingService, customerData);
                if (f.ShowDialog() == DialogResult.OK)
                    LoadCustomers();
            };

            btnAdd = new Button { Text = "Delete Customer", Location = new Point(640, 90), Width = 120 };
            btnDelete.Click += (s,e)=> {
                var cust = GetSelectedCustomer();
                if (cust == null) return;

                if (MessageBox.Show("Delete this customer?", "Confirm", MessageBoxButtons.YesNo) == DialogResult.Yes)
                {
                    _bankingService.DeleteCustomer(cust.CustomerID);
                    LoadCustomers();
                }
            };

            // --- 3. Data Grid ---
            gridCustomers = new DataGridView 
            { 
                Location = new Point(12, 130), 
                Size = new Size(760, 420),
                Anchor = AnchorStyles.Top | AnchorStyles.Bottom | AnchorStyles.Left | AnchorStyles.Right,
                AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill,
                SelectionMode = DataGridViewSelectionMode.FullRowSelect,
                MultiSelect = false,
                ReadOnly = true
            };

            this.Controls.Add(grpMode);
            this.Controls.Add(lblModeStatus);
            this.Controls.Add(btnRefresh);
            this.Controls.Add(btnTransfer);
            this.Controls.Add(btnStatement);
            this.Controls.Add(gridCustomers);
        }

        private void SetServiceMode()
        {
            if (rbLinq.Checked)
            {
                _bankingService = ServiceFactory.GetService(ServiceType.LINQ);
                lblModeStatus.Text = "Current Mode: LINQ (C# Logic)";
                lblModeStatus.ForeColor = Color.Blue;
            }
            else
            {
                _bankingService = ServiceFactory.GetService(ServiceType.StoredProcedure);
                lblModeStatus.Text = "Current Mode: Stored Procedures (SQL Logic)";
                lblModeStatus.ForeColor = Color.DarkGreen;
            }
        }

        private void LoadCustomers()
        {
            try
            {
                // var customers = _bankingService.GetAllCustomers();
                var customers = _bankingService.GetAllCustomer360();
                gridCustomers.DataSource = customers;
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Error loading data: {ex.Message}", "Error");
            }
        }

        private CustomerViewModel? GetSelectedCustomer()
        {
            if (gridCustomers.SelectedRows.Count == 0) return null;
            return gridCustomers.SelectedRows[0].DataBoundItem as CustomerViewModel;
        }

        private void BtnTransfer_Click(object sender, EventArgs e)
        {
            var customer = GetSelectedCustomer();
            if (customer == null)
            {
                MessageBox.Show("Please select a customer first.", "Selection Required");
                return;
            }

            try
            {
                var transferForm = new TransferForm(_bankingService, _currentUser, customer);
                transferForm.ShowDialog();
                LoadCustomers(); 
            }
            catch (Exception ex)
            {
                MessageBox.Show("Error opening transfer form: " + ex.Message);
            }
        }

        private void BtnStatement_Click(object sender, EventArgs e)
        {
            var customer = GetSelectedCustomer();
            if (customer == null)
            {
                MessageBox.Show("Please select a customer first.");
                return;
            }

            try
            {
                // Ensure StatementForm is instantiated correctly
                var stmtForm = new StatementForm(_bankingService, customer);
                stmtForm.ShowDialog();
            }
            catch (Exception ex)
            {
                MessageBox.Show("Error opening statement form: " + ex.Message);
            }
        }
    }
}