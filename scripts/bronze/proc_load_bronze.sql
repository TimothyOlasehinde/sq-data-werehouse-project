/*
=====================================================================================================================
Stored Procedure: Load Bronze Layer ( Source -> Bronze)
=====================================================================================================================
Script Purpose:
  This stored procedure loads data into the 'bronze' schema from external csv files.
  It performs the following functions:
  - Truncates the bronze tables before loading data.
  - Use the 'Copy' command for 'postgresql' to load data from csv files to bronze tables. 

Parameters:
  None.
This stored procedure does not accept any parameters or return any values. 

Usage Example:
  CALL bronze.load_bronze;
=====================================================================================================================
*/

CREATE OR REPLACE PROCEDURE 
	bronze.load_bronze ()
	LANGUAGE plpgsql
	AS $$
	
	DECLARE	
		s_starttime TIMESTAMP; e_endtime TIMESTAMP; b_batchstart TIMESTAMP; b_batchend TIMESTAMP;
	BEGIN
		b_batchstart = NOW();
		
		RAISE INFO '====================================================';
		RAISE INFO 'Loading Bronze Layer';
		RAISE INFO '====================================================';
	
		RAISE INFO '----------------------------------------------------';
		RAISE INFO 'Loading CRM Data';
		RAISE INFO '----------------------------------------------------';
		s_starttime = NOW();
		
		RISE INFO '>> Truncating Table: bronze.crm_cust_info';
		TRUNCATE TABLE bronze.crm_cust_info;
	
		RAISE INFO '>> Inserting Data Into: bronze.crm_cust_info';
		COPY bronze.crm_cust_info
		FROM '/Applications/DATE SCI PROJ/sqlProject_files/sql-data-warehouse-project/datasets/source_crm/cust_info.csv'
		DELIMITER ','
		CSV HEADER;
		e_endtime = NOW();
		RAISE INFO '>>Load Duration: ';
		RAISE INFO '%', CAST(e_endtime - s_starttime AS VARCHAR); 
		RAISE INFO '>> ---------------------------------------------';
		
		s_starttime = NOW();
		RAISE INFO '>> Truncating Table:bronze.crm_prd_info';
		TRUNCATE TABLE bronze.crm_prd_info;
	
		RAISE INFO '>> Inserting Data Into: bronze.crm_prd_info';
		COPY bronze.crm_prd_info
		FROM '/Applications/DATE SCI PROJ/sqlProject_files/sql-data-warehouse-project/datasets/source_crm/prd_info.csv'
		DELIMITER ','
		CSV HEADER;
		e_endtime = NOW();
		RAISE INFO '>>Load Duration: ';
		RAISE INFO '%', CAST(e_endtime - s_starttime AS VARCHAR);
		RAISE INFO '>> ----------------------------------------------';
		
		s_starttime = NOW();
		RAISE INFO '>> Truncating Table: bronze.crm_sales_details';
		TRUNCATE TABLE bronze.crm_sales_details;
	
		RAISE INFO '>> Inserting Data Into: bronze.crm_sales_details';
		COPY bronze.crm_sales_details
		FROM '/Applications/DATE SCI PROJ/sqlProject_files/sql-data-warehouse-project/datasets/source_crm/sales_details.csv'
		DELIMITER ','
		CSV HEADER;
		e_endtime = NOW();
		RAISE INFO '>>Load Duration: ';
		RAISE INFO '%', CAST(e_endtime - s_starttime AS VARCHAR);
		RAISE INFO '>> ------------------------------------------------';
	    
		RAISE INFO '-----------------------------------------------------';
		RAISE INFO 'Loading ERP Data';
		RAISE INFO '-----------------------------------------------------';

		s_starttime = NOW();
		RAISE INFO '>> Truncating Table: bronze.erp_cust_az12';
		TRUNCATE TABLE bronze.erp_cust_az12;
	
		RAISE INFO '>> Inserting Data Into: bronze.erp_cust_az12';
		COPY bronze.erp_cust_az12
		FROM '/Applications/DATE SCI PROJ/sqlProject_files/sql-data-warehouse-project/datasets/source_erp/CUST_AZ12.csv'
		DELIMITER ','
		CSV HEADER;
		e_endtime = NOW();
		RAISE INFO '>>Load Duration: ';
		RAISE INFO '%', CAST(e_endtime - s_starttime AS VARCHAR);
		RAISE INFO '>> -----------------------------------------------';

		s_starttime = NOW();
		RAISE INFO '>> Truncating Table: bronze.erp_loc_a101';
		TRUNCATE TABLE bronze.erp_loc_a101;
	
		RAISE INFO '>> Inserting Data Into: bronze.erp_loc_a101';
		COPY bronze.erp_loc_a101
		FROM '/Applications/DATE SCI PROJ/sqlProject_files/sql-data-warehouse-project/datasets/source_erp/LOC_A101.csv'
		DELIMITER ','
		CSV HEADER;
		e_endtime = NOW();
		RAISE INFO '>>Load Duration: ';
		RAISE INFO '%', CAST(e_endtime - s_starttime AS VARCHAR);
		RAISE INFO '>> ---------------------------------------------';

		s_starttime = NOW();
		RAISE INFO '>> Truncating Table: bronze.erp_px_cat_g1v2';
		TRUNCATE TABLE bronze.erp_px_cat_g1v2;
	
		RAISE INFO '>> Inserting Data Into: bronze.erp_px_cat_g1v2';
		COPY bronze.erp_px_cat_g1v2
		FROM '/Applications/DATE SCI PROJ/sqlProject_files/sql-data-warehouse-project/datasets/source_erp/PX_CAT_G1V2.csv'
		DELIMITER ','
		CSV HEADER;
		e_endtime = NOW();
		RAISE INFO '>>Load Duration: ';
		RAISE INFO '%', CAST(e_endtime - s_starttime AS VARCHAR);
		RAISE INFO '>> ===================================================';

		b_batchend = NOW();
		RAISE INFO 'Loading Bronze Layer is completed';
		RAISE INFO '>> Load Duration';
		RAISE INFO '%', CAST(b_batchstart - b_batchend AS VARCHAR);

		EXCEPTION WHEN OTHERS THEN
			RAISE INFO '===================================================';
			RAISE WARNING 'ERROR OCCOURED DURING LOADING BRONZE LAYER';
			RAISE WARNING '%','Error Message' + ERROR_MESSAGE();
			RAISE WARNING '%','Error Message' + CAST (ERROR_NUMBER() AS VARCHAR);
			RAISE WARNING '%','Error Message' + CAST (ERROR_STATE() AS VARCHAR);
			RAISE INFO '===================================================';
		
		END; $$; 
		
	
END; 

CALL bronze.load_bronze ()



