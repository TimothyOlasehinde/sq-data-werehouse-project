/*
===================================================================================================================
DDL Script: Explanatory Data Analysis
===================================================================================================================
Script Purpose:
  This script explors that data analytically by measuring several dimentions within the dimentions tables to
  the measures within the facts table in the Gold Layer.
  It provides business insights for measuring the performance of different metrics. 
  It analyzes:
  - The relationship between products and sales
  - It measures the highest and lowest areas of revenue
  - Analyzes product performance by categories

Usage:
  - Run this script to gain insights into the performace of the business 
  - Adjust the dimentions appropriatley to gain further insights
===================================================================================================================
*/

-- ----------------------------------------------------------------------------------------------------------------
-- Data Exploration
-- ----------------------------------------------------------------------------------------------------------------

-- Explore All Tables & Columns in the Database 
SELECT * 
FROM information_schema.columns c
JOIN information_schema.tables t 
	ON c.table_name = t.table_name
WHERE t.table_name = 'dim_products' --(Switch out table name to check individual tables, e.g., 'dim_products', 'facts_sals')

-- Explore All Cuntries our Customer's come FROM. 
SELECT DISTINCT country 
FROM gold.dim_customers

-- Explore All Categories, Subcategories & Products 'The Major Divisions'
SELECT DISTINCT 
	category, 
	subcategory, 
	product_name 
FROM gold.dim_products
ORDER BY 1,2, 3

-- -----------------------------------------------------------------------------------------------------------------
-- Date Exploration
-- -----------------------------------------------------------------------------------------------------------------

-- Find the date of the First & Last Order 
-- How many years of sales are available 
-- The difference between the first and last date in (month, weeks & years)
SELECT 
	MIN(order_date) first_order_date, 
	MAX(order_date) last_order_date, 
	(MAX(order_date) - MIN(order_date))/30 -- Update the number by days depending on clculation 7;weeks,30;months
	order_range_in_years 
FROM gold.facts_sales

-- Find the youngest and oldest customers 
SELECT 
	MIN(birthdate) oldest_birthdate, 
	MAX(birthdate) youngest_birthdate, 
	(CURRENT_DATE - MAX(birthdate))/365 oldest_age, 
	(CURRENT_DATE - MIN(birthdate))/365 youngest_age
FROM gold.dim_customers

-- -----------------------------------------------------------------------------------------------------------------
-- Measures Exploration
-- -----------------------------------------------------------------------------------------------------------------

-- Find the total Sales 
SELECT SUM(sales_amount) total_sales 
FROM gold.facts_sales

-- Find how many Items are sold
SELECT SUM(quantity) total_quantity 
FROM gold.facts_sales

-- Find the Average Selling Price
SELECT AVG(price) average_price 
FROM gold.facts_sales

-- Find the total number of Orders
SELECT COUNT(DISTINCT order_number) total_orders -- Use distinct to find total orders by distinct orders 
FROM gold.facts_sales 

-- Find the total number of Products
SELECT COUNT(product_name) total_products 
FROM gold.dim_products

-- Find the total number of Customers
SELECT COUNT(customer_key) total_customers 
FROM gold.dim_customers

-- Find the total number of Customers that have placed an order 
SELECT COUNT(order_id) total_orders 
FROM gold.facts_sales

-------------------------------------------------------------------------------------------------------------------
-- Generate a Report that shows all key metrics of the business
SELECT 
	'Total Sales' measure_name, 
	SUM(sales_amount) measure_value 
FROM gold.facts_sales
UNION
SELECT 
	'Total Quantity' measure_name, 
	SUM(quantity) measure_value 
FROM gold.facts_sales
UNION
SELECT 
	'Average Price' measure_name, 
	SUM(price) measure_value 
FROM gold.facts_sales
UNION
SELECT 
	'Total Orders' measure_name, 
	COUNT(DISTINCT order_number) measure_value 
FROM gold.facts_sales
UNION
SELECT 
	'Total No. Products' measure_name,
	COUNT(product_name) measure_value 
FROM gold.dim_products
UNION
SELECT 
	'Total No. Customers' measure_name, 
	COUNT(customer_key) measure_value 
FROM gold.dim_customers
UNION
SELECT 
	'Total No. Cust With Orders' measure_name, 
	COUNT(DISTINCT customer_key) measure_value 
FROM gold.facts_sales 
WHERE order_number IS NOT NULL

