/*
=============================================================
Procedimiento almacenado: silver.load_silver
=============================================================
Propósito:
    Limpia y transforma los datos de Bronze y los carga en Silver.
    Por cada tabla: la vacía (TRUNCATE) y la llena con INSERT ... SELECT.

Uso:
    EXEC silver.load_silver;

Reglas de limpieza (resumen):
  crm_cust_info
    - Se descartan filas sin cst_id y se deja un solo registro por cliente
      (el de cst_create_date más reciente).
    - Se quitan espacios sobrantes en nombres y apellidos.
    - Estado civil y género se estandarizan (Single/Married, Female/Male,
      'n/a' si no hay dato).
  crm_prd_info
    - prd_key se separa en cat_id (primeros 5 caracteres, "-" -> "_") y
      prd_key (resto).
    - Costo nulo -> 0. Línea de producto: M/R/S/T -> nombre completo.
    - prd_end_dt se recalcula: día anterior al inicio de la siguiente
      versión del mismo producto (en el origen había fechas fin
      anteriores a la fecha de inicio).
  crm_sales_details
    - Fechas INT (yyyymmdd) -> DATE; valores inválidos (0, largo != 8) -> NULL.
    - Ventas = cantidad * |precio| cuando falta, es <= 0 o no coincide.
    - Precio nulo o <= 0 -> ventas / cantidad.
  erp_cust_az12
    - cid: se quita el prefijo 'NAS' para que coincida con cst_key del CRM.
    - Fechas de nacimiento futuras -> NULL.
    - Género estandarizado.
  erp_loc_a101
    - cid: se quitan los guiones. País: DE -> Germany, US/USA -> United States,
      vacío -> 'n/a'.
  erp_px_cat_g1v2
    - Solo se limpian espacios.

Ejecutar DESPUÉS de ddl_silver.sql y de haber cargado Bronze.
=============================================================
*/

USE data_warehouse;
GO

