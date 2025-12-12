using System;
using System.Windows.Forms;

namespace IBMS.WinForms.Forms
{
    partial class CustomerCrudForm : Form
    {
        private System.ComponentModel.IContainer components = null;

        private System.Windows.Forms.Label lblName;
        private System.Windows.Forms.Label lblEmail;
        private System.Windows.Forms.Label lblPhone;
        private System.Windows.Forms.Label lblAddress;
        private System.Windows.Forms.Label lblDOB;
        private System.Windows.Forms.DateTimePicker dtpDOB;
        private System.Windows.Forms.TextBox txtName;
        private System.Windows.Forms.TextBox txtEmail;
        private System.Windows.Forms.TextBox txtPhone;
        private System.Windows.Forms.TextBox txtAddress;

        private System.Windows.Forms.Button btnSave;
        private System.Windows.Forms.Button btnCancel;

        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
                components.Dispose();
            base.Dispose(disposing);
        }

        private void InitializeComponent()
        {
            this.lblName = new System.Windows.Forms.Label();
            this.lblEmail = new System.Windows.Forms.Label();
            this.lblPhone = new System.Windows.Forms.Label();
            this.lblAddress = new System.Windows.Forms.Label();

            this.txtName = new System.Windows.Forms.TextBox();
            this.txtEmail = new System.Windows.Forms.TextBox();
            this.txtPhone = new System.Windows.Forms.TextBox();
            this.txtAddress = new System.Windows.Forms.TextBox();

            this.btnSave = new System.Windows.Forms.Button();
            this.btnCancel = new System.Windows.Forms.Button();

            this.SuspendLayout();

            // --- Labels ---
            lblName.AutoSize = true;
            lblName.Location = new System.Drawing.Point(25, 25);
            lblName.Text = "Full Name:";

            lblEmail.AutoSize = true;
            lblEmail.Location = new System.Drawing.Point(25, 75);
            lblEmail.Text = "Email:";

            lblPhone.AutoSize = true;
            lblPhone.Location = new System.Drawing.Point(25, 125);
            lblPhone.Text = "Phone:";

            lblAddress.AutoSize = true;
            lblAddress.Location = new System.Drawing.Point(25, 175);
            lblAddress.Text = "Address:";

            lblDOB = new System.Windows.Forms.Label();
            lblDOB.AutoSize = true;
            lblDOB.Location = new System.Drawing.Point(25, 225);
            lblDOB.Text = "Date of Birth:";

            // --- TextBoxes ---
            txtName.Location = new System.Drawing.Point(120, 22);
            txtName.Size = new System.Drawing.Size(250, 23);

            txtEmail.Location = new System.Drawing.Point(120, 72);
            txtEmail.Size = new System.Drawing.Size(250, 23);

            txtPhone.Location = new System.Drawing.Point(120, 122);
            txtPhone.Size = new System.Drawing.Size(250, 23);

            txtAddress.Location = new System.Drawing.Point(120, 172);
            txtAddress.Size = new System.Drawing.Size(250, 23);

            dtpDOB = new System.Windows.Forms.DateTimePicker();
            dtpDOB.Format = System.Windows.Forms.DateTimePickerFormat.Short;
            dtpDOB.Location = new System.Drawing.Point(120, 222);
            dtpDOB.Size = new System.Drawing.Size(250, 23);

            // --- Buttons ---
            btnSave.Text = "Save";
            btnSave.Location = new System.Drawing.Point(120, 270);
            btnSave.Size = new System.Drawing.Size(100, 30);
            btnSave.Click += new System.EventHandler(this.btnSave_Click);

            btnCancel.Text = "Cancel";
            btnCancel.Location = new System.Drawing.Point(270, 270);
            btnCancel.Size = new System.Drawing.Size(100, 30);
            btnCancel.DialogResult = System.Windows.Forms.DialogResult.Cancel;

            // --- Form Settings ---
            this.ClientSize = new System.Drawing.Size(400, 320);
            this.Text = "Customer Editor";
            this.FormBorderStyle = System.Windows.Forms.FormBorderStyle.FixedDialog;
            this.StartPosition = System.Windows.Forms.FormStartPosition.CenterParent;
            this.MaximizeBox = false;

            // Add Controls
            this.Controls.Add(lblName);
            this.Controls.Add(lblEmail);
            this.Controls.Add(lblPhone);
            this.Controls.Add(lblAddress);
            this.Controls.Add(lblDOB);

            this.Controls.Add(txtName);
            this.Controls.Add(txtEmail);
            this.Controls.Add(txtPhone);
            this.Controls.Add(txtAddress);
            this.Controls.Add(dtpDOB);

            this.Controls.Add(btnSave);
            this.Controls.Add(btnCancel);

            this.ResumeLayout(false);
            this.PerformLayout();
        }
    }
}