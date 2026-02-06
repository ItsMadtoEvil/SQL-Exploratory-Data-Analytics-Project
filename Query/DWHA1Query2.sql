USE DataWarehouseAnalytics1;
GO

/* Changes Over Time Analysis*/
-- SALES ANALYSIS BY DATE
SELECT 
order_date,
SUM(sales_amount) AS total_Sales
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY order_date
ORDER BY order_date

-- SALES ANALYSIS BY YEAR
SELECT 
YEAR(order_date) AS order_year,
SUM(sales_amount) AS total_Sales
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date)
ORDER BY YEAR(order_date)

-- SALES ANALYSIS BY MONTH
SELECT 
MONTH(order_date) AS order_month,
SUM(sales_amount) AS total_Sales,
COUNT(DISTINCT customer_key) AS total_customers,
SUM(quantity) AS total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY MONTH(order_date)
ORDER BY MONTH(order_date)

-- SALES ANALYSIS BY MONTH ON YEAR
SELECT 
YEAR(order_date) AS order_year,
MONTH(order_date) AS order_month,
SUM(sales_amount) AS total_Sales,
COUNT(DISTINCT customer_key) AS total_customers,
SUM(quantity) AS total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date),MONTH(order_date)
ORDER BY YEAR(order_date),MONTH(order_date)

-- SALES ANALYSIS BY MONTH ON YEAR FROM STARTING DATE OF MONTH
SELECT 
DATETRUNC(MONTH,order_date) AS order_date,
SUM(sales_amount) AS total_Sales,
COUNT(DISTINCT customer_key) AS total_customers,
SUM(quantity) AS total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(MONTH,order_date) 
ORDER BY DATETRUNC(MONTH,order_date)

-- SALES ANALYSIS BY MONTH ON YEAR FORMAT
SELECT 
FORMAT(order_date,'yyyy-MMM') AS order_date,
SUM(sales_amount) AS total_Sales,
COUNT(DISTINCT customer_key) AS total_customers,
SUM(quantity) AS total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY FORMAT(order_date,'yyyy-MMM') 
ORDER BY FORMAT(order_date,'yyyy-MMM')

/* Cumulative Analysis*/

-- Calculate the Total Sales Per Month
-- And the running total of sales over time

SELECT 
order_date AS order_year,
total_Sales,
SUM(total_sales) OVER (ORDER BY order_date) AS running_total_sales,
AVG(avg_price) OVER (ORDER BY order_date) AS moving_average_price
FROM
(
SELECT
DATETRUNC(YEAR,order_date) AS order_date,
SUM(sales_amount) AS total_sales,
AVG(price) AS avg_price
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(YEAR,order_date)
)t

/* Performance Analysis*/
-- Analyze the yearly performance of products by comparing their sales
-- to both the average sales performance of the product and the previous year's sales

WITH yearly_product_sales AS (
SELECT 
YEAR(f.order_date) AS order_year,
p.product_name,
SUM(f.sales_amount) AS current_sales
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_products AS p
ON f.product_key = p.product_key
WHERE f.order_date IS NOT NULL
GROUP BY YEAR(f.order_date),p.product_name
)
SELECT
order_year,
product_name,
current_sales,
AVG(current_sales) OVER (PARTITION BY product_name) AS avg_sales,
current_sales - AVG(current_sales) OVER (PARTITION BY product_name) AS diff_avg,
CASE WHEN current_sales - AVG(current_sales) OVER (PARTITION BY product_name) < 0 THEN 'Below AVG'
	 WHEN current_sales - AVG(current_sales) OVER (PARTITION BY product_name) > 0 THEN 'Above AVG'
	 ELSE 'AVG'
END AS avg_changes,
LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) AS previous_year_sales,
current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) AS diff_previous_year,
CASE WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) > 0 THEN 'Increase'
	 WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) < 0 THEN 'Decrease'
	 ELSE 'No Changes'
END AS previous_year_changes
FROM yearly_product_sales
ORDER BY product_name, order_year

/*Proportional Analysis*/
-- Which Categories contribute the most to overall sales?
WITH category_sales AS(
SELECT
category,
SUM(sales_amount) AS total_sales
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_products AS p
ON p.product_key = f.product_key
GROUP BY category
)
SELECT
category,
total_sales,
SUM(total_sales) OVER () overall_sales,
CONCAT(ROUND((CAST(total_sales AS FLOAT) / SUM(total_sales) OVER ())*100, 2), '%') AS percentage_of_total
FROM category_sales
ORDER BY total_sales DESC

/*Data Segmentation*/
-- Segment products into cost ranges and count how many products fall into each segment
WITH product_segments AS (
SELECT
product_key,
product_name,
cost,
CASE WHEN cost<100 THEN 'Below 100'
	 WHEN cost BETWEEN 100 AND 500 THEN '100-500'
	 WHEN cost BETWEEN 500 AND 1000 THEN '500-1000'
	 ELSE 'Above 1000'
END AS cost_range
FROM gold.dim_products
)
SELECT
cost_range,
COUNT(product_key) AS total_products
FROM product_segments
GROUP BY cost_range
ORDER BY total_products DESC

--- GROUP CUSTOMERS INTO THREE SEGMENTS BASED ONTHEIR SPENDING BEHAVIOR:
-- VIP: AT LEAST 12 MONTHS OF HISTORY AND SPENDING MORE THAN 5000.
-- REGULAR: AT LEAST 12 MONTHS OF HISTORY BUT SPENDING 5000 OR LESS.
-- NEW: LIFESPAN LESS THAN 12 MONTHS.
--- AND FIND THE TOTAL NUMBER OF CUSTOMERS BY EACH GROUP
WITH customer_spending AS(SELECT
c.customer_key,
SUM(f.sales_amount) AS total_spending,
DATEDIFF(MONTH,MIN(order_date),MAX(order_date)) AS lifespan
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_customers AS c
ON f.customer_key = c.customer_key
GROUP BY c.customer_key
)
SELECT
customer_segment,
COUNT(customer_key) AS total_customers
FROM(SELECT
customer_key,
CASE WHEN lifespan >= 12 AND total_spending > 5000 THEN 'VIP'
	 WHEN lifespan >= 12 AND total_spending < 5000 THEN 'Regular'
	 ELSE 'New'
END customer_segment
FROM customer_spending
) t
GROUP BY customer_segment
ORDER BY total_customers DESC