CREATE OR ALTER PROCEDURE silver.load_silver
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @start_time  DATETIME;
    DECLARE @batch_start DATETIME = GETDATE();

    BEGIN TRY
        PRINT '================================================';
        PRINT 'Cargando capa Silver';
        PRINT '================================================';

        -- ---------------------------------------------------
        -- silver.crm_cust_info
        -- ---------------------------------------------------
        SET @start_time = GETDATE();
        PRINT '>> Cargando: silver.crm_cust_info';
        TRUNCATE TABLE silver.crm_cust_info;
        INSERT INTO silver.crm_cust_info (
            cst_id, cst_key, cst_firstname, cst_lastname,
            cst_marital_status, cst_gndr, cst_create_date
        )
        SELECT
            cst_id,
            cst_key,
            ISNULL(NULLIF(TRIM(cst_firstname), ''), 'n/a'),
            ISNULL(NULLIF(TRIM(cst_lastname), ''), 'n/a'),
            CASE UPPER(TRIM(cst_marital_status))
                WHEN 'S' THEN 'Single'
                WHEN 'M' THEN 'Married'
                ELSE 'n/a'
            END,
            CASE UPPER(TRIM(cst_gndr))
                WHEN 'F' THEN 'Female'
                WHEN 'M' THEN 'Male'
                ELSE 'n/a'
            END,
            cst_create_date
        FROM (
            SELECT *,
                   ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
            FROM bronze.crm_cust_info
            WHERE cst_id IS NOT NULL
        ) AS t
        WHERE flag_last = 1;
        PRINT '   Segundos: ' + CAST(DATEDIFF(SECOND, @start_time, GETDATE()) AS NVARCHAR(20));

        -- ---------------------------------------------------
        -- silver.crm_prd_info
        -- ---------------------------------------------------
        SET @start_time = GETDATE();
        PRINT '>> Cargando: silver.crm_prd_info';
        TRUNCATE TABLE silver.crm_prd_info;
        INSERT INTO silver.crm_prd_info (
            prd_id, cat_id, prd_key, prd_nm, prd_cost, prd_line, prd_start_dt, prd_end_dt
        )
        SELECT
            prd_id,
            REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_'),
            SUBSTRING(prd_key, 7, LEN(prd_key)),
            prd_nm,
            ISNULL(prd_cost, 0),
            CASE UPPER(TRIM(prd_line))
                WHEN 'M' THEN 'Mountain'
                WHEN 'R' THEN 'Road'
                WHEN 'S' THEN 'Other Sales'
                WHEN 'T' THEN 'Touring'
                ELSE 'n/a'
            END,
            CAST(prd_start_dt AS DATE),
            CAST(DATEADD(DAY, -1, LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt)) AS DATE)
        FROM bronze.crm_prd_info;
        PRINT '   Segundos: ' + CAST(DATEDIFF(SECOND, @start_time, GETDATE()) AS NVARCHAR(20));

        -- ---------------------------------------------------
        -- silver.crm_sales_details
        -- ---------------------------------------------------
        SET @start_time = GETDATE();
        PRINT '>> Cargando: silver.crm_sales_details';
        TRUNCATE TABLE silver.crm_sales_details;
        INSERT INTO silver.crm_sales_details (
            sls_ord_num, sls_prd_key, sls_cust_id,
            sls_order_dt, sls_ship_dt, sls_due_dt,
            sls_sales, sls_quantity, sls_price
        )
        SELECT
            sls_ord_num,
            sls_prd_key,
            sls_cust_id,
            CASE WHEN sls_order_dt = 0 OR LEN(CAST(sls_order_dt AS VARCHAR(20))) <> 8
                 THEN NULL
                 ELSE CAST(CAST(sls_order_dt AS VARCHAR(8)) AS DATE) END,
            CASE WHEN sls_ship_dt = 0 OR LEN(CAST(sls_ship_dt AS VARCHAR(20))) <> 8
                 THEN NULL
                 ELSE CAST(CAST(sls_ship_dt AS VARCHAR(8)) AS DATE) END,
            CASE WHEN sls_due_dt = 0 OR LEN(CAST(sls_due_dt AS VARCHAR(20))) <> 8
                 THEN NULL
                 ELSE CAST(CAST(sls_due_dt AS VARCHAR(8)) AS DATE) END,
            CASE WHEN sls_sales IS NULL OR sls_sales <= 0
                      OR sls_sales <> sls_quantity * ABS(sls_price)
                 THEN sls_quantity * ABS(sls_price)
                 ELSE sls_sales END,
            sls_quantity,
            CASE WHEN sls_price IS NULL OR sls_price <= 0
                 THEN sls_sales / NULLIF(sls_quantity, 0)
                 ELSE sls_price END
        FROM bronze.crm_sales_details;
        PRINT '   Segundos: ' + CAST(DATEDIFF(SECOND, @start_time, GETDATE()) AS NVARCHAR(20));

        -- ---------------------------------------------------
        -- silver.erp_cust_az12
        -- ---------------------------------------------------
        SET @start_time = GETDATE();
        PRINT '>> Cargando: silver.erp_cust_az12';
        TRUNCATE TABLE silver.erp_cust_az12;
        INSERT INTO silver.erp_cust_az12 (cid, bdate, gen)
        SELECT
            CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid)) ELSE cid END,
            CASE WHEN bdate > GETDATE() THEN NULL ELSE bdate END,
            CASE
                WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
                WHEN UPPER(TRIM(gen)) IN ('M', 'MALE')   THEN 'Male'
                ELSE 'n/a'
            END
        FROM bronze.erp_cust_az12;
        PRINT '   Segundos: ' + CAST(DATEDIFF(SECOND, @start_time, GETDATE()) AS NVARCHAR(20));

        -- ---------------------------------------------------
        -- silver.erp_loc_a101
        -- ---------------------------------------------------
        SET @start_time = GETDATE();
        PRINT '>> Cargando: silver.erp_loc_a101';
        TRUNCATE TABLE silver.erp_loc_a101;
        INSERT INTO silver.erp_loc_a101 (cid, cntry)
        SELECT
            REPLACE(cid, '-', ''),
            CASE
                WHEN TRIM(cntry) = 'DE'              THEN 'Germany'
                WHEN TRIM(cntry) IN ('US', 'USA')    THEN 'United States'
                WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
                ELSE TRIM(cntry)
            END
        FROM bronze.erp_loc_a101;
        PRINT '   Segundos: ' + CAST(DATEDIFF(SECOND, @start_time, GETDATE()) AS NVARCHAR(20));

        -- ---------------------------------------------------
        -- silver.erp_px_cat_g1v2
        -- ---------------------------------------------------
        SET @start_time = GETDATE();
        PRINT '>> Cargando: silver.erp_px_cat_g1v2';
        TRUNCATE TABLE silver.erp_px_cat_g1v2;
        INSERT INTO silver.erp_px_cat_g1v2 (id, cat, subcat, maintenance)
        SELECT
            TRIM(id),
            TRIM(cat),
            TRIM(subcat),
            TRIM(maintenance)
        FROM bronze.erp_px_cat_g1v2;
        PRINT '   Segundos: ' + CAST(DATEDIFF(SECOND, @start_time, GETDATE()) AS NVARCHAR(20));

        PRINT '================================================';
        PRINT 'Carga Silver completada. Duración total (segundos): '
            + CAST(DATEDIFF(SECOND, @batch_start, GETDATE()) AS NVARCHAR(20));
        PRINT '================================================';
    END TRY
    BEGIN CATCH
        PRINT '================================================';
        PRINT 'ERROR durante la carga de la capa Silver';
        PRINT 'Mensaje: ' + ERROR_MESSAGE();
        PRINT 'Número : ' + CAST(ERROR_NUMBER() AS NVARCHAR(20));
        PRINT '================================================';
        THROW;
    END CATCH;
END;
GO
