use DataWarehouseAnalytics
/*
===========================================================================================
Customer Report 
===========================================================================================
Purpose :
- This report consolidates key customer metrics and behaviours
Highlights:
 1) Gathers essential fields such as names , ages, and transactions details.
 2) Segments Customers into categories(Vip , regular,new) and age groups
 3) Aggregate customer-level metrics:
   -total sales
   -total orders
   -total quantity purchased 
   - total products
   -lifespan(in months)
4) Calculate valuable KPIs:
 -recency(months since last order)
 -average order value
 -average monthly spend
=====================================================================================
*/
/*
--1) Base query :Retrieve core columns from table
*/
CREATE VIEW gold.report_customers as 
with base_query as (
select f.order_number,f.product_key,f.order_date,f.sales_amount,
f.quantity,c.customer_key,c.customer_number,
CONCAT(c.first_name,' ',c.last_name) as customer_name,
DATEDIFF(YEAR,c.birthdate,GETDATE()) Age
from gold.fact_sales f left join gold.dim_customers c on
c.customer_key=f.customer_key
where order_date is not null) 
,customer_segmentation 
/*
customer Aggregation : Summarizes key metrics at customer level
*/
as 
(select 
customer_key,customer_number,customer_name,Age,
COUNT(distinct order_number) as total_orders,
SUM(sales_amount) as total_sales,
SUM(quantity) as total_quantity,
COUNT(distinct product_key) as total_products,
MAX(order_date) as last_order_date,
DATEDIFF(MONTH,MIN(order_date),max(order_date)) as lifespan
from base_query
group by customer_key,customer_number,customer_name,Age)
,final_report as
(select customer_key,
customer_number,customer_name,Age,
case when Age<20 then 'Under 20'
when Age between 20 and 29 then '20-29'
when Age between 30  and 39 then '30-39'
when Age between 40  and 49 then '40-49'
else 'Above 50' end Age_status,
case when lifespan >=12 and total_sales > 5000  then 'VIP'
 when lifespan >=12 and total_sales <= 5000  then 'Regular'
else 'New' end 'customer_segment',
last_order_date,
-- compute Recency KPI
DATEDIFF(MONTH,last_order_date,GETDATE()) as recency,
total_orders,
total_sales,
total_quantity,
total_products,
lifespan,
--compute average order valuee AVO
case when total_sales=0 then 0
else total_sales/total_orders end as  Avg_order_value,
--compute average monthly spend
case when lifespan=0 then total_sales
else total_sales/lifespan
end as avg_monthly_spend
from customer_segmentation)
select * from final_report










.


























