use DataWarehouseAnalytics;
/*===================================================================
PROJECT REPORT 
=====================================================================
Purpose :
- This report conslidates key product metrics and behaviour
Highlights:
1) Gathers essential fields such as product name , category,subcategory and cost.
2)Segments products by revenue to identify  High-performers , Mid-range or Low-performers.
3)Aggregate product- level Metrics:
 -total orders
 -total sales
 -total quantity sold
 -total customers(Unique)
 -lifespan(in months)
4) calculate valubale KPI's:
- recency(months since last sale)
-average order revenue(AOR)
- Average Monthly revenue
=====================================================================
*/
--1) Gathers essential fields such as product name , category,subcategory and cost.
create view gold.report_Product as
with cte_query as (
    select 
        f.order_number,
        f.customer_key,
        p.product_key,
        p.product_name,
        p.category,
        p.subcategory,
        p.cost,
        f.sales_amount,
        f.order_date,
        f.quantity
    from gold.fact_sales f
    left join gold.dim_products p 
        on f.product_key = p.product_key 
    where order_date is not null
),
/*--------------------------------Aggregate product- level Metrics:-----------------------------*/
product_segmentation as (
    select  
        product_key,
        product_name,
        COUNT(distinct order_number) as total_orders,
        SUM(quantity) as total_quantity,
        SUM(sales_amount) as total_sales,
        COUNT(distinct customer_key) as total_customers,
        MIN(order_date) as first_order_date,
        MAX(order_date) as last_order_date,
        DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) as lifespan_months
    from cte_query
    group by product_key, product_name
),final_report as
/*-----2)Segments products by revenue to identify  High-performers , Mid-range or Low-performers--*/
(select 
	*,
	case when total_sales>5000 then 'High-performers'
	when total_sales  between 5000 and 10000  then  'Mid-Revenue'
	else 'Low-performers'
	end performance_segment,
	/* ============================calculate valubale KPI'============================================= */
	DATEDIFF(MONTH,last_order_date,GETDATE()) as recency,
	--total_orders,
	-- average order revenue
	case when total_sales=0 then 0
	else total_sales/total_orders end as  Avg_order_revenue,
	--average Monthly revenue (AMR)
	case when total_sales=0 then 0 
	else total_sales/lifespan_months 
	end 'average Monthly revenue'
from product_segmentation)
select * from final_report

