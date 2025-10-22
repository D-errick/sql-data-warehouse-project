/* 
====================================================================
Quality Checks
====================================================================
Script purpose:
This script performs various quality checks such as checking for duplicates,
data consistency, accuracy, data standardization across the 'silver' schema.
It includes checks for:
-Null or duplicate primary keys
-unwanted spaces in string columns
-data standardization and consistency
-invalid date ranges and orders
-data consistency btwn related fields
*/


-- Check for Nulls or Duplicates in primary key
-- Expectation: No result
SELECT *
FROM silver.crm_prd_info;

SELECT prd_id,
COUNT(*)
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL;


-- Check unwanted spaces
-- Expectation: No Results
select prd_nm
FROM silver.crm_prd_info
where prd_nm != TRIM(prd_nm);


-- Data Standardization and consistency
SELECT DISTINCT gen
FROM silver.erp_cust_az12

-- Checking for invalid dates
SELECT *
FROM silver.crm_sales_details
WHERE sls_order_dt > sls_due_dt OR sls_order_dt > sls_ship_dt;

SELECT DISTINCT cntry
FROM [DataWarehouse].[silver].[erp_loc_a101]
ORDER BY cntry


SELECT DISTINCT *
FROM [DataWarehouse].[silver].[erp_loc_a101]
