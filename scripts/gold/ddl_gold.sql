/*
==================================================================================
DDL Script: Create Gold Views
==================================================================================
Script Purpose: 
  This Script creates views for the Gold layer in the data warehouse.
  The Gold layer represents the final dimention and fact tables (Star Schema)

  Each view performs transformations and combines data from the silver layer
  to produce clean, enriched, and business-ready datasets.

Usage:
  - These views can be queried directly for analytics and reporting.
==================================================================================
*/

-- ===============================================================================
-- Create Dimention Table: gold.dim_customers
-- ===============================================================================
CREATE VIEW gold.dim_customers AS
SELECT
	ROW_NUMBER() OVER(ORDER BY cst_id) customer_key,
	ci.cst_id customer_id,
	ci.cst_key customer_number,
	ci.cst_firstname first_name,
	ci.cst_lastname last_name,
	la.cntry country,
	ci.cst_marital_status marital_status,
	CASE WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr -- CRM is the Master tabled for gender Info
		ELSE COALESCE(ca.gen, 'n/a')
	END gender,
	ca.bdate birthdate,
	ci.cst_create_date create_date
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca
	ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 la
	ON ci.cst_key = la.cid
  
-- ===============================================================================
-- Create Dimention Table: gold.dim_products
-- ===============================================================================


CREATE VIEW gold.dim_products AS 
SELECT
	ROW_NUMBER() OVER (ORDER BY pn.prd_start_dt, pn.prd_key) product_key,
	pn.prd_id product_id,
	pn.prd_key product_number,
	pn.prd_nm product_name,
	pn.cat_id category_id,
	pc.cat category,
	pc.subcat subcategory,
	pc.maintenance, 
	pn.prd_cost cost,
	pn.prd_line product_line,
	pn.prd_start_dt	start_date
FROM silver.crm_prd_info pn
LEFT JOIN silver.erp_px_cat_g1v2 pc
	ON pn.cat_id = pc.id
WHERE pn.prd_end_dt IS NULL -- Filter out all historicl data

-- ===============================================================================
-- Create Fact Table: gold.fact_sales
-- ===============================================================================
  
CREATE VIEW gold.facts_sales AS
SELECT 
	sd.sls_ord_num order_number,
	pr.product_key,
	cu.customer_key,
	sd.sls_order_dt order_date,
	sd.sls_ship_dt shipping_date,
	sd.sls_due_dt due_date,
	sd.sls_sales sales_amount,
	sd.sls_quantity quantity,
	sd.sls_price price
FROM silver.crm_sales_details sd
LEFT JOIN gold.dim_products pr
	ON sd.sls_prd_key = pr.product_number
LEFT JOIN gold.dim_customers cu
	ON sd.sls_cust_id = cu.customer_id
