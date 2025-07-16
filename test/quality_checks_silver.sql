/*
=================================================================================================
Quality Checks
=================================================================================================
Script Purpose:
  This script performes various quality checkes for data consistenncy, accuracy and 
  standardization accross the 'silver' schemas. It includes checks for;
  - Null or duplicate primary keys.
  - Unwanted spaces in string fields.
  - Data standardization and consistency.
  - Invalid data ranges and orders.
  - Data consistency between related fields.

Usage Notes:
  - Run these checks after loading data into Silver Layer.
  - Investigate and resolve any discrepencies during the checks.
=================================================================================================
*/

-- ==============================================================================================
-- Checking silver.crm_cust_info 
-- ==============================================================================================

-- Check For Nulls or Duplicates in Primary Key
-- Expectaion: No Result 

SELECT 
cst_id,
COUNT(*)
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL;


-- Check For Unwanted Spaces
-- Expectation: No Result 
SELECT cst_firstname, cst_lastname
FROM silver.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname);

--Data Standardization & Consistency
SELECT DISTINCT cst_gndr
FROM silver.crm_cust_info;

SELECT DISTINCT cst_marital_status
FROM silver.crm_cust_info;

=================================================================================================

-- ==============================================================================================
-- Checking silver.crm_prd_info
-- ==============================================================================================
  
-- Check For Nulls or Duplicates in Primary Key
-- Expectaion: No Result 
SELECT 
prd_id,
COUNT(*)
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL;


-- Check For Unwanted Spaces
-- Expectation: No Result 
SELECT prd_nm
FROM silver.crm_prd_info
WHERE prd_nm != TRIM(prd_nm);

-- Check For Nulls or Negative Numbers 
-- Expectation: No Results
SELECT prd_cost
FROM silver.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL;

--Data Standardization & Consistency
SELECT DISTINCT prd_line
FROM silver.crm_prd_info;

-- CHeck Invalid Date Orders
SELECT *
FROM silver.crm_prd_info
WHERE prd_end_dt < prd_start_dt

-- Fixing & Testing to make sure end date is alwats after start date 
SELECT 
	prd_id,
	prd_key,
	prd_nm,
	prd_start_dt,
	prd_end_dt,
	LEAD(prd_start_dt) OVER(PARTITION BY prd_key ORDER BY prd_start_dt) -1 prd_end_dt_test
	FROM bronze.crm_prd_info
	WHERE prd_key IN('AC-HE-UH-U509-R', 'AC-HE-HL-U509')

=================================================================================================

-- ==============================================================================================
-- Checking silver.crm_sales_details
-- ==============================================================================================
  
-- Check For Unwanted Spaces 
-- Expectaion: No Results
SELECT * FROM silver.crm_sales_details
WHERE sls_ord_num != TRIM(sls_ord_num);

-- Check For Unwanted Spaces 
-- Expectaions: No Results
SELECT * FROM silver.crm_sales_details
WHERE sls_cust_id NOT IN (SELECT cst_id FROM silver.crm_cust_info)

-- Check For Invalid Dates 
-- Expectaions: No Results 
SELECT NULLIF(sls_due_dt, 0) sls_due_dt
FROM silver.crm_sales_details
WHERE sls_due_dt <= 0
	OR LENGTH(sls_due_dt::TEXT) != 8
	OR sls_due_dt > 20500101 
	OR sls_due_dt < 19000101 

SELECT NULLIF(sls_order_dt,0) sls_due_dt
FROM silver.crm_sales_details
WHERE sls_order_dt <= 0
	OR LENGTH(sls_order_dt::TEXT) != 8
	OR sls_order_dt > 20500101 
	OR sls_order_dt < 19000101 

SELECT NULLIF(sls_ship_dt,0) sls_ship_dt
FROM silver.crm_sales_details
WHERE sls_ship_dt <= 0
	OR LENGTH(sls_ship_dt::TEXT) != 8
	OR sls_ship_dt > 20500101 
	OR sls_ship_dt < 19000101 

-- Check That The Due Date is After The Shipping Date Which is in Turn After The Order Date
-- Expectations: No Results
SELECT *
FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt OR sls_ship_dt > sls_due_dt

-- Check Data Consistency Between Sales, Quantity and Price
-- >> Sales = Quantity * Price
-- >> Values must not be Null, zero or negative
SELECT DISTINCT
	sls_sales,
	sls_quantity,
	sls_price
FROM silver.crm_sales_details
WHERE 
	sls_sales != (sls_quantity * sls_price) 
	OR sls_sales IS NULL
	OR sls_quantity IS NULL
	OR sls_sales <= 0 
	OR sls_quantity <= 0
	OR sls_price <= 0
ORDER BY sls_sales, sls_quantity, sls_price

SELECT * FROM silver.crm_sales_details

=================================================================================================

-- ==============================================================================================
-- Checking silver.erp_cust_az12
-- ==============================================================================================
  
-- Identify Out-Of_Range dates
-- Expectations: No Results 

SELECT bdate
FROM silver.erp_cust_az12
WHERE bdate < '1924-01-01' OR bdate > NOW()

--Checking Invalid Entry In The Gender Column
SELECT DISTINCT gen
FROM silver.erp_cust_az12

=================================================================================================

-- ==============================================================================================
-- For silver.erp_loc_a101
-- ==============================================================================================
  
-- Replacing the '-' in the cid 
-- Expectations: No Results
SELECT 
	REPLACE(cid, '-', '') cid
FROM silver.erp_loc_a101 WHERE REPLACE(cid, '-', '') NOT IN
(SELECT cst_key FROM silver.crm_cust_info)

-- Data Standardization & Consistency for country column
SELECT DISTINCT cntry
FROM silver.erp_loc_a101 
ORDER BY cntry

=================================================================================================

-- ==============================================================================================
-- For silver.erp_px_cat_g1v2
-- ==============================================================================================
  
-- Checking for unwanted spaces 
SELECT *
FROM  bronze.erp_px_cat_g1v2
WHERE cat != TRIM(cat) OR subcat != TRIM(subcat) OR maintenance != TRIM(maintenance) 

-- Data Standardization & Consistency
SELECT DISTINCT cat 
FROM silver.erp_px_cat_g1v2

SELECT DISTINCT subcat 
FROM silver.erp_px_cat_g1v2

SELECT DISTINCT maintenance 
FROM silver.erp_px_cat_g1v2






