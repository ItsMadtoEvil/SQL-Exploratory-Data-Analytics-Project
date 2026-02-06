/* ============================================================
   Customer Report
   ============================================================

   Purpose:
   This report consolidates key customer metrics and behavioral
   insights for analytical and business decision-making.

   Highlights:
   1. Captures core customer attributes such as names, ages,
      and transaction details.
   2. Segments customers into meaningful groups:
      - VIP
      - Regular
      - New
      along with age-based categories.
   3. Aggregates customer-level metrics, including:
      - Total orders
      - Total sales
      - Total quantity purchased
      - Total distinct products
      - Customer lifespan (in months)
   4. Calculates important KPIs:
      - Recency (months since last order)
      - Average order value
      - Average monthly spend

   ============================================================ */
USE DataWarehouseAnalytics1
GO
-----------------------------
-----------------------------
CREATE VIEW gold.report_customers AS
-----------------------------
-----------------------------
WITH base_table AS(
    SELECT 
        f.order_number,
        f.product_key,
        f.order_date,
        f.sales_amount,
        f.quantity,
        f.customer_key,
        c.customer_number,
        CONCAT(c.first_name,' ',c.last_name) AS customer_name,
        DATEDIFF(YEAR,c.birthdate,GETDATE()) AS age
    FROM gold.fact_sales AS f
    LEFT JOIN gold.dim_customers AS c
    ON f.customer_key = c.customer_key
    WHERE order_date IS NOT NULL
),
customer_aggregation AS(
    SELECT
        customer_key,
        customer_number,
        customer_name,
        age,
        COUNT(DISTINCT order_number) AS total_orders,
        SUM(sales_amount) AS total_sales,
        SUM(quantity) AS total_quantity,
        SUM(product_key) AS total_products,
        MAX(order_date) AS last_order_date,
        DATEDIFF(MONTH,MIN(order_date),MAX(order_date)) AS lifespan
    FROM base_table
    GROUP BY customer_key,
             customer_number,
             customer_name,
             age
)
SELECT
    customer_key,
    customer_number,
    customer_name,
    age,
    CASE
         WHEN age < 20 THEN 'Below 20'
         WHEN age BETWEEN 20 AND 29 THEN '20-29'
         WHEN age BETWEEN 30 AND 39 THEN '30-39'
         WHEN age BETWEEN 40 AND 49 THEN '40-49'
         ELSE '50 And Above'
    END AS age_groups,
    CASE
        WHEN lifespan >= 12 AND total_sales > 5000 THEN 'VIP'
        WHEN lifespan >= 12 AND total_sales < 5000 THEN 'Regular'
        ELSE 'New'
    END AS customer_segment,
    total_orders,
    total_sales,
    CASE
         WHEN total_orders = 0 THEN 0
         ELSE (total_sales/ total_orders)
    END AS avg_order_value,
    CASE 
         WHEN lifespan = 0 THEN total_sales
         ELSE (total_sales/lifespan)
    END AS avg_monthly_spend,
    total_quantity,
    total_products,
    DATEDIFF(MONTH, last_order_date,GETDATE()) AS recency,
    last_order_date,
    lifespan
FROM customer_aggregation

------------------------------------------------------
