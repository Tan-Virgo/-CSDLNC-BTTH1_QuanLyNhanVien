using _2020_12_TH1_18120553.DTO;
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace _2020_12_TH1_18120553
{
    public partial class fStatisticDepartment : Form
    {
        public fStatisticDepartment()
        {
            InitializeComponent();

            LoadData();
        }

        void LoadData()
        {
            // Load danh sách các ID Department
            string query = @"SELECT DepartmentID FROM Department";

            DataTable data = DatabaseProvider.Instance.ExecuteQuery(query);

            List<string> ID_department = new List<string>();

            foreach (DataRow item in data.Rows)
            {
                ID_department.Add(item[0].ToString());
            }

            cbDepartment.DataSource = ID_department;

        }

        private void cbDepartment_SelectedIndexChanged(object sender, EventArgs e)
        {
            string query = @"SELECT dbo.Tong_Luong_Phong_Ban (" + cbDepartment.Text + ")";

            DataTable data = DatabaseProvider.Instance.ExecuteQuery(query);

            List<string> Salary = new List<string>();

            foreach (DataRow item in data.Rows)
            {
                Salary.Add(item[0].ToString());
            }

            txtSalary.Text = Salary[0].ToString();
        }
    }
}
