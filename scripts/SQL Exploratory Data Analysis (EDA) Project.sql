

/*
===============================================================================
Database Exploration
===============================================================================
Purpose:
    - To explore the structure of the database, including the list of tables and their schemas.
    - To inspect the columns and metadata for specific tables.

Table Used:
    - INFORMATION_SCHEMA.TABLES
    - INFORMATION_SCHEMA.COLUMNS
===============================================================================
*/
-- Explore all object in the database
SELECT * FROM INFORMATION_SCHEMA.TABLES;
-- OR --
SELECT 
    TABLE_CATALOG, 
    TABLE_SCHEMA, 
    TABLE_NAME, 
    TABLE_TYPE
FROM INFORMATION_SCHEMA.TABLES;

-- Explore all the column in the database
SELECT * FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'dim_customers';
-- OR --
SELECT 
    COLUMN_NAME, 
    DATA_TYPE, 
    IS_NULLABLE, 
    CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'dim_customers';


/*
===============================================================================
Dimensions Exploration
===============================================================================
Purpose:
    - To explore the structure of dimension tables.
	
SQL Functions Used:
    - DISTINCT
    - ORDER BY
===============================================================================
*/
-- Retrieve a list of unique countries from which customers originate
SELECT DISTINCT 
    country 
FROM gold.dim_customers;

-- Retrieve a list of unique categories, subcategories, and products
SELECT DISTINCT 
    category, 
    subcategory, 
    product_name 
FROM gold.dim_product
ORDER BY category, subcategory, product_name;

/*
===============================================================================
Date Range Exploration 
===============================================================================
Purpose:
    - To determine the temporal boundaries of key data points.
    - To understand the range of historical data.

SQL Functions Used:
    - MIN(), MAX(), DATEDIFF()
===============================================================================
*/
-- Determine the first and last order date and the total duration in months
SELECT 
	MIN(order_date) AS first_order_date,
	MAX(order_date) AS last_order_date,
    TIMESTAMPDIFF(month,MIN(order_date),MAX(order_date)) AS order_range_months
FROM gold.fact_sales;

-- Find the youngest and oldest customer based on birthdate
SELECT 
	MIN(birthdate) AS oldest_birthdate,
    TIMESTAMPDIFF(year,MIN(birthdate),CURDATE()) AS oldest_age,
    MAX(birthdate) AS youngest_birthdate,
    TIMESTAMPDIFF(year,MAX(birthdate),CURDATE()) AS youngest_age
FROM gold.dim_customers;


/*
===============================================================================
Measures Exploration (Key Metrics)
===============================================================================
Purpose:
    - To calculate aggregated metrics (e.g., totals, averages) for quick insights.
    - To identify overall trends or spot anomalies.

SQL Functions Used:
    - COUNT(), SUM(), AVG()
===============================================================================
*/

-- Find the Total Sales
SELECT SUM(sales_amount) AS total_sales FROM gold.fact_sales;

-- Find how many items are sold
SELECT SUM(quantity) AS total_quantity FROM gold.fact_sales;

-- Find the average selling price
SELECT AVG(price) AS avg_selling_price FROM gold.fact_sales;

-- Find the Total number of Orders
SELECT count(order_number) AS total_orders FROM gold.fact_sales;

-- Find the total number of products
SELECT Count(product_name) FROM gold.dim_product;

-- Find the total number of customers
SELECT * FROM gold.dim_customers;
SELECT COUNT(customer_key) FROM gold.dim_customers;

-- Find the total number of customers that has placed an order
SELECT * FROM gold.fact_sales;
SELECT COUNT(distinct(customer_id)) as total_customer FROM gold.fact_sales;

-- Generate a Report that shows all key metrics of the business
SELECT 'Total Sales' AS measure_name, ROUND(SUM(sales_amount),0) AS measure_value FROM gold.fact_sales
UNION ALL
SELECT 'Total Quantity', ROUND(SUM(quantity),0) FROM gold.fact_sales
UNION ALL
SELECT 'Average Price', ROUND(AVG(price),0) FROM gold.fact_sales
UNION ALL
SELECT 'Total Orders', COUNT(DISTINCT order_number) FROM gold.fact_sales
UNION ALL
SELECT 'Total Products', COUNT(DISTINCT product_name) FROM gold.dim_product
UNION ALL
SELECT 'Total Customers', COUNT(customer_key) FROM gold.dim_customers;

