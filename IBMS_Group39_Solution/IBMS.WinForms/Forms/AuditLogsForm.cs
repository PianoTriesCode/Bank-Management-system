using System;
using System.Collections.Generic;
using System.Drawing;
using System.Windows.Forms;
using IBMS.Core.Interfaces;
using IBMS.Core.Models;

public class AuditLogsForm : Form
{
    private readonly IBankingService _service;
    private DataGridView dgvLogs;

    public AuditLogsForm(IBankingService service)
    {
        _service = service;
        InitializeComponent();
        LoadAuditLogs();
    }

    private void InitializeComponent()
    {
        this.Text = "Audit Logs";
        this.Size = new Size(800, 600);
        this.StartPosition = FormStartPosition.CenterParent;

        dgvLogs = new DataGridView
        {
            Dock = DockStyle.Fill,
            ReadOnly = true,
            AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill,
            AllowUserToAddRows = false,
            AllowUserToDeleteRows = false,
        };

        this.Controls.Add(dgvLogs);
    }

    private void LoadAuditLogs()
    {
        try
        {
            var logs = _service.GetAuditLogs();
            dgvLogs.DataSource = logs;
        }
        catch (Exception ex)
        {
            MessageBox.Show($"Error loading audit logs: {ex.Message}");
        }
    }
}