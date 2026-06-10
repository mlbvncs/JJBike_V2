# JJBike SQL Server - Business Intelligence Analysis

Comprehensive Business Intelligence solution using SQL Server and Power BI for the fictional company JJBike, demonstrating complete data warehouse development from OLTP to OLAP.

---

## 🎯 Quick Overview

**JJBike SQL Server** is a BI project that demonstrates:

- **Data Warehouse Design:** Star Schema with dimensional modeling
- **OLTP Environment:** Transactional database (SQL Server)
- **OLAP Environment:** Analytical database with Slowly Changing Dimensions (SCD Type 2)
- **Power BI:** Interactive dashboards and reports
- **SQL Server Analysis Services (SSAS):** Cube for multidimensional analysis
- **T-SQL:** Complete ETL and analytical queries

**For complete technical documentation, see [Analysis.pdf](./Analysis.pdf)**

---

## 🏗️ Architecture

```
┌──────────────────────────────┐
│   OLAP (Analytical Layer)    │
│   Star Schema + Cube (SSAS)  │
├──────────────────────────────┤
│   T-SQL ETL Transformation   │
├──────────────────────────────┤
│   OLTP (Operational Layer)   │
│   Relational Database        │
└──────────────────────────────┘
```

### Dimensional Model (Star Schema)

**Fact Table:**
- `fact_sales` - Sales metrics at product-per-sale granularity

**Dimensions:**
- `dim_product` - Products with SCD Type 2 versioning
- `dim_seller` - Sellers with SCD Type 2 versioning
- `dim_customer` - Customers with SCD Type 2 versioning
- `dim_time` - Dates with temporal attributes

**Additional:**
- `kpi` - Monthly revenue vs. targets

---

## 🛠 Technologies

| Component | Technology |
|-----------|-----------|
| **Database** | SQL Server 2019+ |
| **IDE/Tools** | SQL Server Management Studio (SSMS) |
| **Scripting** | T-SQL |
| **Visualization** | Power BI Desktop |
| **OLAP** | SQL Server Analysis Services (SSAS) |
| **Version Control** | Git |

---

## 📦 Prerequisites

