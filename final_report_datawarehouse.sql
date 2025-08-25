--customer_view
select 
age_status,
COUNT(customer_number) as total_customers,
SUM(total_sales) as total_sales
from gold.report_customers
group by age_status



--product_view
select * from gold.report_product