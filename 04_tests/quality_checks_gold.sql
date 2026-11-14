/*
=============================================================
Pruebas de calidad: capa Gold
=============================================================
Cada consulta debe devolver 0 filas (o el valor esperado indicado).
=============================================================
*/
USE data_warehouse;
GO

-- Claves subrogadas únicas ---------------------------------------------
-- Esperado: sin filas
SELECT customer_key, COUNT(*) AS veces FROM gold.dim_customers GROUP BY customer_key HAVING COUNT(*) > 1;
SELECT product_key,  COUNT(*) AS veces FROM gold.dim_products  GROUP BY product_key  HAVING COUNT(*) > 1;

-- Sin duplicados por clave de negocio -----------------------------------
-- Esperado: sin filas
SELECT customer_id,    COUNT(*) AS veces FROM gold.dim_customers GROUP BY customer_id    HAVING COUNT(*) > 1;
SELECT product_number, COUNT(*) AS veces FROM gold.dim_products  GROUP BY product_number HAVING COUNT(*) > 1;

-- Integridad del modelo (hechos -> dimensiones) -------------------------
-- Esperado: sin filas (ventas que no encuentran su cliente o producto)
SELECT f.order_number, f.customer_key, f.product_key
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_customers AS c ON c.customer_key = f.customer_key
LEFT JOIN gold.dim_products  AS p ON p.product_key  = f.product_key
WHERE c.customer_key IS NULL OR p.product_key IS NULL;

-- Conteos esperados -----------------------------------------------------
-- dim_customers 18484 | dim_products 295 | fact_sales 60398
SELECT 'dim_customers' AS vista, COUNT(*) AS filas FROM gold.dim_customers
UNION ALL SELECT 'dim_products', COUNT(*) FROM gold.dim_products
UNION ALL SELECT 'fact_sales',   COUNT(*) FROM gold.fact_sales;

-- Consulta de ejemplo: ventas por categoría y país ----------------------
SELECT TOP 10
    p.category,
    c.country,
    SUM(f.sales_amount) AS total_ventas
FROM gold.fact_sales AS f
JOIN gold.dim_products  AS p ON p.product_key  = f.product_key
JOIN gold.dim_customers AS c ON c.customer_key = f.customer_key
GROUP BY p.category, c.country
ORDER BY total_ventas DESC;
GO