/*
===============================================================================
Magnitude Analysis
===============================================================================
Purpose:
    - To quantify data and group results by specific dimensions.
    - For understanding data distribution across categories.

SQL Functions Used:
    - Aggregate Functions: SUM(), COUNT(), AVG()
    - GROUP BY, ORDER BY
===============================================================================
*/
SELECT * FROM gold.dim_customers;
SELECT * FROM gold.dim_product;
SELECT * FROM gold.fact_sales;

-- Find total customers by countries
SELECT 
	country,
    count(customer_key) as total_customer
FROM gold.dim_customers
GROUP BY country;

-- Find total customers by gender
SELECT 
	gender,
    count(customer_key) as total_customer
FROM gold.dim_customers
GROUP BY gender
ORDER BY total_customer DESC;

-- Find total products by category
SELECT 
	category,
    count(product_key) as total_products
FROM gold.dim_product
GROUP BY category
ORDER BY total_products DESC;

-- What is the average costs in each category?
SELECT
	category,
    ROUND(AVG(cost)) as avg_cost
FROM gold.dim_product
group by category
order by avg_cost;

-- What is the total revenue generated for each category?
SELECT 
	p.category,
    SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_product p
ON p.product_key = f.product_key
GROUP BY p.category
ORDER BY total_revenue DESC;

-- What is the total revenue generated by each customer?
SELECT 
	c.first_name,
    c.last_name,
    c.customer_id,
    SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
ON c.customer_id = f.customer_id
GROUP BY
	c.first_name,
    c.last_name,
    c.customer_id
ORDER BY total_revenue DESC;


-- What is the distribution of sold items across countries?
SELECT 
	c.country,
    SUM(f.quantity) AS total_sold_items
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
ON c.customer_id = f.customer_id
GROUP BY c.country
ORDER BY total_sold_items DESC;

/*
===============================================================================
Ranking Analysis
===============================================================================
Purpose:
    - To rank items (e.g., products, customers) based on performance or other metrics.
    - To identify top performers or laggards.

SQL Functions Used:
    - Window Ranking Functions: RANK(), DENSE_RANK(), ROW_NUMBER(), TOP
    - Clauses: GROUP BY, ORDER BY
===============================================================================
*/

-- Which 5 products Generating the Highest Revenue?
-- Simple Ranking
SELECT
	p.product_name,
    SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_product p
ON p.product_key = f.product_key
GROUP BY p.product_name
ORDER BY total_revenue DESC
LIMIT 5;
-- Complex but Flexibly Ranking Using Window Functions
SELECT *
FROM (
    SELECT
        p.product_name,
        SUM(f.sales_amount) AS total_revenue,
        RANK() OVER (ORDER BY SUM(f.sales_amount) DESC) AS rank_products
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_product p
        ON p.product_key = f.product_key
    GROUP BY p.product_name
) AS ranked_products
WHERE rank_products <= 5;

-- What are the 5 worst-performing products in terms of sales?

SELECT 
	p.product_name,
    SUM(f.sales_amount) as total_sales
FROM gold.fact_sales f
LEFT JOIN gold.dim_product p
ON p.product_key = f.product_key
GROUP by product_name
Order by total_sales
LIMIT 5;

-- Find the top 10 customers who have generated the highest revenue

SELECT 
	c.first_name,
    c.last_name,
    c.customer_id,
    SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
ON c.customer_id = f.customer_id
GROUP BY
	c.first_name,
    c.last_name,
    c.customer_id
ORDER BY total_revenue DESC
LIMIT 5;

-- The 3 customers with the fewest orders placed
SELECT 
	c.first_name,
    c.last_name,
    c.customer_id,
    COUNT(DISTINCT order_number) AS total_orders
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
ON c.customer_id = f.customer_id
GROUP BY
	c.first_name,
    c.last_name,
    c.customer_id
ORDER BY total_orders
LIMIT 3;


/*
===============================================================================
Change Over Time Analysis
===============================================================================
Purpose:
    - To track trends, growth, and changes in key metrics over time.
    - For time-series analysis and identifying seasonality.
    - To measure growth or decline over specific periods.

SQL Functions Used:
    - Date Functions: DATEPART(), DATETRUNC(), FORMAT()
    - Aggregate Functions: SUM(), COUNT(), AVG()
===============================================================================
*/

