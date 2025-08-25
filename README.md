
#  Customer Behavior and Product Performance Analytics  
A **SQL-based Data Warehouse Analytics Project** that provides deep insights into **customer behavior, product performance, and sales trends**. This project helps businesses understand **who their customers are, what products perform best, and how sales evolve over time** — enabling **data-driven decision-making**.  

---

##  Key Features
- 📈 **Customer Analytics**: Track total sales, orders, products purchased, lifespan, recency, and segment customers into **VIP, Regular, New**.  
- 🛍 **Product Analytics**: Measure product performance with total sales, orders, quantity sold, unique customers, and classify into **High, Mid, Low performers**.  
- 📊 **KPI Calculation**: Includes **Average Order Revenue (AOR)**, **Average Monthly Revenue (AMR)**, and recency metrics.  
- 📅 **Trend Analysis**: Sales analysis by **month, year, moving averages**, and **YOY comparisons**.  
- 🏷 **Segmentation**: Group products by cost ranges and customers by spending behavior.  

---

## 🏗Tech Stack
- **SQL (T-SQL / PostgreSQL)**  
- **Data Warehouse Schema** (fact & dimension tables: sales, products, customers)  

---

## 📂 Project Structure
```
📁 data-warehouse-analytics
 ┣ 📜 customer_analysis.sql
 ┣ 📜 product_analysis.sql
 ┣ 📜 datawarehouse_project.sql
 ┗ 📜 README.md
```

---

##  Customer Analysis (SQL Example)

```sql
-- Customer Segmentation Report
with base_query as (
  select f.order_number, f.sales_amount, f.quantity,
         c.customer_key, c.customer_number,
         concat(c.first_name,' ',c.last_name) as customer_name,
         datediff(year,c.birthdate,getdate()) as age,
         f.order_date, f.product_key
  from gold.fact_sales f
  left join gold.dim_customers c on f.customer_key = c.customer_key
  where order_date is not null
),
customer_segmentation as (
  select customer_key, customer_number, customer_name, age,
         count(distinct order_number) as total_orders,
         sum(sales_amount) as total_sales,
         sum(quantity) as total_quantity,
         count(distinct product_key) as total_products,
         max(order_date) as last_order_date,
         datediff(month,min(order_date),max(order_date)) as lifespan
  from base_query
  group by customer_key, customer_number, customer_name, age
)
select *,
  case when lifespan >=12 and total_sales > 5000 then 'VIP'
       when lifespan >=12 and total_sales <= 5000 then 'Regular'
       else 'New' end as customer_segment,
  datediff(month,last_order_date,getdate()) as recency,
  total_sales/total_orders as avg_order_value,
  case when lifespan=0 then total_sales else total_sales/lifespan end as avg_monthly_spend
from customer_segmentation;
```

---

##  Product Analysis (SQL Example)

```sql
-- Product Performance Report
with product_segmentation as (
  select product_key, product_name,
         count(distinct order_number) as total_orders,
         sum(quantity) as total_quantity,
         sum(sales_amount) as total_sales,
         count(distinct customer_key) as total_customers,
         min(order_date) as first_order_date,
         max(order_date) as last_order_date,
         datediff(month,min(order_date),max(order_date)) as lifespan_months
  from gold.fact_sales f
  join gold.dim_products p on f.product_key = p.product_key
  where order_date is not null
  group by product_key, product_name
)
select *,
  case when total_sales > 10000 then 'High-performer'
       when total_sales between 5000 and 10000 then 'Mid-range'
       else 'Low-performer' end as performance_segment,
  datediff(month,last_order_date,getdate()) as recency,
  total_sales*1.0/nullif(total_orders,0) as avg_order_revenue,
  total_sales*1.0/nullif(nullif(lifespan_months,0),0) as avg_monthly_revenue
from product_segmentation;
```

---

##  Sales Trend Analysis (SQL Example)

```sql
-- Monthly Sales with Running Total
select order_date_month, total_sales,
       sum(total_sales) over(order by order_date_month) as running_total_sales
from (
  select datetrunc(month, order_date) as order_date_month,
         sum(sales_amount) as total_sales
  from gold.fact_sales
  where order_date is not null
  group by datetrunc(month, order_date)
) t
order by order_date_month;
```

---

##  How to Use
1. Clone this repo  
   ```bash
   git clone https://github.com/your-username/data-warehouse-analytics.git
   cd data-warehouse-analytics
   ```
2. Load SQL scripts into your **Data Warehouse / SQL environment**.  
3. Run queries inside your **SQL client (SSMS, DBeaver, etc.)**.  

---

## 🌟 Outcomes
- Identify **top customers (VIPs)** and **loyalty segments**.  
- Spot **high-performing products** and categories driving sales.  
- Track **trends in revenue** across time (monthly, yearly, YoY).  
- Compute **key KPIs (AOR, AMR, Recency, Lifespan)** for business insights.  

---

## 🤝 Contributions
Contributions are welcome! Feel free to fork, raise issues, or submit PRs to enhance analytics use cases.  

---

✨ This project is useful for **students, analysts, and professionals** who want to learn **data warehousing, SQL analytics, and business intelligence reporting**.  
