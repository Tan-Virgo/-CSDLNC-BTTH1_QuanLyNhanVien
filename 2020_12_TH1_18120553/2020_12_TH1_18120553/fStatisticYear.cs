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
    public partial class fStatisticYear : Form
    {
        public fStatisticYear()
        {
            InitializeComponent();

            LoadData();
        }

        void LoadData()
        {
            // Load danh sách các ID Shift lên combobox
            string query = @"SELECT dbo.Nam_Dau_Co_NV()";

            DataTable data = DatabaseProvider.Instance.ExecuteQuery(query);

            List<string> NamDau = new List<string>();
            foreach (DataRow item in data.Rows)
            {
                NamDau.Add(item[0].ToString());
            }
       
            int nam = int.Parse(NamDau[0]);

            List<int> List_Nam = new List<int>();

            for (int i = nam; i < DateTime.Today.Year; i++)
            {
                List_Nam.Add(i);
            }
            cbYear.DataSource = List_Nam;
        }

        private void cbYear_SelectedValueChanged(object sender, EventArgs e)
        {
            string nam = cbYear.Text;
            string query = @"exec Thong_Ke_Luong_Theo_Nam " + nam;

            DataTable data = DatabaseProvider.Instance.ExecuteQuery(query);

            dgResult.DataSource = data;
        }
    }
}
