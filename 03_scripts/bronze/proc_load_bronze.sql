/*
=============================================================
Procedimiento almacenado: bronze.load_bronze
=============================================================
Carga los 6 archivos CSV en las tablas del esquema 'bronze'.
Por cada tabla: la vacía (TRUNCATE) y la llena con BULK INSERT.

Parámetro:
    @datasets_path : carpeta que contiene source_crm y source_erp.
                     Ejemplo: C:\datasets

Uso:
    EXEC bronze.load_bronze @datasets_path = 'C:\datasets';

Nota:
    BULK INSERT lo ejecuta SQL Server, así que el servicio de SQL Server
    debe poder leer esa carpeta. Use una carpeta simple como C:\datasets
    (fuera de Documentos, Escritorio, etc.).

Ejecutar DESPUÉS de ddl_bronze.sql.
=============================================================
*/

USE data_warehouse;
GO

CREATE OR ALTER PROCEDURE bronze.load_bronze
    @datasets_path NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @batch_start DATETIME = GETDATE();
    DECLARE @start_time  DATETIME;
    DECLARE @sql         NVARCHAR(MAX);
    DECLARE @table       NVARCHAR(128);
    DECLARE @file        NVARCHAR(260);
    DECLARE @rows        INT;
    DECLARE @i           INT = 1;

    -- Asegurar que la ruta termine en "\"
    IF RIGHT(@datasets_path, 1) <> '\'
        SET @datasets_path = @datasets_path + '\';

    -- Lista de (tabla destino, archivo origen)
    DECLARE @files TABLE (
        id         INT IDENTITY(1,1),
        table_name NVARCHAR(128),
        file_path  NVARCHAR(260)
    );

    INSERT INTO @files (table_name, file_path) VALUES
        ('bronze.crm_cust_info',     'source_crm\cust_info.csv'),
        ('bronze.crm_prd_info',      'source_crm\prd_info.csv'),
        ('bronze.crm_sales_details', 'source_crm\sales_details.csv'),
        ('bronze.erp_cust_az12',     'source_erp\CUST_AZ12.csv'),
        ('bronze.erp_loc_a101',      'source_erp\LOC_A101.csv'),
        ('bronze.erp_px_cat_g1v2',   'source_erp\PX_CAT_G1V2.csv');

    DECLARE @total INT = (SELECT COUNT(*) FROM @files);

    BEGIN TRY
        PRINT '================================================';
        PRINT 'Cargando capa Bronze';
        PRINT '================================================';

        WHILE @i <= @total
        BEGIN
            SELECT @table = table_name, @file = file_path
            FROM @files WHERE id = @i;

            SET @start_time = GETDATE();
            PRINT '>> Cargando: ' + @table;

            -- BULK INSERT no acepta variables en el nombre del archivo,
            -- por eso se arma el comando como texto y se ejecuta con sp_executesql.
            -- FIRSTROW = 2 salta los encabezados; CODEPAGE 65001 = UTF-8 (tildes y ñ);
            -- KEEPNULLS deja los campos vacíos como NULL.
            SET @sql = N'TRUNCATE TABLE ' + @table + N';
                BULK INSERT ' + @table + N'
                FROM ''' + @datasets_path + @file + N'''
                WITH (
                    FIRSTROW        = 2,
                    FIELDTERMINATOR = '','',
                    CODEPAGE        = ''65001'',
                    KEEPNULLS,
                    TABLOCK
                );';
            EXEC sp_executesql @sql;

            SET @sql = N'SELECT @r = COUNT(*) FROM ' + @table + N';';
            EXEC sp_executesql @sql, N'@r INT OUTPUT', @r = @rows OUTPUT;

            PRINT '   Filas cargadas: ' + CAST(@rows AS NVARCHAR(20))
                + ' | Segundos: ' + CAST(DATEDIFF(SECOND, @start_time, GETDATE()) AS NVARCHAR(20));

            SET @i = @i + 1;
        END;

        PRINT '================================================';
        PRINT 'Carga Bronze completada. Duración total (segundos): '
            + CAST(DATEDIFF(SECOND, @batch_start, GETDATE()) AS NVARCHAR(20));
        PRINT '================================================';
    END TRY
    BEGIN CATCH
        PRINT '================================================';
        PRINT 'ERROR durante la carga de ' + ISNULL(@table, '(sin tabla)');
        PRINT 'Mensaje: ' + ERROR_MESSAGE();
        PRINT 'Número : ' + CAST(ERROR_NUMBER() AS NVARCHAR(20));
        PRINT '================================================';
        THROW;
    END CATCH;
END;
GO