- **SQL Server 2019+** ([download](https://www.microsoft.com/en-us/sql-server/sql-server-downloads))
  - Express (free), Developer, Standard, or Enterprise editions
- **SQL Server Management Studio (SSMS)** ([download](https://learn.microsoft.com/en-us/sql/ssms/download-sql-server-management-studio-ssms))
- **Power BI Desktop** ([download](https://powerbi.microsoft.com/en-us/desktop/)) - Windows/macOS
- **Visual Studio** (optional, for SSAS cube development)
- **Git** ([download](https://git-scm.com/))

---

## 🚀 Quick Start

### 1. Clone Repository
```bash
git clone https://github.com/mlbvncs/JJBike_SQL_Server.git
cd JJBike_SQL_Server
```

### 2. Create Database
```sql
CREATE DATABASE [JJBike];
GO
```

### 3. Execute T-SQL Scripts

In SSMS, execute scripts in order from `1. Environments/`:

**OLTP (Transactional):**
```bash
1. Scripts_Create_Table_Relational.sql
2. Insert_Into_Customers.sql
3. Insert_Into_Products.sql
4. Insert_Into_Sellers.sql
5. Insert_Into_Sales.sql
6. Insert_Into_SaleItems.sql
```

**OLAP (Analytical):**
```bash
1. Scripts_Create_Table_Dimensional.sql
2. Insert_Into_dim_time.sql
3. Script.sql (ETL with SCD Type 2)
4. KPI.sql
```

### 4. Connect Power BI
1. Open **Power BI Desktop**
2. **Get Data** → **SQL Server**
3. Server: `localhost`
4. Database: `JJBike`
5. Select tables from Dimensional schema
6. Click **Load**

### 5. Build SSAS Cube (Optional)
1. Open **Visual Studio**
2. Create **Analysis Services Project**
3. Create Data Source View with Dimensional tables
4. Build dimensions and fact table
5. Create hierarchies (Geographic, Temporal)
6. Deploy to Analysis Services

---

## 📊 Data Models

### OLTP: Relational Schema

| Table | Purpose |
|-------|---------|
| **sellers** | Seller information |
| **products** | Product catalog |
| **customers** | Customer demographics |
| **sales** | Sale headers |
| **sale_items** | Sale line items (N:M) |

### OLAP: Dimensional Schema

#### **Fact Table: fact_sales**
- Grain: One row per product item per sale
- Metrics: quantity, unit_price, total_price, discount
- Foreign Keys: seller_key, customer_key, product_key, time_key

#### **Dimensions**

| Dimension | Columns | Features |
|-----------|---------|----------|
| **dim_product** | product_key, id_product, product_name, validity dates | SCD Type 2 |
| **dim_seller** | seller_key, id_seller, seller_name, validity dates | SCD Type 2 |
| **dim_customer** | customer_key, id_customer, customer_name, customer_state, customer_gender, customer_status, validity dates | SCD Type 2 |
| **dim_time** | time_key, time_date, time_day, time_month, time_year, time_weekday, time_quarter | Immutable |

#### **KPI Table**
- Columns: month, total_revenue, target
- Purpose: Revenue vs. monthly targets tracking

---

## 📂 Project Structure

```
JJBike_SQL_Server/
├── 1. Environments/
│   ├── 1. OLTP/              # Relational schema scripts
│   └── 2. OLAP/              # Dimensional schema scripts
├── 2. Artifacts/
│   ├── 1. Reports+Dashboards/ # Power BI files
│   └── 2. Cube/              # SSAS cube definition
├── 3. Translations/          # Portuguese documentation
├── Analysis.pdf              # Complete technical documentation
├── LICENSE
└── README.md
```

---

## 🎯 Key Features

✅ **Star Schema** - Optimized for analytical queries  
✅ **SCD Type 2** - Complete historical tracking of dimension changes  
✅ **MERGE + OUTPUT Pattern** - Efficient SQL Server ETL  
✅ **Automated Surrogate Keys** - IDENTITY for all primary keys  
✅ **Time Dimension** - January 1970 to December 2030  
✅ **KPI Tracking** - Monthly revenue vs. targets  
✅ **Power BI Integration** - Interactive dashboards and reports  
✅ **SSAS Cube** - Multidimensional analysis with hierarchies  

---

## 📈 Power BI Artifacts

### Reports
- **Customers Report** - Revenue by state, status, gender, top 5 customers
- **Sellers Report** - Top/worst sellers, month-to-month trends
- **Products Report** - Best/least sellers, discount analysis

### Dashboards
- **Sales Dashboard** - Value, quantity, discount trends
- **KPI Dashboard** - Revenue vs. targets, monthly comparison

### Transformations
- `discount_percent` - Calculated column in fact_sales
- `location_map` - Brazilian state mapping in dim_customer

### Measures
- `measure_target` - Dynamic KPI target filtering
- `measure_total_revenue` - Dynamic revenue filtering

---

## 📊 SSAS Cube

### Dimensions
- `dim_customer`, `dim_product`, `dim_seller`, `dim_time`

### Hierarchies
- **Geographic:** customer_state → customer_name
- **Temporal:** time_year → time_quarter → time_month → time_day

### Measures
- quantity, total_price, discount (aggregated by sum)
- Record count (automatic)

### Deployment
- Compiled and loaded to local Analysis Services instance
- Ready for Excel Pivot Table connections

---

## 💡 Analysis Capabilities

With this data warehouse, answer questions like:

📊 *"Revenue by product type each month?"*
- Dimensions: time_month, dim_product
- Metric: SUM(total_price)

📊 *"Seller performance with customer status changes?"*
- Dimensions: dim_seller, dim_customer (with history)
- Metric: SUM(quantity), SUM(total_price)

📊 *"Geographic distribution of sales by state?"*
- Dimensions: customer_state, customer_name
- Metric: SUM(total_price)

📊 *"KPI achievement: actual vs. target revenue?"*
- Table: kpi
- Comparison: total_revenue vs. target by month

---

## 🎓 Learning Outcomes

✅ SQL Server database design & administration  
✅ T-SQL mastery (CTEs, window functions, MERGE, OUTPUT)  
✅ Star Schema dimensional modeling  
✅ SCD Type 2 implementation with MERGE pattern  
✅ ETL design and optimization  
✅ Power BI dashboard development  
✅ SSAS cube design and deployment  
✅ Business intelligence best practices  

---

## 🤝 Contributing

Contributions welcome! Fork → Branch → Commit → Push → PR

**Ideas:**
- 🔧 T-SQL optimization improvements
- 📝 Additional Power BI templates
- 🐛 Model refinements
- ✨ SSAS cube enhancements

---

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.

**For educational and portfolio purposes.**

---

## 👤 Author

**Malba Vinicius Lopes Santos**  
🐙 GitHub: [@mlbvncs](https://github.com/mlbvncs)  
💼 Focus: Business Intelligence & SQL Server

---

## 📖 Resources

- [SQL Server Documentation](https://learn.microsoft.com/en-us/sql/)
- [Power BI Documentation](https://learn.microsoft.com/en-us/power-bi/)
- [Analysis Services Documentation](https://learn.microsoft.com/en-us/analysis-services/)
- [T-SQL Reference](https://learn.microsoft.com/en-us/sql/t-sql/language-reference)

---

**Last Updated:** June 10, 2026  
**Status:** Complete  
**Type:** Educational Portfolio

⭐ **If you find this useful, please consider starring the repository!**
