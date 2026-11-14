/*
Verificación rápida de la capa Bronze: conteo de filas por tabla.
Esperado: crm_cust_info 18494, crm_prd_info 397, crm_sales_details 60398,
          erp_cust_az12 18484, erp_loc_a101 18484, erp_px_cat_g1v2 37
*/
USE data_warehouse;
GO

SELECT 'crm_cust_info'     AS tabla, COUNT(*) AS filas FROM bronze.crm_cust_info
UNION ALL SELECT 'crm_prd_info',      COUNT(*) FROM bronze.crm_prd_info
UNION ALL SELECT 'crm_sales_details', COUNT(*) FROM bronze.crm_sales_details
UNION ALL SELECT 'erp_cust_az12',     COUNT(*) FROM bronze.erp_cust_az12
UNION ALL SELECT 'erp_loc_a101',      COUNT(*) FROM bronze.erp_loc_a101
UNION ALL SELECT 'erp_px_cat_g1v2',   COUNT(*) FROM bronze.erp_px_cat_g1v2;
GO

-- Vistazo a los datos
SELECT TOP 10 * FROM bronze.crm_cust_info;
SELECT TOP 10 * FROM bronze.crm_sales_details;
GO
