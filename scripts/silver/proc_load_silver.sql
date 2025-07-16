/*
===============================================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
===============================================================================================
Script Purpose:
  This stored procedure performes the ETL (Extract, Transform, Load) process 
  to populate the 'silver' schema tables from the 'bronze' schema.
Actiions Performed:
  - Truncates Silver Tables.
  - Inserts transformed and cleansed data from Bronze into Silver tables. 

Parameters:
  None.
  This stored procedure does not accept any parameters or return any values.

Usage Example:
  CALL silver.load_silver();
===============================================================================================
*/

CREATE OR REPLACE PROCEDURE silver.load_silver()
LANGUAGE plpgsql 
AS $$

DECLARE
 s_starttime TIMESTAMP; e_endtime TIMESTAMP; b_batchstart TIMESTAMP; b_batchend TIMESTAMP;
BEGIN
	b_batchstart = NOW();
	
	RAISE INFO '=================================================================================';
	RAISE INFO ' Truncating & Loading Silver Tables';
	RAISE INFO '=================================================================================';	
	
		RAISE INFO '-------------------------------------------------------------------------------';
		RAISE INFO '>> Loading CRM Tables';
		RAISE INFO '-------------------------------------------------------------------------------';

		s_starttime = NOW();
		RAISE INFO '>> Truncating Table:  silver.crm_cust_info';
		TRUNCATE TABLE  silver.crm_cust_info;
		RAISE INFO '>> Inserting Data Into Table:  silver.crm_cust_info';
		INSERT INTO silver.crm_cust_info(
			cst_id,
			cst_key,
			cst_firstname,
			cst_lastname,
			cst_marital_status,
			cst_gndr,
			cst_create_date
		)
		SELECT
			cst_id,
			cst_key,
			TRIM(cst_firstname) cst_firstname,
			TRIM(cst_lastname) cst_lastname,
			CASE WHEN cst_marital_status = 'M' THEN 'Married'
				 WHEN cst_marital_status = 'S' THEN 'Single'
				 ELSE 'n/a'
			END cst_marital_status,  -- Normalize marital status values to readable format
			CASE WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
				WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
				ELSE 'n/a'
			END cst_gndr,  -- Normalize gender valuse to readable formart
			cst_create_date
		FROM 
			(
			SELECT 
				* ,
				ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
			FROM bronze.crm_cust_info 
			WHERE cst_id IS NOT NULL)
		WHERE flag_last = 1; -- Select the most recent record per customer 
		e_endtime = NOW();
		RAISE INFO '>>Load Duration: ';
		RAISE INFO '%', CAST(e_endtime - s_starttime AS VARCHAR); 
		
		RAISE INFO '-------------------------------------------------------------------------------';

		s_starttime = NOW();
		RAISE INFO '>> Truncating Table: silver.crm_prd_info';
		TRUNCATE TABLE  silver.crm_prd_info;
		RAISE INFO '>> Inserting Data Into Table: silver.crm_prd_info';
		INSERT INTO silver.crm_prd_info(
			prd_id,
			cat_id,
			prd_key,
			prd_nm,
			prd_cost,
			prd_line,
			prd_start_dt,
			prd_end_dt
		)
		SELECT 
			prd_id,
			REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') cat_id, -- Extract category ID
			SUBSTRING(prd_key, 7, LENGTH(prd_key)) prd_key,     -- Extract product key
			prd_nm,
			COALESCE(prd_cost, 0) prd_cost,
			CASE UPPER(TRIM(prd_line))
				 WHEN 'M' THEN 'Mountain'
				 WHEN 'R' THEN 'Road'
				 WHEN 'S' THEN 'Other Sales'
				 WHEN 'T' THEN 'Touring'
				 ELSE 'n/a'
			END prd_line, -- Map product line codes to descriptive values
			prd_start_dt,
			CAST(
				LEAD(prd_start_dt) OVER(PARTITION BY prd_key ORDER BY prd_start_dt) -1 AS DATE
				) AS prd_end_dt -- Calculate end date as one day before the next start date
		FROM bronze.crm_prd_info;
		e_endtime = NOW();
		RAISE INFO '>>Load Duration: ';
		RAISE INFO '%', CAST(e_endtime - s_starttime AS VARCHAR); 
	
		RAISE INFO '-------------------------------------------------------------------------------';

		s_starttime = NOW();
		RAISE INFO '>> Truncating Table: silver.crm_prd_info';
		TRUNCATE TABLE  silver.crm_prd_info;
		RAISE INFO '>> Inserting Data Into Table: silver.crm_prd_info';
		INSERT INTO silver.crm_prd_info(
			prd_id,
			cat_id,
			prd_key,
			prd_nm,
			prd_cost,
			prd_line,
			prd_start_dt,
			prd_end_dt
		)
		SELECT 
			prd_id,
			REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') cat_id, -- Extract category ID
			SUBSTRING(prd_key, 7, LENGTH(prd_key)) prd_key,     -- Extract product key
			prd_nm,
			COALESCE(prd_cost, 0) prd_cost,
			CASE UPPER(TRIM(prd_line))
				 WHEN 'M' THEN 'Mountain'
				 WHEN 'R' THEN 'Road'
				 WHEN 'S' THEN 'Other Sales'
				 WHEN 'T' THEN 'Touring'
				 ELSE 'n/a'
			END prd_line, -- Map product line codes to descriptive values
			prd_start_dt,
			CAST(
				LEAD(prd_start_dt) OVER(PARTITION BY prd_key ORDER BY prd_start_dt) -1 AS DATE
				) AS prd_end_dt -- Calculate end date as one day before the next start date
		FROM bronze.crm_prd_info;
		e_endtime = NOW();
		RAISE INFO '>>Load Duration: ';
		RAISE INFO '%', CAST(e_endtime - s_starttime AS VARCHAR); 
		
		RAISE INFO '-------------------------------------------------------------------------------';
		RAISE INFO '>> Loading ERP Tables';
		RAISE INFO '-------------------------------------------------------------------------------';
		
		RAISE INFO '-------------------------------------------------------------------------------';

		s_starttime = NOW();
		RAISE INFO '>> Truncating Table: silver.erp_cust_az12';
		TRUNCATE TABLE  silver.erp_cust_az12;
		RAISE INFO '>> Inserting Data Into Table: silver.erp_cust_az12';
		INSERT INTO silver.erp_cust_az12(
			cid,
			bdate,
			gen
		)
		SELECT 
			CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LENGTH(cid)) -- Remove 'NAS' prefix if present 
				 ELSE cid
			END cid,
			CASE WHEN bdate > NOW() THEN NULL
				 ELSE bdate -- set future birthdays to NULL
			END bdate,
			CASE WHEN UPPER(TRIM(gen)) IN('M', 'MALE') THEN 'Male'
				 WHEN UPPER(TRIM(gen)) IN('F', 'FEMALE') THEN 'Female'
				 ELSE 'n/a'
			END gen  -- Norrmalize gender values and handle unknown cases
		FROM bronze.erp_cust_az12;
		e_endtime = NOW();
		RAISE INFO '>>Load Duration: ';
		RAISE INFO '%', CAST(e_endtime - s_starttime AS VARCHAR); 

		RAISE INFO '-------------------------------------------------------------------------------';

		s_starttime = NOW();
		RAISE INFO '>> Truncating Table: silver.erp_loc_a101';
		TRUNCATE TABLE  silver.erp_loc_a101;
		RAISE INFO '>> Inserting Data Into Table: silver.erp_loc_a101';
		INSERT INTO silver.erp_loc_a101(
			cid,
			cntry
		)
		SELECT DISTINCT
			REPLACE(cid, '-', '') cid,
			CASE WHEN UPPER(TRIM(cntry)) = 'DE' THEN 'Germany'
				WHEN UPPER(TRIM(cntry)) IN ('US', 'USA') THEN 'United States'
				WHEN UPPER(TRIM(cntry)) = '' OR cntry IS NULL THEN 'n/a'
				ELSE TRIM(cntry)
			END cntry -- Normalized or removed blank country codes
		FROM bronze.erp_loc_a101;	
		e_endtime = NOW();
		RAISE INFO '>>Load Duration: ';
		RAISE INFO '%', CAST(e_endtime - s_starttime AS VARCHAR); 
		
		
		RAISE INFO '-------------------------------------------------------------------------------';
		
		s_starttime = NOW();
		RAISE INFO '>> Truncating Table: silver.erp_px_cat_g1v2';
		TRUNCATE TABLE silver.erp_px_cat_g1v2;
		RAISE INFO '>> Inserting Data Into Table: silver.erp_px_cat_g1v2';
		INSERT INTO silver.erp_px_cat_g1v2(
			id,
		    cat,
		    subcat,
		    maintenance
		)
		SELECT
		    id,
		    cat,
		    subcat,
		    maintenance
		FROM bronze.erp_px_cat_g1v2;
		e_endtime = NOW();
		RAISE INFO '>>Load Duration: ';
		RAISE INFO '%', CAST(e_endtime - s_starttime AS VARCHAR); 

	b_batchend = NOW();
	RAISE INFO 'Loading Silver Layer is completed';
	RAISE INFO '>> Load Duration';
	RAISE INFO '%', CAST(b_batchstart - b_batchend AS VARCHAR) + ' seconds';

	EXCEPTION WHEN OTHERS THEN

END $$;

CALL silver.load_silver();







