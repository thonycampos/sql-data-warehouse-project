/*
=============================================================
DDL: Crear la capa Gold (modelo estrella)
=============================================================
Propósito:
    Crea las vistas del esquema 'gold' que integran CRM y ERP en un
    modelo dimensional (esquema en estrella):

        gold.dim_customers  (dimensión de clientes)
        gold.dim_products   (dimensión de productos)
        gold.fact_sales     (tabla de hechos de ventas)

    Cada vez que se consulta una vista, se leen los datos actuales de Silver.
    Las claves subrogadas (customer_key, product_key) se generan con
    ROW_NUMBER().

Ejecutar DESPUÉS de cargar Silver (EXEC silver.load_silver).
=============================================================
*/

USE data_warehouse;
GO

-- =============================================================
-- Dimensión: gold.dim_customers
-- =============================================================
CREATE OR ALTER VIEW gold.dim_customers AS
SELECT
    ROW_NUMBER() OVER (ORDER BY ci.cst_id)  AS customer_key,     -- clave subrogada
    ci.cst_id                               AS customer_id,
    ci.cst_key                              AS customer_number,
    ci.cst_firstname                        AS first_name,
    ci.cst_lastname                         AS last_name,
    ISNULL(la.cntry, 'n/a')                 AS country,
    ci.cst_marital_status                   AS marital_status,
    CASE
        WHEN ci.cst_gndr <> 'n/a' THEN ci.cst_gndr           -- el CRM es la fuente principal
        ELSE ISNULL(ca.gen, 'n/a')                            -- si el CRM no tiene dato, se usa el ERP
    END                                     AS gender,
    ca.bdate                                AS birthdate,
    ci.cst_create_date                      AS create_date
FROM silver.crm_cust_info AS ci
LEFT JOIN silver.erp_cust_az12 AS ca ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101  AS la ON ci.cst_key = la.cid;
GO

-- =============================================================
-- Dimensión: gold.dim_products
-- (solo la versión vigente de cada producto: prd_end_dt IS NULL)
-- =============================================================
CREATE OR ALTER VIEW gold.dim_products AS
SELECT
    ROW_NUMBER() OVER (ORDER BY pn.prd_start_dt, pn.prd_key) AS product_key,  -- clave subrogada
    pn.prd_id                       AS product_id,
    pn.prd_key                      AS product_number,
    pn.prd_nm                       AS product_name,
    pn.cat_id                       AS category_id,
    ISNULL(pc.cat, 'n/a')           AS category,
    ISNULL(pc.subcat, 'n/a')        AS subcategory,
    ISNULL(pc.maintenance, 'n/a')   AS maintenance,
    pn.prd_cost                     AS cost,
    pn.prd_line                     AS product_line,
    pn.prd_start_dt                 AS start_date
FROM silver.crm_prd_info AS pn
LEFT JOIN silver.erp_px_cat_g1v2 AS pc ON pn.cat_id = pc.id
WHERE pn.prd_end_dt IS NULL;
GO

-- =============================================================
-- Hechos: gold.fact_sales
-- =============================================================
CREATE OR ALTER VIEW gold.fact_sales AS
SELECT
    sd.sls_ord_num   AS order_number,
    pr.product_key   AS product_key,      -- llave hacia dim_products
    cu.customer_key  AS customer_key,     -- llave hacia dim_customers
    sd.sls_order_dt  AS order_date,
    sd.sls_ship_dt   AS shipping_date,
    sd.sls_due_dt    AS due_date,
    sd.sls_sales     AS sales_amount,
    sd.sls_quantity  AS quantity,
    sd.sls_price     AS price
FROM silver.crm_sales_details AS sd
LEFT JOIN gold.dim_products  AS pr ON sd.sls_prd_key = pr.product_number
LEFT JOIN gold.dim_customers AS cu ON sd.sls_cust_id = cu.customer_id;
GO