-- Analyse sales performance over time
-- Quick Date Functions
SELECT 
YEAR(order_date) AS order_year,
MONTH(order_date) AS order_month,
SUM(sales_amount) AS total_sales,
COUNT(DISTINCT(customer_id)) as total_cutomer,
SUM(quantity) AS total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY 
	YEAR(order_date),MONTH(order_date)
ORDER BY
	YEAR(order_date),MONTH(order_date);
    
-- FORMAT()
SELECT
    DATE_FORMAT(order_date, '%Y-%b') AS order_month,
    SUM(sales_amount) AS total_sales,
    COUNT(DISTINCT customer_id) AS total_customers,
    SUM(quantity) AS total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATE_FORMAT(order_date, '%Y-%b')
ORDER BY MIN(order_date);   -- ensures correct chronological order

/*
===============================================================================
Cumulative Analysis
===============================================================================
Purpose:
    - To calculate running totals or moving averages for key metrics.
    - To track performance over time cumulatively.
    - Useful for growth analysis or identifying long-term trends.

SQL Functions Used:
    - Window Functions: SUM() OVER(), AVG() OVER()
===============================================================================
*/

-- Calculate the total sales per month 
-- and the running total of sales over time 
SELECT
    order_month,
    total_sales,
    SUM(total_sales) OVER (ORDER BY order_month) AS running_total_sales,
    AVG(avg_price) OVER (ORDER BY order_month) AS moving_average_price
FROM (
    SELECT 
        DATE_FORMAT(order_date, '%Y-%b') AS order_month,
        SUM(sales_amount) AS total_sales,
        AVG(price) AS avg_price
    FROM gold.fact_sales
    WHERE order_date IS NOT NULL
    GROUP BY order_month
) t;


/*
===============================================================================
Performance Analysis (Year-over-Year, Month-over-Month)
===============================================================================
Purpose:
    - To measure the performance of products, customers, or regions over time.
    - For benchmarking and identifying high-performing entities.
    - To track yearly trends and growth.

SQL Functions Used:
    - LAG(): Accesses data from previous rows.
    - AVG() OVER(): Computes average values within partitions.
    - CASE: Defines conditional logic for trend analysis.
===============================================================================
*/

/* Analyze the yearly performance of products by comparing their sales 
to both the average sales performance of the product and the previous year's sales */

WITH yearly_product_sales AS (
    SELECT 
        YEAR(f.order_date) AS order_year,
        p.product_name,
        SUM(f.sales_amount) AS current_sales
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_product p
        ON f.product_key = p.product_key
    WHERE f.order_date IS NOT NULL
    GROUP BY 
        YEAR(f.order_date),
        p.product_name
)
SELECT 
	order_year,
    product_name,
    current_sales,
    AVG(current_sales) OVER(PARTITION BY product_name) as avg_sales,
    ROUND(current_sales - AVG(current_sales) OVER(PARTITION BY product_name)) AS diff_avg,
    CASE WHEN ROUND(current_sales - AVG(current_sales) OVER(PARTITION BY product_name)) > 0 THEN 'Above Avg'
		WHEN ROUND(current_sales - AVG(current_sales) OVER(PARTITION BY product_name)) < 0 THEN 'Below Avg'
        ELSE 'Avg'
	END avg_change,
    -- Year-over-Year Analysis
    LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) AS py_sales,
    current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) AS diff_py,
    CASE WHEN ROUND(current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year)) > 0 THEN 'Increase'
		WHEN ROUND(current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year)) < 0 THEN 'Decrease'
        ELSE 'No Change'
	END py_change
    FROM yearly_product_sales;

/*
===============================================================================
Part-to-Whole Analysis
===============================================================================
Purpose:
    - To compare performance or metrics across dimensions or time periods.
    - To evaluate differences between categories.
    - Useful for A/B testing or regional comparisons.

SQL Functions Used:
    - SUM(), AVG(): Aggregates values for comparison.
    - Window Functions: SUM() OVER() for total calculations.
===============================================================================
*/
-- Which categories contribute the most to overall sales?

