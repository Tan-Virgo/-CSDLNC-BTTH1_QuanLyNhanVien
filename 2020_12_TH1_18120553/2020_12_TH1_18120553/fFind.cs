using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using _2020_12_TH1_18120553.DTO;

namespace _2020_12_TH1_18120553
{
    public partial class fFind : Form
    {
        public fFind()
        {
            InitializeComponent();
            LoadData();
        }

        void LoadData()
        {
            cbGender.SelectedIndex = 0; // mặc định hiển thị "Nam" trên combobox

            // Load danh sách các ID Department
            string query1 = @"SELECT DepartmentID FROM Department";

            DataTable data1 = DatabaseProvider.Instance.ExecuteQuery(query1);

            List<string> ID_department = new List<string>();
            ID_department.Add("<None>");

            foreach (DataRow item in data1.Rows)
            {
                ID_department.Add(item[0].ToString());
            }

            cbDepartmentID.DataSource = ID_department;

            // Load danh sách các ID Shift lên combobox
            string query2 = @"SELECT ShiftID FROM Shift";

            DataTable data2 = DatabaseProvider.Instance.ExecuteQuery(query2);

            List<string> ID_Shift = new List<string>();
            ID_Shift.Add("<None>");

            foreach (DataRow item in data2.Rows)
            {
                ID_Shift.Add(item[0].ToString());
            }

            cbShiftID.DataSource = ID_Shift;
        }

        private void btnFind_Click(object sender, EventArgs e)
        {
            string GerderID;

            if (cbGender.SelectedIndex == 1) // Nam
                GerderID = "'M'";
            else if (cbGender.SelectedIndex == 2) // Nữ
                GerderID = "'F'";
            else // không xét đk
                GerderID = "null";


            string query = String.Format("exec Find_NV {0}, {1}, {2}",
                    (cbDepartmentID.Text == "<None>") ? 0 : Int16.Parse(cbDepartmentID.Text),
                    (cbShiftID.Text == "<None>") ? 0 : byte.Parse(cbShiftID.Text),
                    GerderID);

            DataTable data = DatabaseProvider.Instance.ExecuteQuery(query);

            dgResultFind.DataSource = data;
        }
    }
}
