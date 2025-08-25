use DataWarehouseAnalytics
select * from gold.fact_sales
--select * from gold.dim_customers
--select * from gold.dim_products
-- question calculate TotalSales per month and running total of sales over time
-- by the month
select order_date_month,total_sales,
SUM(total_sales) over(partition  by order_date_month order by order_date_month ) as running_total_sum
--window_func
from
(select 
datetrunc(month,order_date) as order_date_month ,
SUM(sales_amount) as total_sales
from gold.fact_sales
where order_date is not null
group by datetrunc(month,order_date))t

-- BY YEAR
-- by the month
select order_date_month,total_sales,
SUM(total_sales) over( order by order_date_month ) as running_total_sum
--window_func
from
(select 
datetrunc(YEAR,order_date) as order_date_month ,
SUM(sales_amount) as total_sales
from gold.fact_sales
where order_date is not null
group by datetrunc(YEAR,order_date))t
--MOVING AVERAGE PRICE
select order_date_month,total_sales,
SUM(total_sales) over( order by order_date_month ) as running_total_sum,
avg(average_sales) over( order by order_date_month ) as running_average
--window_func
from
(select 
datetrunc(YEAR,order_date) as order_date_month ,
SUM(sales_amount) as total_sales,
AVG(sales_amount) as average_sales
from gold.fact_sales
where order_date is not null
group by datetrunc(YEAR,order_date))t

/*analyze the yearly performance of products by compairing each products sales to both its average 
sales performance & previous year sales */
-- yearly performance 
with cte_year as(
select year(f.order_date) as order_year,p.product_name,
SUM(f.sales_amount) as current_sales
from gold.fact_sales f left join gold.dim_products p
on f.product_key=p.product_key 
where f.order_date is not null
group by year(f.order_date),p.product_name)
--average sales
select order_year,product_name,current_sales,
AVG(current_sales) over(partition by product_name) as avg_sales,
current_sales- AVG(current_sales) over(partition by product_name) as sales_averagediff,
case when current_sales- AVG(current_sales) over(partition by product_name) >0 then 'Above_avg'
 when current_sales- AVG(current_sales) over(partition by product_name) <0 then 'Below_avg'
else 'Avg' end 'Sales_status',
-- year-over-year analysis
LAG(current_sales,1,current_sales) over(partition by product_name order by order_year ) as py_year,
current_sales- LAG(current_sales,1,current_sales) over(partition by product_name order by order_year ) as py_diff,
case when current_sales- LAG(current_sales,1,current_sales) over(partition by product_name order by order_year )>0 then 'Increase'
 when current_sales- LAG(current_sales,1,current_sales) over(partition by product_name order by order_year )<0 then 'Decreased'
else 'No change' end 'Year_status'
from cte_year
order by product_name,order_year
/*analyze the  performance of products by compairing each products sales to both its average 
sales performance & previous year sales */
with cte_monthly as (
select MONTH(f.order_date) order_month,p.product_name,sum(f.sales_amount) as current_sales
from gold.fact_sales f left join gold.dim_products p
on f.product_key=p.product_key
where order_date is not null
group by MONTH(f.order_date),p.product_name)
--order by datename(MONTH,f.order_date),p.product_name
select order_month,product_name,current_sales,
-- avgerage sales
AVG(current_sales) over(partition by product_name) as avg_monthly_sales,
current_sales-AVG(current_sales) over(partition by product_name) as avg_sales_difference,
case when current_sales-AVG(current_sales) over(partition by product_name)<0 then 'below avg'
when current_sales-AVG(current_sales) over(partition by product_name)>0 then 'Above avg' 
else 'Avg' end 'sales_status',
--previous monthly sales
lag(current_sales,1,current_sales) over(partition by product_name order by order_month) as previous_month_sales,current_sales-AVG(current_sales) over(partition by product_name) as avg_sales_difference,
case when current_sales-lag(current_sales) over(partition by product_name order by order_month)<0 then 'decresed'
when current_sales-lag(current_sales) over(partition by product_name order by order_month)>0 then 'Increased' 
else 'Avg' end 'monthly_status'
from cte_monthly
order by product_name,order_month

-- part-to-whole
-- which categories contribute the most of the overall sales
with cte_total as (select p.category,sum(f.sales_amount) as total_sales
--SUM(f.sales_amount) over(partition by category) as runningtotal
from gold.fact_sales f left join gold.dim_products p
on f.product_key=p.product_key
group by p.category)
--order by p.category,f.sales_amount
select *,
SUM(total_sales) over() as running_Sum,
concat(round((cast(total_sales AS float)/SUM(total_sales) over())*100,2),'%') as CATEGORY_PERCENT
from cte_total
order by CATEGORY_PERCENT desc

-- date segmentation 
/* segment products into cost range & count how many products fall inti each segment */

with cte_cost_range as (
select product_key,product_name,cost,
case when cost<100 then 'below-100'
when cost between 100 and 500 then '100-500'
when cost between 500 and 1000 then '500-1000'
else 'Above 1000' end cost_range
from gold.dim_products)
select cost_range,COUNT(product_key) as total_products from cte_cost_range
group by cost_range
order by total_products desc
/*
group customers into three segmentb based on their spending behaviour
vip: at least 12 months of history and spending more than $5000
regular: at least 12 months of history BUT spending  $5000 OR LESS
new: lifespan less than 12 months 
*/
with customer_segment as (
select  c.customer_key,sum(f.sales_amount) as total_spending,MIN(order_date) as first_order ,
MAX(order_date) as last_order,
DATEDIFF(month,MIN(order_date),MAX(order_date)) as lifespan
from gold.fact_sales f left join gold.dim_customers c on f.customer_key=c.customer_key
group by c.customer_key 
--order by c.customer_key desc
)
select customer_segment ,COUNT(customer_segment) as count_customer_segement from (
select customer_key,total_spending,lifespan ,
case when lifespan >=12 and total_spending > 5000  then 'VIP'
 when lifespan >=12 and total_spending <= 5000  then 'Regular'
else 'New' end 'customer_segment'
from customer_segment)t
group by customer_segment
order by customer_segment


--where customer_key=1708






































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































