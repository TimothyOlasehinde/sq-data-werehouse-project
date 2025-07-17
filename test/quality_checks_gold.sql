/*
==================================================================================
Quality Checks
==================================================================================
Script Purpose:
  This script perofms quality checks to validate the integrity, consistency,
  and accuracy of the Gold Layer. 
  The checks ensure:
  - Uniqueness of surrogate keys in the dimention tables.
  - Refrential integrity between fact and dimention tables.
  - Validation of relationships in the data model for analytical purposes.

Usage:
  - Run these checks after date loadining Silver Layer.
  - Investigae and resolve any discrepencies found during the checks. 
=====================================================================================
*/

-- ==================================================================================
-- Checks 'gold.dim_customers'
-- ==================================================================================
-- Checks for uniqueness of Customer key in gold.dim_customers
-- Expectation: No Resuls
SELECT 
    customer_key,
    COUNT(*), AS duplicate_count
FROM gold.dim_customers
GROUP BY customer_key
HAVING COUNT(*) > 1;
=====================================================================================

SELECT DISTINCT 
	ci.cst_gndr,
	ca.gen,
	CASE WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr -- CRM is the Master tabled for gender Info
		ELSE COALESCE(ca.gen, 'n/a')
	END new_gen
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca
	ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 la
	ON ci.cst_key = la.cid
ORDER BY 1, 2
  
-- ==================================================================================
-- Checking that the dimentions tables are properly matched to the facts table
-- ==================================================================================  
-- Expectaions: No Result
  
SELECT * FROM gold.facts_sales f
	LEFT JOIN gold.dim_products p 
	ON p.product_key =f.product_key
	WHERE p.product_key IS NULL

SELECT * FROM gold.facts_sales f
	LEFT JOIN gold.dim_customers c 
	ON c.customer_key =f.customer_key
	WHERE c.customer_key IS NULL