-- -----------------------------------------------------------------------------------------------------------------
-- Magnitde 
-- -----------------------------------------------------------------------------------------------------------------

-- Find total Customers by Countries 
SELECT 
	country, 
	COUNT(customer_key) total_customers 
FROM gold.dim_customers 
GROUP BY country 
ORDER BY total_customers DESC

-- Find total Customers by Gender 
SELECT 
	gender, 
	COUNT(customer_key) total_customers 
FROM gold.dim_customers 
GROUP BY gender 
ORDER BY total_customers DESC

-- Fnd total Products by Category
SELECT 
	category, 
	COUNT(product_key) total_products 
FROM gold.dim_products 
GROUP BY category 
ORDER BY total_products

-- What is the average cost in each category?
SELECT 
	category, 
	AVG(cost)::INT average_cost 
FROM gold.dim_products 
GROUP BY category 
ORDER BY average_cost DESC

-- What is the total revenue generated from each category?
SELECT 
	p.category,
	SUM(s.sales_amount) total_revenue
FROM gold.facts_sales s
RIGHT JOIN gold.dim_products p
	ON s.product_key = p.product_key
GROUP BY p.category
ORDER BY total_revenue DESC

-- Find that total revenue generated by each customer
SELECT 
	c.customer_key customer,
	c.first_name, 
	c.last_name,
	sum(s.sales_amount) total_revenue
FROM gold.facts_sales s
JOIN gold.dim_customers c
	ON c.customer_key = s.customer_key
GROUP BY 
	c.customer_key,
	c.first_name, 
	c.last_name
ORDER BY total_revenue DESC

-- What is the distribution of sold items accross countries?
SELECT 
	c.country,
	SUM(s.quantity) total_sold_items
FROM gold.facts_sales s
JOIN gold.dim_customers c
	ON c.customer_key = s.customer_key
GROUP BY country
ORDER BY total_sold_items DESC

-- What is the number of customers by Marital status
SELECT 
	marital_status,
	COUNT(customer_key) number_of_married_customers
FROM gold.dim_customers
GROUP BY marital_status
ORDER BY number_of_married_customers DESC

-- -----------------------------------------------------------------------------------------------------------------
-- Ranking Analyzer
-- -----------------------------------------------------------------------------------------------------------------
-- Which 5 Products generated the most revenue?
SELECT
	p.product_name,
	SUM(s.sales_amount) total_sales_amount
FROM gold.facts_sales s
JOIN gold.dim_products p
	ON s.product_key = p.product_key 
GROUP BY p.product_name
ORDER BY total_sales_amount DESC
LIMIT 5

-- What are the 5 worst-performing produts in terms of sales?
SELECT 
	p.product_name,
	SUM(s.sales_amount) total_sales_amount
FROM gold.facts_sales s
JOIN gold.dim_products p
	ON s.product_key = p.product_key 
GROUP BY p.product_name 
ORDER BY total_sales_amount ASC
LIMIT 5

-- Which 5 Subcategories generated the most revenue?
SELECT
	p.subcategory,
	SUM(s.sales_amount) total_sales_amount
FROM gold.facts_sales s
JOIN gold.dim_products p
	ON s.product_key = p.product_key 
GROUP BY p.subcategory
ORDER BY total_sales_amount DESC
LIMIT 5

-- Which 5 Subcategories generated the worst revenue?
SELECT
	p.subcategory,
	SUM(s.sales_amount) total_sales_amount
FROM gold.facts_sales s
JOIN gold.dim_products p
	ON s.product_key = p.product_key 
GROUP BY p.subcategory
ORDER BY total_sales_amount ASC
LIMIT 5

-- Find the top 10 Customers who have generated the highest revenue
SELECT 
	c.customer_key,
	c.first_name,
	c.last_name,
	SUM(s.sales_amount) total_revenue
FROM gold.facts_sales s
JOIN gold.dim_customers c
	ON s.customer_key = c.customer_key
GROUP BY 
	c.customer_key,
	c.first_name,
	c.last_name
ORDER BY total_revenue DESC
LIMIT 10

-- Find the 3 Customers with the fewest orders placed
SELECT 
	c.customer_number,
	c.first_name,
	c.last_name,
	COUNT(DISTINCT s.order_number) total_orders
FROM gold.facts_sales s
JOIN gold.dim_customers c
	ON s.customer_key = c.customer_key
GROUP BY 
	c.customer_number,
	c.first_name,
	c.last_name
ORDER BY total_orders ASC
LIMIT 3
