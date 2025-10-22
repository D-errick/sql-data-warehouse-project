CREATE VIEW gold.dim_customers AS
SELECT
        ROW_NUMBER() OVER(ORDER BY ci.cst_id) AS customer_key,
		ci.cst_id AS customer_id,
		ci.cst_key AS customer_number,
		ci.cst_firstname AS first_name,
		ci.cst_lastname AS last_name,
		la.cntry AS country,
		ci.cst_marital_status AS marital_status,
		CASE WHEN ci.cst_gndr != 'N/A' THEN ci.cst_gndr
			 ELSE COALESCE(ca.gen, 'N/A')
		END AS gender,
		ci.cst_create_date AS create_date,
		ca.bdate AS birthdate		
FROM [DataWarehouse].[silver].[crm_cust_info] ci
LEFT JOIN silver.erp_cust_az12 ca
ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 la
ON ci.cst_key = la.cid;




CREATE VIEW gold.dim_products AS
SELECT
    ROW_NUMBER() OVER(ORDER BY pn.prd_start_dt, pn.prd_id) AS product_key,
	pn.prd_id AS product_id,
	pn.prd_key AS product_number,
	pn.prd_nm AS product_name,
	pn.cat_id AS category_id,
	pc.cat AS category,
	pc.subcat AS subcategory,
	pc.maintenance,
	pn.prd_cost AS cost,
	pn.prd_line AS product_line,
	pn.prd_start_dt AS start_date
FROM [DataWarehouse].[silver].[crm_prd_info] pn
LEFT JOIN silver.erp_px_cat_g1v2 pc
ON pn.cat_id = pc.id
WHERE pn.prd_end_dt IS NULL;  -- Filters out all historic data


CREATE VIEW gold.sales_fact AS 
SELECT
        sls_ord_num AS order_number,
        pr.product_key,
        cu.customer_id,
        sls_order_dt AS order_date,
        sls_ship_dt AS shipping_date,
        sls_due_dt AS due_date,
        sls_sales AS sales_amount,
        sls_quantity AS quantity,
        sls_price   AS price     
FROM [DataWarehouse].[silver].[crm_sales_details] sd
LEFT JOIN gold.dim_products pr
ON sd.sls_prd_key = pr.product_number
LEFT JOIN gold.dim_customers cu
ON sd.sls_cust_id = cu.customer_id