WITH category_sales AS (
SELECT 
	p.category,
    SUM(f.sales_amount) AS total_sales
FROM gold.fact_sales f
LEFT JOIN gold.dim_product p
ON p.product_key = f.product_key
GROUP BY category
)
SELECT
	category,
    total_sales,
    SUM(total_sales) OVER() AS overall_sales,
	CONCAT(ROUND((total_sales / SUM(total_sales) OVER()) * 100, 2), '%') AS percentage_total
FROM category_sales
ORDER BY total_sales DESC;


/*
===============================================================================
Data Segmentation Analysis
===============================================================================
Purpose:
    - To group data into meaningful categories for targeted insights.
    - For customer segmentation, product categorization, or regional analysis.

SQL Functions Used:
    - CASE: Defines custom segmentation logic.
    - GROUP BY: Groups data into segments.
===============================================================================
*/

/*Segment products into cost ranges and 
count how many products fall into each segment*/
WITH product_segment AS(
SELECT 
	product_key,
    product_name,
    cost,
    CASE WHEN cost < 100 THEN 'Below 100'
		 WHEN cost BETWEEN 100 AND 500 THEN '100-500'
         WHEN cost BETWEEN 500 AND 1000 THEN '500-1000'
         ELSE 'Above 1000'
	END cost_range
	FROM gold.dim_product)
	SELECT 
		cost_range,
		count(product_key) AS total_product
	FROM product_segment
	GROUP BY cost_range
    ORDER BY total_product DESC;
    
/*Group customers into three segments based on their spending behavior:
	- VIP: Customers with at least 12 months of history and spending more than €5,000.
	- Regular: Customers with at least 12 months of history but spending €5,000 or less.
	- New: Customers with a lifespan less than 12 months.
And find the total number of customers by each group
*/
WITH customer_spending AS(
SELECT
	c.customer_key,
    SUM(f.sales_amount) AS total_spending,
    MIN(order_date) AS first_order,
    MAX(order_date) AS last_order,
    TIMESTAMPDIFF(MONTH,MIN(order_date),MAX(order_date)) AS lifespan
FROM gold.fact_sales f
left JOIN gold.dim_customers c
ON f.customer_key = c.customer_key
GROUP BY c.customer_key
)
SELECT 
customer_segment,
count(customer_key) AS total_customers
FROM (
	SELECT 
		customer_key,
		CASE WHEN lifespan >= 12 AND total_spending > 5000 THEN 'VIP'
			 WHEN lifespan >= 12 AND total_spending <= 5000 THEN 'Regular'
			 ELSE 'New'
		END customer_segment
	FROM customer_spending)t
GROUP BY customer_segment
ORDER BY total_customers DESC;

/*
===============================================================================
Customer Report
===============================================================================
Purpose:
    - This report consolidates key customer metrics and behaviors

Highlights:
    1. Gathers essential fields such as names, ages, and transaction details.
	2. Segments customers into categories (VIP, Regular, New) and age groups.
    3. Aggregates customer-level metrics:
	   - total orders
	   - total sales
	   - total quantity purchased
	   - total products
	   - lifespan (in months)
    4. Calculates valuable KPIs:
	    - recency (months since last order)
		- average order value
		- average monthly spend
===============================================================================
*/

-- =============================================================================
-- Create Report: gold.report_customers
-- =============================================================================


CREATE VIEW gold.report_customers AS
WITH base_query AS (
    /*---------------------------------------------------------------------------
    1) Base Query: Retrieves core columns from fact_sales and dim_customers
    ---------------------------------------------------------------------------*/
    SELECT 
        f.order_number,
        f.product_key,
        f.order_date,
        f.sales_amount,
        f.quantity,
        c.customer_key,
        c.customer_number,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        TIMESTAMPDIFF(YEAR, c.birthdate, CURDATE()) AS age
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_customers c
        ON c.customer_key = f.customer_key
    WHERE f.order_date IS NOT NULL)
