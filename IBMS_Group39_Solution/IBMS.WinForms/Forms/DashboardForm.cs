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
        private Button btnAccountSummary;
        private Button btnViewAuditLogs;
        private Button btnViewArchive;

        private TextBox txtSearch;
        private Button btnSearch;


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
            this.Size = new Size(800, 650);
            this.StartPosition = FormStartPosition.CenterScreen;

            // --- 1. Mode Selection (The Factory Pattern UI) ---
            grpMode = new GroupBox { Text = "Business Logic Mode", Location = new Point(12, 12), Size = new Size(320, 60) };
            rbLinq = new RadioButton { Text = "LINQ / Entity Framework", Location = new Point(15, 25), AutoSize = true };
            rbSP = new RadioButton { Text = "Stored Procedures", Location = new Point(180, 25), AutoSize = true };
            
            rbLinq.CheckedChanged += (s, e) => SetServiceMode();
            rbSP.CheckedChanged += (s, e) => SetServiceMode();

            grpMode.Controls.Add(rbLinq);
            grpMode.Controls.Add(rbSP);

            lblModeStatus = new Label { Text = "Current Mode: LINQ", Location = new Point(350, 35), AutoSize = true, Font = new Font(this.Font, FontStyle.Bold) };

            // --- 2. Action Buttons ---
            btnRefresh = new Button { Text = "Refresh List", Location = new Point(12, 90), Width = 100 };
            btnRefresh.Click += (s, e) => LoadCustomers();

            btnViewArchive = new Button
            {
                Text = "View Archives (Partitioned)",
                Location = new Point(330, 130), // Adjust X/Y to fit next to Audit Logs
                Width = 180,
                BackColor = Color.LightYellow
            };
            btnViewArchive.Click += BtnViewArchive_Click;

            this.Controls.Add(btnViewArchive);

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

            btnEdit = new Button { Text = "Update Customer", Location = new Point(510, 90), Width = 120 };
            btnEdit.Click += (s,e)=> {
                var cust = GetSelectedCustomer();
                if (cust == null) return;

                var customerData = _bankingService.GetCustomer(cust.CustomerID);
                var f = new CustomerCrudForm(_bankingService, customerData);
                if (f.ShowDialog() == DialogResult.OK)
                    LoadCustomers();
            };

            btnDelete = new Button { Text = "Delete Customer", Location = new Point(640, 90), Width = 120 };
            btnDelete.Click += (s,e)=> {
                var cust = GetSelectedCustomer();
                if (cust == null) return;

                if (MessageBox.Show("Delete this customer?", "Confirm", MessageBoxButtons.YesNo) == DialogResult.Yes)
                {
                    _bankingService.DeleteCustomer(cust.CustomerID);
                    LoadCustomers();
                }
            };

            btnAccountSummary = new Button
            {
                Text = "View Account Summary",
                Location = new Point(12, 130),
                Width = 150
            };
            btnAccountSummary.Click += BtnAccountSummary_Click;

            btnViewAuditLogs = new Button
            {
                Text = "View Audit Logs",
                Location = new Point(170, 130),
                Width = 150,
                // Anchor = AnchorStyles.Bottom | AnchorStyles.Left
            };
            btnViewAuditLogs.Click += BtnViewAuditLogs_Click;

            txtSearch = new TextBox
            {
                Location = new Point(470, 130),
                Width = 200
            };
            txtSearch.KeyDown += TxtSearch_KeyDown;

            btnSearch = new Button
            {
                Text = "Search",
                Location = new Point(680, 130),
                Width = 80
            };
            btnSearch.Click += BtnSearch_Click;

            // --- 3. Data Grid ---
            gridCustomers = new DataGridView 
            { 
                Location = new Point(12, 170), 
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
            this.Controls.Add(btnAdd);
            this.Controls.Add(btnEdit);
            this.Controls.Add(btnDelete);
            this.Controls.Add(btnAccountSummary);
            this.Controls.Add(btnViewAuditLogs);
            this.Controls.Add(txtSearch);
            this.Controls.Add(btnSearch);
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

        private Customer360ViewModel? GetSelectedCustomer()
        {
            if (gridCustomers.SelectedRows.Count == 0) return null;
            // return gridCustomers.SelectedRows[0].DataBoundItem as CustomerViewModel;
            return gridCustomers.SelectedRows[0].DataBoundItem as Customer360ViewModel;
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

        private void BtnAccountSummary_Click(object sender, EventArgs e)
        {
            var selectedCustomer = GetSelectedCustomer();
            if (selectedCustomer == null)
            {
                MessageBox.Show("Please select a customer first.", "Selection Required");
                return;
            }

            try
            {
                // Call the new service method to get the summary
                var summary = _bankingService.GetCustomerAccountSummary(selectedCustomer.CustomerID);

                // Show results in a new form or message box
                var summaryForm = new AccountSummaryForm(summary);
                summaryForm.ShowDialog();
            }
            catch (Exception ex)
            {
                MessageBox.Show("Error loading account summary: " + ex.Message, "Error");
            }
        }
        private void BtnViewArchive_Click(object sender, EventArgs e)
        {
            try
            {
                var archivedData = _bankingService.GetArchivedTransactions();

                // Simple popup grid to show data
                Form popup = new Form { Text = "Archived Data (Partitioned Table)", Size = new Size(800, 500) };
                DataGridView grid = new DataGridView { Dock = DockStyle.Fill, DataSource = archivedData, ReadOnly = true, AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill };
                popup.Controls.Add(grid);
                popup.StartPosition = FormStartPosition.CenterParent;
                popup.ShowDialog();
            }
            catch (Exception ex)
            {
                MessageBox.Show("Error loading archives: " + ex.Message);
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
                var stmtForm = new StatementForm(_bankingService, customer);
                stmtForm.ShowDialog();
            }
            catch (Exception ex)
            {
                MessageBox.Show("Error opening statement form: " + ex.Message);
            }
        }

        private void BtnViewAuditLogs_Click(object sender, EventArgs e)
        {
            var auditForm = new AuditLogsForm(_bankingService);
            auditForm.ShowDialog(this);
        }

        private void BtnSearch_Click(object sender, EventArgs e)
        {
            FilterCustomers(txtSearch.Text.Trim());
        }

        private void TxtSearch_KeyDown(object sender, KeyEventArgs e)
        {
            if (e.KeyCode == Keys.Enter)
            {
                e.Handled = true;
                e.SuppressKeyPress = true;
                FilterCustomers(txtSearch.Text.Trim());
            }
        }

        private void FilterCustomers(string fullName)
        {
            try
            {
                List<Customer360ViewModel> filteredCustomers;

                if (string.IsNullOrWhiteSpace(fullName))
                {
                    filteredCustomers = _bankingService.GetAllCustomer360();
                }
                else
                {
                    filteredCustomers = _bankingService.SearchCustomersByName(fullName);
                }

                gridCustomers.DataSource = filteredCustomers;
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Error during search: {ex.Message}", "Error");
            }
        }
    }
}