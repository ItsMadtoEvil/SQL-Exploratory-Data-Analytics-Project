/* ============================================================
   Product Report
   ============================================================

   Purpose:
   This report consolidates key product metrics and performance
   behaviors to support sales and inventory analysis.

   Highlights:
   1. Captures essential product attributes such as product name,
      category, subcategory, and cost.
   2. Segments products by revenue performance to identify:
      - High Performers
      - Mid-Range Performers
      - Low Performers
   3. Aggregates product-level metrics, including:
      - Total orders
      - Total sales
      - Total quantity sold
      - Total unique customers
      - Product lifespan (in months)
   4. Calculates important KPIs:
      - Recency (months since last sale)
      - Average order revenue (AOR)
      - Average monthly revenue

   ============================================================ */
USE DataWarehouseAnalytics1
GO

WITH base_table AS(
SELECT 
    f.order_number,
    f.customer_key,
    f.order_date,
    f.sales_amount,
    f.quantity,
    p.product_key,
    p.product_name,
    p.category,
    p.subcategory,
    p.cost
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_products AS p
on f.product_key = p.product_key
WHERE order_date IS NOT NULL
),
product_aggregation AS (
SELECT
    COUNT(DISTINCT order_number) AS total_orders,
    COUNT(DISTINCT customer_key) AS total_customers,
    SUM(sales_amount) AS total_sales,
    SUM(quantity) AS total_quantity,
    product_key,
    product_name,
    category,
    subcategory,
    cost,
    ROUND(AVG(CAST(sales_amount AS FLOAT)/ NULLIF(quantity,0)),2)AS avg_selling_price,
    MAX(order_date) AS last_sale_date,
    DATEDIFF(MONTH,MIN(order_date),MAX(order_date)) AS lifespan
FROM base_table
GROUP BY product_key,
         product_name,
         category,
         subcategory,
         cost
)
SELECT
    product_key,
    product_name,
    category,
    subcategory,
    cost,
    total_orders,
    total_customers,
    total_sales,
    total_quantity,
    CASE
         WHEN total_sales > 50000 THEN 'High-Performer'
         WHEN total_sales >= 10000 THEN 'Mid-Range'
         ELSE 'Low-Performer'
    END AS product_segment,
    avg_selling_price,
    CASE
         WHEN total_orders = 0 THEN 0
         ELSE total_sales/total_orders
    END AS avg_order_revenue,
    CASE
         WHEN lifespan = 0 THEN total_sales
         ELSE total_sales/ lifespan
    END AS avg_monthly_revenue,
    DATEDIFF(MONTH,last_sale_date,GETDATE()) AS recency,
    last_sale_date,
    lifespan
FROM product_aggregation