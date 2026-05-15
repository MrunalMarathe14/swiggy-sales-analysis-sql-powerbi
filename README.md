# 🍽️ Swiggy Sales Analysis — SQL Server + Power BI

![SQL Server](https://img.shields.io/badge/SQL_Server-T--SQL-blue?style=flat-square&logo=microsoftsqlserver&logoColor=white)
![Power BI](https://img.shields.io/badge/Power_BI-Dashboard-yellow?style=flat-square&logo=powerbi&logoColor=black)
![Schema](https://img.shields.io/badge/Schema-Star_Schema-orange?style=flat-square)
![Status](https://img.shields.io/badge/Status-Complete-brightgreen?style=flat-square)

An end-to-end data analysis project on Swiggy food delivery data — covering raw data ingestion, cleaning, dimensional modelling (Star Schema), business KPI development in SQL, and an interactive Power BI dashboard.

---

## 📁 Repository Structure

```
swiggy-sales-analysis-sql-powerbi/
│
├── data/
│   └── swiggy_data.csv                  # Raw dataset
│
├── sql/
│   └── swiggy_analysis.sql              # Full SQL script (cleaning → schema → KPIs)
│
├── powerbi/
│   └── swiggy_dashboard.pbix            # Power BI dashboard file
│
├── screenshots/
│   ├── 01_null_check.png
│   ├── 02_duplicate_detection.png
│   ├── 03_star_schema_tables.png
│   ├── 04_fact_table_preview.png
│   ├── 05_kpi_total_orders.png
│   ├── 06_kpi_total_revenue.png
│   ├── 07_monthly_orders.png
│   ├── 08_top_cities.png
│   ├── 09_top_restaurants.png
│   ├── 10_cuisine_performance.png
│   ├── 11_spend_buckets.png
│   ├── 12_ratings_analysis.png
│   └── 13_powerbi_dashboard.png
│
└── README.md
```

---

## 🎯 Project Objectives

- Validate and clean raw Swiggy order data using T-SQL
- Design a **Star Schema** with 1 fact table and 5 dimension tables
- Develop business KPIs across time, location, restaurant, cuisine, and customer spend
- Visualize findings in an interactive **Power BI dashboard**

---

## 🗃️ Dataset Overview

| Column | Description |
|---|---|
| `State` | Indian state of the order |
| `City` | City of delivery |
| `Order_Date` | Date of order placement |
| `Restaurant_Name` | Name of the restaurant |
| `Location` | Sub-area / locality |
| `Category` | Cuisine type |
| `Dish_Name` | Specific dish ordered |
| `Price_INR` | Order value in Indian Rupees |
| `Rating` | Customer rating (1–5 scale) |
| `Rating_Count` | Number of ratings for the dish |

---

## 🏗️ Star Schema Design

```
                    ┌─────────────┐
                    │  dim_date   │
                    └──────┬──────┘
                           │
┌──────────────┐    ┌──────┴──────────────┐    ┌────────────────┐
│ dim_location │────│  fact_swiggy_orders │────│ dim_restaurant │
└──────────────┘    └──────┬──────────────┘    └────────────────┘
                           │
              ┌────────────┴────────────┐
              │                         │
       ┌──────┴──────┐          ┌───────┴──────┐
       │ dim_category│          │   dim_dish   │
       └─────────────┘          └──────────────┘
```

**Fact Table:** `fact_swiggy_orders`  
Stores `price_INR`, `rating`, `rating_count` with foreign keys linking to all 5 dimension tables.

**Dimension Tables:**

| Table | Key Columns |
|---|---|
| `dim_date` | year, month, month_name, quarter, day, week |
| `dim_location` | state, city, location |
| `dim_restaurant` | restaurant_name |
| `dim_category` | category |
| `dim_dish` | dish_name |

---

## 🔧 SQL Pipeline

### Phase 1 — Data Cleaning & Validation
- NULL checks across all 10 columns
- Empty/blank string detection
- Duplicate detection using `GROUP BY` + `HAVING COUNT(*) > 1`
- Deduplication via `ROW_NUMBER()` CTE with `DELETE`

### Phase 2 — Dimensional Modelling
- Created dimension tables with `IDENTITY(1,1)` surrogate keys
- Built fact table with foreign key constraints
- Populated dimensions using `INSERT INTO ... SELECT DISTINCT`
- Loaded fact table using multi-table JOINs on natural keys

### Phase 3 — KPI & Business Analysis

| Domain | Analysis |
|---|---|
| **Time** | Monthly, quarterly, yearly orders & revenue; day-of-week patterns |
| **Location** | Top 10 cities by volume; state revenue share %; top sub-localities |
| **Restaurant** | Top 10 by orders & revenue; high-rated vs low-rated restaurant flags |
| **Cuisine & Dishes** | Category performance; most ordered dishes; cuisine × rating matrix |
| **Customer Spend** | Spend bucket distribution (Under ₹100 → ₹500+); % breakdown |
| **Ratings** | Distribution by floor rating; avg rating by category & city |
| **Cross-Dimensional** | Best city + cuisine combos; top revenue dish per city (window functions) |

---

## 📊 SQL Highlights

**Revenue Contribution by State (Window Function)**
```sql
SELECT 
    l.state,
    ROUND(SUM(f.price_INR), 2) AS total_revenue,
    ROUND(
        SUM(f.price_INR) * 100.0 / SUM(SUM(f.price_INR)) OVER (), 
        2
    ) AS revenue_pct
FROM fact_swiggy_orders f
JOIN dim_location l ON f.location_id = l.location_id
GROUP BY l.state
ORDER BY total_revenue DESC;
```

**Highest Revenue Dish Per City (ROW_NUMBER)**
```sql
WITH city_dish_revenue AS (
    SELECT 
        l.city, d.dish_name,
        SUM(f.price_INR) AS total_revenue,
        ROW_NUMBER() OVER (
            PARTITION BY l.city ORDER BY SUM(f.price_INR) DESC
        ) AS rn
    FROM fact_swiggy_orders f
    JOIN dim_location l ON f.location_id = l.location_id
    JOIN dim_dish d ON f.dish_id = d.dish_id
    GROUP BY l.city, d.dish_name
)
SELECT city, dish_name, ROUND(total_revenue, 2) AS total_revenue
FROM city_dish_revenue
WHERE rn = 1;
```

---

## 📊 Power BI Dashboard

The Power BI report connects directly to the star schema and includes:

- **Overview** — Total orders, revenue, avg price, avg rating KPI cards
- **Time Trends** — Monthly/quarterly revenue line charts; day-of-week heatmap
- **Location Analysis** — State revenue map; top cities bar chart
- **Restaurant & Cuisine** — Leaderboard tables; category performance matrix
- **Customer Insights** — Spend bucket donut chart; rating distribution

> 📷 See `screenshots/13_powerbi_dashboard.png` for a full preview.

---

## 💡 Key Insights

- **Day-of-week ordering peaks** identified — highest volume concentrated around weekends
- **State-level GMV concentration** — top states drive a disproportionate share of revenue
- **Low-rated, high-volume restaurants** flagged as quality intervention candidates
- **₹100–₹299 spend range** accounts for the bulk of order volume
- **City × cuisine combos** reveal highest-performing pairings for targeted promotions

---

## 🛠️ Tools & Technologies

| Tool | Purpose |
|---|---|
| **SQL Server (T-SQL)** | Data cleaning, star schema design, KPI queries |
| **SSMS** | Query execution and schema management |
| **Power BI Desktop** | Interactive dashboards and data visualization |
| **Kimball Star Schema** | Dimensional modelling methodology |

---

## 🚀 How to Reproduce

1. Import `data/swiggy_data.csv` into SQL Server as table `swiggy_data`
2. Open `sql/swiggy_analysis.sql` in SSMS and run sections in order:
   - Data Cleaning → Dimension Tables → Fact Table → Insert Data → KPI Queries
3. Open `powerbi/swiggy_dashboard.pbix` in Power BI Desktop
4. Update the data source connection to point to your SQL Server instance

---

## 👤 Author

**Mrunal Marathe** | B.Tech Computer Science, MIT-WPU Pune (2026)  
Aspiring Data Analyst | SQL · Power BI · Python · PySpark

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Connect-blue?style=flat-square&logo=linkedin)](https://www.linkedin.com/in/mrunalmarathe1404/)
[![GitHub](https://img.shields.io/badge/GitHub-Follow-black?style=flat-square&logo=github)](https://github.com/MrunalMarathe14)
---

*Part of a data analytics portfolio demonstrating end-to-end SQL proficiency: data engineering, dimensional modelling, and business intelligence.*