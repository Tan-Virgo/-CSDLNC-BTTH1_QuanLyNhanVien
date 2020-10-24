using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Data.SqlClient;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using _2020_12_TH1_18120553.DTO;



namespace _2020_12_TH1_18120553
{
    public partial class fManage : Form
    {
        public fManage()
        {
            InitializeComponent();

            LoadData();
        }



        private void nhânViênTheoĐiềuKiệnToolStripMenuItem_Click(object sender, EventArgs e)
        {
            fFind f = new fFind();
            f.ShowDialog();
        }

        private void lươngCủaMỗiNhânViênTheoNămToolStripMenuItem_Click(object sender, EventArgs e)
        {
            fStatisticYear f = new fStatisticYear();
            f.ShowDialog();
        }

        private void tổngLươngTheoPhòngBanToolStripMenuItem_Click(object sender, EventArgs e)
        {
            fStatisticDepartment f = new fStatisticDepartment();
            f.ShowDialog();
        }

        private void fManage_FormClosing(object sender, FormClosingEventArgs e)
        {
            if (MessageBox.Show("Bạn muốn thoát chương trình?", "Thông báo", MessageBoxButtons.OKCancel) != System.Windows.Forms.DialogResult.OK)
            {
                e.Cancel = true;
            }
        }



        void LoadData()
        {
            cbPayFrequency.SelectedIndex = 0; //  1 - trả theo 1 tháng

            // Load danh sách các ID lên combobox
            string query = @"SELECT BusinessEntityID FROM Employee";

            DataTable data = DatabaseProvider.Instance.ExecuteQuery(query);

            List<string> ID = new List<string>();

            foreach (DataRow item in data.Rows)
            {
                ID.Add(item[0].ToString());
            }

            cbID.DataSource = ID;
        }


        // Hàm gọi cập nhật lương dưới server
        bool Cap_Nhat_Luong(int BusinessEntityID, string RateChangeDate, decimal Rate, Int16 PayFrequency)
        {
            string query = string.Format("exec Update_Luong {0}, '{1}', {2}, {3}", BusinessEntityID, RateChangeDate, Rate, PayFrequency);
            int result = DatabaseProvider.Instance.ExecuteNonQuery(query);

            return result > 0;
        }

        // cập nhật lương nhân viên = thêm một lịch sử lương vào bảng EmployeePayHistory
        private void btnUpdate_Click(object sender, EventArgs e)
        {
            int BusinessEntityID = int.Parse(cbID.Text);
            string Ngay = dpChangeDate.Value.Day.ToString();
            string Thang = dpChangeDate.Value.Month.ToString();
            string Nam = dpChangeDate.Value.Year.ToString();
            string RateChangeDate = Thang + "/" + Ngay + "/" + Nam;
            decimal Rate = (decimal)nuRate.Value;
            Int16 PayFrequency;
            if (cbPayFrequency.SelectedIndex == 0)
                PayFrequency = 1;
            else
                PayFrequency = 2;

            try
            {
                if (Cap_Nhat_Luong(BusinessEntityID, RateChangeDate, Rate, PayFrequency))
                {
                    MessageBox.Show("Bạn vừa cập nhật thành công lương của nhân viên có mã là " + BusinessEntityID, "SUCCESS", MessageBoxButtons.OK, MessageBoxIcon.Information);

                    // đặt lại mặc định các combobox,...
                    cbID.SelectedIndex = 0;
                    dpChangeDate.Value = DateTime.Today;
                    nuRate.Value = 0;
                    cbPayFrequency.SelectedIndex = 0;

                }
                else
                {
                    MessageBox.Show("Lỗi khi cập nhật lương!", "ERROR", MessageBoxButtons.OK, MessageBoxIcon.Error);
                }
            }
            catch
            {
                MessageBox.Show("Ngày RateChangeDate phải lớn hơn ngày cập nhật lương gần đây nhất!",
                    "ERROR", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
       
        }

        
    }
}