, customer_aggregation AS(
/*---------------------------------------------------------------------------
2) Product Aggregations: Summarizes key metrics at the product level
---------------------------------------------------------------------------*/
SELECT 
    customer_key,
    customer_number,
    customer_name,
    age,
    COUNT(DISTINCT order_number) AS total_orders,
    SUM(sales_amount) AS total_sales,
    SUM(quantity) AS total_quantity,
    COUNT(DISTINCT product_key) AS total_products,
    MAX(order_date) AS last_order_date,
    TIMESTAMPDIFF(MONTH, MIN(order_date), MAX(order_date)) AS lifespan
FROM base_query
GROUP BY
    customer_key,
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
		WHEN age < 20 THEN 'under 20'
        WHEN age between 20 and 29 THEN '20-29'
        WHEN age between 30 and 39 THEN '30-39'
        WHEN age between 40 and 49 THEN '40-49'
        ELSE '50 and above'
	END AS age_group,
    CASE 
		WHEN lifespan >= 12 AND total_sales > 5000 THEN 'VIP'
		WHEN lifespan >= 12 AND total_sales <= 5000 THEN 'Regular'
		ELSE 'New'
	END AS customer_segment,	
    last_order_date,
    TIMESTAMPDIFF(month,last_order_date, CURDATE()) AS recency,
	total_orders,
    total_sales,
    total_quantity,
    total_products,
    lifespan,
    	-- Average Order Revenue (AOR)
	CASE 
		WHEN total_orders = 0 THEN 0
		ELSE round(total_sales / total_orders)
	END AS vg_order_revenue,
    
	-- Average Monthly Revenue
	CASE
		WHEN lifespan = 0 THEN total_sales
		ELSE round(total_sales / lifespan)
	END AS avg_monthly_revenue
FROM customer_aggregation;


/*
===============================================================================
Product Report
===============================================================================
Purpose:
    - This report consolidates key product metrics and behaviors.

Highlights:
    1. Gathers essential fields such as product name, category, subcategory, and cost.
    2. Segments products by revenue to identify High-Performers, Mid-Range, or Low-Performers.
    3. Aggregates product-level metrics:
       - total orders
       - total sales
       - total quantity sold
       - total customers (unique)
       - lifespan (in months)
    4. Calculates valuable KPIs:
       - recency (months since last sale)
       - average order revenue (AOR)
       - average monthly revenue
===============================================================================
*/
-- =============================================================================
-- Create Report: gold.report_products
-- =============================================================================


CREATE VIEW gold.report_products AS
WITH base_query AS (
/*---------------------------------------------------------------------------
1) Base Query: Retrieves core columns from fact_sales and dim_products
---------------------------------------------------------------------------*/
    SELECT
	    f.order_number,
        f.order_date,
		f.customer_key,
        f.sales_amount,
        f.quantity,
        p.product_key,
        p.product_name,
        p.category,
        p.subcategory,
        p.cost
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_product p
        ON f.product_key = p.product_key
    WHERE order_date IS NOT NULL  -- only consider valid sales dates
),

product_aggregations AS (
 
SELECT
    product_key,
    product_name,
    category,
    subcategory,
    cost,
    TIMESTAMPDIFF(MONTH, MIN(order_date), MAX(order_date)) AS lifespan,
    MAX(order_date) AS last_sale_date,
    COUNT(DISTINCT order_number) AS total_orders,
	COUNT(DISTINCT customer_key) AS total_customers,
    SUM(sales_amount) AS total_sales,
    SUM(quantity) AS total_quantity,
	ROUND(AVG(CAST(sales_amount AS FLOAT) / NULLIF(quantity, 0)),1) AS avg_selling_price
FROM base_query

GROUP BY
    product_key,
    product_name,
    category,
    subcategory,
    cost
)

/*---------------------------------------------------------------------------
  3) Final Query: Combines all product results into one output
---------------------------------------------------------------------------*/
SELECT 
	product_key,
	product_name,
	category,
	subcategory,
	cost,
	last_sale_date,
	TIMESTAMPDIFF(MONTH, last_sale_date, CURDATE()) AS recency_in_months,
	CASE
		WHEN total_sales > 50000 THEN 'High-Performer'
		WHEN total_sales >= 10000 THEN 'Mid-Range'
		ELSE 'Low-Performer'
	END AS product_segment,
	lifespan,
	total_orders,
	total_sales,
	total_quantity,
	total_customers,
	avg_selling_price,
	-- Average Order Revenue (AOR)
	CASE 
		WHEN total_orders = 0 THEN 0
		ELSE round(total_sales / total_orders)
	END AS avg_order_revenue,

	-- Average Monthly Revenue
	CASE
		WHEN lifespan = 0 THEN total_sales
		ELSE round(total_sales / lifespan)
	END AS avg_monthly_revenue

FROM product_aggregations;

select * from gold.report_products;