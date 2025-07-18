/* 
=============================================================================
 Advanced Analytics
=============================================================================
Purpose:
	- This script aims to evaluate the processed data to produce 
	  mesurable business insights into key metrics.
	- It uses the data from the Gold Layer (facts_sales, dim_customers 
	  & dim_products tables) for its analysis

Highlights: 
	1. Change-Over-Time
	2. Cummulative Analysis
	3. Performance Analysis
	4. Part-To-Whole
	5. Data Segmentation

Usage:
	Run this scrip to gain highlevel insights into the business 
	performance
=========================================================================== */


-- --------------------------------------------------------------------------
-- Change-Over-Time (Trends)
-- --------------------------------------------------------------------------
-- Sales Performanc over time (By Month)
SELECT 
	EXTRACT(YEAR FROM order_date) order_year,
	EXTRACT(MONTH FROM order_date) order_month,
	SUM(sales_amount) total_sales,
	COUNT(DISTINCT customer_key) total_customers,
	SUM(quantity) total_quantity
FROM gold.facts_sales
WHERE order_date IS NOT NULL
GROUP BY order_year, order_month
ORDER BY order_year, order_month 

-- --------------------------------------------------------------------------
-- Cumulative Analysis
-- --------------------------------------------------------------------------
/* Calculate the total cumulative sales 
   and moving average price per year (using window function).
*/
SELECT
	order_year,
	total_sales,
	SUM(total_sales) OVER (ORDER BY order_year) running_total_sales,
	AVG(avg_prive) OVER (ORDER BY avg_prive) moving_avg_price
FROM(
	SELECT EXTRACT(YEAR FROM order_date) order_year, /* Adjust date function 
														 (e.g., 'MONTH', 'DAY') 
														 for further breakdown
														 of the data
													  */
		SUM(sales_amount) total_sales,
		AVG(price) avg_prive
	FROM gold.facts_sales
	WHERE order_date IS NOT NULL
	GROUP BY order_year)

-- --------------------------------------------------------------------------
-- Performance Analysis
-- --------------------------------------------------------------------------
/* Analyze the yearly performance of the products by comparing each product's sales
  to both the average sales performance and the previous year's sales 
  (Using Common Table Expressions (CTE)).
*/
WITH total_yearly_sales AS (
SELECT 
	EXTRACT(YEAR FROM s.order_date) order_year,  /* Adjust date function
													(e.g.,'Month') for further
													breakdown of the date.
												 */
	p.product_name,
	SUM(s.sales_amount) current_sales	
FROM gold.facts_sales s
JOIN gold.dim_products p
	ON s.product_key = p.product_key
WHERE order_date IS NOT NULL
GROUP BY order_year, p.product_name)

	SELECT 
		order_year,
		product_name,
		current_sales,
		ROUND(AVG(current_sales) OVER (PARTITION BY product_name)) avg_sales,
		current_sales - AVG(current_sales) OVER (PARTITION BY product_name) avg_sales_diff,
		CASE WHEN current_sales - AVG(current_sales) OVER (PARTITION BY product_name) > 0 THEN 'Above Avg'
			 WHEN current_sales - AVG(current_sales) OVER (PARTITION BY product_name) < 0 THEN 'Below Avg'
			 ELSE 'No Difference'
		END avg_diff,
		LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) prv_yr_total_sales,
		current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) sales_diff_prv_yr,
		CASE WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) > 0 THEN 'Increase'
			 WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) < 0 THEN 'Decrease'
			 ELSE 'No Difference'
		END sales_diff
	FROM total_yearly_sales
	ORDER BY  product_name, order_year

-- --------------------------------------------------------------------------
-- Part-To-Whole
-- --------------------------------------------------------------------------
-- Which categories contribute the most to the overall sales? (Using Common Table Expressions (CTE))
WITH category_sales AS (
SELECT 
	p.category,									/* Adjust target metrics 
												   (e.g., 'subcategory', 'product')
												   to explore more segmentations.
												*/
	SUM(s.sales_amount) total_sales 
FROM gold.facts_sales s
JOIN gold.dim_products p
	ON s.product_key = p.product_key 
GROUP BY p.category)

	SELECT 
		category,
		total_sales,
		SUM(total_sales) OVER() overall_sales,
		CONCAT(ROUND(total_sales / SUM(total_sales) OVER(), 2) * 100,'%') percent_of_total
	FROM category_sales
	ORDER BY percent_of_total DESC

-- --------------------------------------------------------------------------
-- Data Segmentation
-- --------------------------------------------------------------------------
/* Segment products into cost ranges and count how many products fall into 
each category (Using Common Table Expressions (CTE)).
*/
WITH product_segment AS (
SELECT 
	product_key,
	product_name,
	cost,
	CASE WHEN cost < 100 THEN 'Below 100'
		 WHEN cost Between 100 AND 500 THEN '100-500'
		 WHEN cost BETWEEN 500 AND 1000 THEN '500-1000'
		 ELSE 'Above 100'
	END cost_range 
FROM gold.dim_products)

	SELECT 
		cost_range,
		COUNT(product_key) total_products
	FROM product_segment
	GROUP BY cost_range
	ORDER BY total_products 

/* Group customers into three segments based on their spending behavior:
	- VIP: Customers with at least 12 months of history and spending more than $5000.
	- Regular: Customers with at least 12 months of history but spending $5000 or less. 
	- New: Customers with a lifespan less then 12 months
And find the total number of customers by each group (Using Common Table Expressions (CTE))
*/
WITH customer_spending AS (
SELECT 
	c.customer_key,
	SUM(s.sales_amount) total_spending,
	MIN(s.order_date) first_order,
	MAX(s.order_date) last_order,
	(MAX(s.order_date) - MIN(s.order_date))/30  lifespan_months  /* Dividing the equation by 30
																    to get the period in months
																 */
FROM gold.facts_sales s
JOIN gold.dim_customers c 
	ON s.customer_key = c.customer_key 
GROUP BY c.customer_key)

	SELECT 
		customer_segments,
		COUNT(customer_key) total_customers
	FROM (
		SELECT 
			customer_key, 
			CASE WHEN lifespan_months >= 12 AND total_spending > 5000 THEN 'V.I.P'
				 WHEN lifespan_months <= 12 AND total_spending <= 5000 THEN 'Regular'
				 ELSE 'New'
			END customer_segments	
		FROM customer_spending)
	GROUP BY customer_segments
	ORDER BY total_customers DESC








