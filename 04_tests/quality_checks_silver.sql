/*
=============================================================
Pruebas de calidad: capa Silver
=============================================================
Cada consulta debe devolver 0 filas (o el valor esperado indicado).
Si devuelve filas, hay un problema de calidad que revisar.
=============================================================
*/
USE data_warehouse;
GO

-- silver.crm_cust_info -------------------------------------------------
-- Esperado: sin filas (ID nulo o duplicado)
SELECT cst_id, COUNT(*) AS veces
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL;

-- Esperado: sin filas (espacios sobrantes)
SELECT cst_firstname, cst_lastname
FROM silver.crm_cust_info
WHERE cst_firstname <> TRIM(cst_firstname) OR cst_lastname <> TRIM(cst_lastname);

-- Esperado: solo Single / Married / n/a  y  Female / Male / n/a
SELECT DISTINCT cst_marital_status, cst_gndr FROM silver.crm_cust_info;

-- silver.crm_prd_info --------------------------------------------------
-- Esperado: sin filas (fecha fin anterior a la fecha inicio)
SELECT prd_id, prd_key, prd_start_dt, prd_end_dt
FROM silver.crm_prd_info
WHERE prd_end_dt < prd_start_dt;

-- Esperado: sin filas (costo nulo o negativo)
SELECT prd_id, prd_cost FROM silver.crm_prd_info WHERE prd_cost IS NULL OR prd_cost < 0;

-- Esperado: sin filas (cada producto debe tener exactamente una versión vigente)
SELECT prd_key
FROM silver.crm_prd_info
GROUP BY prd_key
HAVING SUM(CASE WHEN prd_end_dt IS NULL THEN 1 ELSE 0 END) <> 1;

-- silver.crm_sales_details ---------------------------------------------
-- Esperado: sin filas (ventas/precio inválidos o que no cuadran)
SELECT sls_ord_num, sls_sales, sls_quantity, sls_price
FROM silver.crm_sales_details
WHERE sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
   OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <= 0
   OR sls_sales <> sls_quantity * sls_price;

-- Esperado: sin filas (fecha de pedido posterior a envío o vencimiento)
SELECT sls_ord_num, sls_order_dt, sls_ship_dt, sls_due_dt
FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt;

-- Informativo: pedidos sin fecha de pedido (en el origen venían con valores inválidos). Esperado: 19
SELECT COUNT(*) AS pedidos_sin_fecha FROM silver.crm_sales_details WHERE sls_order_dt IS NULL;

-- silver.erp_cust_az12 -------------------------------------------------
-- Esperado: sin filas (fecha de nacimiento en el futuro)
SELECT cid, bdate FROM silver.erp_cust_az12 WHERE bdate > GETDATE();

-- Esperado: solo Female / Male / n/a
SELECT DISTINCT gen FROM silver.erp_cust_az12;

-- Esperado: sin filas (el cid ya no debe llevar el prefijo NAS)
SELECT cid FROM silver.erp_cust_az12 WHERE cid LIKE 'NAS%';

-- silver.erp_loc_a101 --------------------------------------------------
-- Esperado: países estandarizados (sin DE, US, USA ni vacíos)
SELECT DISTINCT cntry FROM silver.erp_loc_a101 ORDER BY cntry;

-- Esperado: sin filas (el cid ya no debe llevar guiones)
SELECT cid FROM silver.erp_loc_a101 WHERE cid LIKE '%-%';
GO
