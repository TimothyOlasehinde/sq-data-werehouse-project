/* ======================================================================================
---------------------------------------------------------------------------------------
#Reports (Customer & Products)
---------------------------------------------------------------------------------------
======================================================================================= */

/* ======================================================================================
##Customer Report (Using Common Table Expressions)
=========================================================================================
Purpose:
	- This report consolidates key customer metrics and behaviors

Highlights: 
	1. Gathers essential fields such as names, ages and transaction details. 
	2. Segments customers into categories (VIP, New, Regular) and age groups.
	3. Aggregates customer level metrics:
		- total orders
		- total sales
		- total quantity purchased
		- total products
		- lifespan (in months)
	4. Calculates valuable KPIs:
		- recency(months since last order)
		- average order value
		- average monthly spending 
====================================================================================== */

CREATE VIEW gold.report_customers AS 
WITH base_query AS (
/* ---------------------------------------------------------------------------------------
**1) Base Query: Retrives core colums from facts_sales & dim_customers tables**
--------------------------------------------------------------------------------------- */
SELECT 
	s.order_number,
	s.product_key,
	s.order_date,
	s.sales_amount,
	s.quantity,
	c.customer_key,
	c.customer_number,
	CONCAT(c.first_name, ' ', c.last_name) customer_name,
	(CURRENT_DATE - c.birthdate)/365 age
FROM gold.facts_sales s
JOIN gold.dim_customers c
	ON s.customer_key = c.customer_key
WHERE order_date IS NOT NULL)  -- only consider valid dates 

	,customer_aggregation AS (
/* ----------------------------------------------------------------------------------------
**2) Customer Aggregation: Summerizes key metrices at the customerlevel**
----------------------------------------------------------------------------------------- */
	SELECT 
		customer_key,
		customer_number,
		customer_name,
		age,
		COUNT(DISTINCT order_number) total_orders,
		SUM(sales_amount) total_spending, 
		SUM(quantity) total_quantity,
		COUNT(DISTINCT product_key) total_products,
		MAX(order_date) last_order_date,
		(MAX(order_date) - MIN(order_date))/30 lifespan_months
	FROM base_query
	GROUP BY 
		customer_key,
		customer_number,
		customer_name,
		age)		
/* ----------------------------------------------------------------------------------------
**3) Final Query: Combines all customer results into one output**
---------------------------------------------------------------------------------------- */
		SELECT 
		customer_key,
		customer_number,
		customer_name,
		CASE 
			 WHEN age < 20 THEN 'Under 20'
			 WHEN age BETWEEN 20 AND 29 THEN '20-29'
			 WHEN age BETWEEN 30 AND 39 THEN '30-39'
			 WHEN age BETWEEN 40 AND 49 THEN '40-49'
			 ELSE '50 and above'
		END age_groups,
		CASE 
			 WHEN lifespan_months >= 12 AND total_spending > 5000 THEN 'V.I.P'
			 WHEN lifespan_months <= 12 AND total_spending <= 5000 THEN 'Regular'
			 ELSE 'New'
		END customer_segments,	
		total_orders,
		total_spending,
		total_products,
		last_order_date,
		(CURRENT_DATE - last_order_date)/30 recency,
		lifespan_months,
		-- Compute average order value (AVO)
		CASE 
			WHEN total_orders = 0 THEN 0
			ELSE (total_spending/total_orders)
		END avg_order_value,
		-- Compute the average monthly spend
		CASE WHEN lifespan_months = 0 THEN total_spending 
			 ELSE total_spending/lifespan_months
		END avg_monthly_spend
		FROM customer_aggregation
		
/* ======================================================================================
##Products Report (Using Common Table Expressions)
=========================================================================================
Purpose:
	- This report consolidates key products metrics and behaviors

Highlights: 
	1. Gathers essential fields such as producs names, category and subcategory and cost. 
	2. Segments products by revenue to identify High-Performers, Mid_range, or Low_performers.
	3. Aggregates product-level metrics:
		- total orders
		- total sales
		- total quantity sold
		- total customers (unique)
		- lifespan (in months)
	4. Calculates valuable KPIs:
		- recency(months since last sale)
		- average order revenue(AOR)
		- average monthly revenue 
======================================================================================= */

CREATE VIEW gold.report_products AS 
WITH base_query AS (
/* ---------------------------------------------------------------------------------------
**1) Base Query: Retrives core colums from facts_sales & dim_products tables**
--------------------------------------------------------------------------------------- */
SELECT
	s.order_number,
	s.order_date,
	s.customer_key,
	s.sales_amount,
	s.quantity,
	p.product_key,
	p.product_name,
	p.category,
	p.subcategory,
	p.cost	
FROM gold.facts_sales s
JOIN gold.dim_products p
	ON s.product_key = p.product_key
WHERE order_date IS NOT NULL) -- only consider valid dates

	,products_aggregation AS (
/* ----------------------------------------------------------------------------------------
**2) Products Aggregation: Summerizes key metrices at the product-level**
----------------------------------------------------------------------------------------- */
	SELECT 
		product_key,
		product_name,
		category,
		subcategory,
		cost,
		(MAX(order_date) - MIN(order_date))/30 lifespan_months, 
		MAX(order_date) last_sale_date,
		COUNT(DISTINCT order_number) total_orders,
		COUNT(DISTINCT customer_key) total_customers,
		SUM(sales_amount) total_sales,
		SUM(quantity) total_quantity,
		ROUND(AVG(sales_amount/NULLIF(quantity, 0))) avg_selling_price
	FROM base_query
	GROUP BY 
		product_key,
		product_name,
		category,
		subcategory,
		cost)
/* ----------------------------------------------------------------------------------------
**3) Final Query: Combines all products results into one output**
---------------------------------------------------------------------------------------- */
			SELECT 
				product_key,
				product_name,
				category,
				subcategory,
				cost,
				last_sale_date,
				(CURRENT_DATE - lifespan_months) recency,
				CASE 
					WHEN total_sales > 50000 THEN 'High-Performer'
					WHEN total_sales >= 10000 THEN 'Mid-Range'
					ELSE 'Low-Performer'
				END product_segments,
				lifespan_months,
				total_orders,
				total_sales,
				total_quantity,
				total_customers,
				avg_selling_price,
				-- Compute Average Order Revenue (AOR)
				CASE 
					WHEN total_orders = 0 THEN 0
					ELSE total_sales/total_orders
				END avg_orded_revenue,
				-- Compute Average Monthly Revenue
				CASE 
					WHEN lifespan_months = 0 THEN total_sales
					ELSE total_sales/lifespan_months
				END avg_montly_revenue
			FROM products_aggregation
