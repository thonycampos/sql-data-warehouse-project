# Guía de configuración (SSMS 22 + GitHub)

## Parte 1: SQL Server en SSMS

1. Abra **SSMS 22** y conéctese (Server name: `localhost` o `.\SQLEXPRESS`; Windows Authentication; si da error de certificado, marque *Trust server certificate*).
2. Copie `source_crm` y `source_erp` (de la carpeta `01_datasets`) a una carpeta `C:\datasets`, de modo que quede `C:\datasets\source_crm\cust_info.csv`, etc. SQL Server lee los archivos con su propio servicio y no siempre tiene permiso en Documentos o el Escritorio.
3. **File > Open > File** y abra `03_scripts/init_database.sql`. Presione **Ctrl+A** (seleccionar todo) y **F5**. Crea la base `data_warehouse` y los esquemas `bronze`, `silver` y `gold`. Si ya existía, la borra y la recrea.
4. En *Object Explorer*: clic derecho en **Databases > Refresh**. Expanda `data_warehouse > Security > Schemas`: deben verse los 3 esquemas.
5. Abra `03_scripts/bronze/ddl_bronze.sql`, **Ctrl+A** y **F5**. Crea las 6 tablas (Tables > Refresh para verlas).
6. Abra `03_scripts/bronze/proc_load_bronze.sql`, **Ctrl+A** y **F5**. Crea el procedimiento `bronze.load_bronze`.
7. **New Query** y ejecute:
   ```sql
   USE data_warehouse;
   EXEC bronze.load_bronze @datasets_path = 'C:\datasets';
   ```
   La pestaña *Messages* muestra las filas cargadas por tabla.
8. Abra `04_tests/quality_checks_bronze.sql` y ejecútelo. Esperado: 18494, 397, 60398, 18484, 18484 y 37 filas.
9. **Capa Silver.** Abra y ejecute (Ctrl+A y F5), en este orden:
   - `03_scripts/silver/ddl_silver.sql` (crea las tablas)
   - `03_scripts/silver/proc_load_silver.sql` (crea el procedimiento)

   Luego, en una **New Query**:
   ```sql
   USE data_warehouse;
   EXEC silver.load_silver;
   ```
10. Ejecute `04_tests/quality_checks_silver.sql`. Casi todas las consultas deben dar **0 filas** (las que muestran valores distintos o un conteo están marcadas en el script).
11. **Capa Gold.** Ejecute `03_scripts/gold/ddl_gold.sql`. Crea las vistas `gold.dim_customers`, `gold.dim_products` y `gold.fact_sales` (aparecen en *Views*).
12. Ejecute `04_tests/quality_checks_gold.sql`. Esperado: 18484 clientes, 295 productos y 60398 ventas, y 0 filas en las pruebas de integridad.

### Errores comunes
- **Msg 2760 (schema bronze does not exist)**: no se ejecutó `init_database.sql` completo. Vuelva al paso 3.
- **Invalid object name 'silver.xxx'**: falta ejecutar `ddl_silver.sql` (paso 9) o `EXEC silver.load_silver`.
- **Msg 911 (Database does not exist)**: el nombre es `data_warehouse` (con guion bajo, minúsculas).
- **Operating system error 5 / Cannot bulk load**: SQL Server no tiene permiso para leer la carpeta. Use `C:\datasets`.
- **Operating system error 3**: la ruta está mal escrita. Revise que exista `C:\datasets\source_crm`.

## Parte 2: Subir a GitHub (desde el navegador, sin comandos)

1. Cree cuenta en https://github.com e inicie sesión.
2. Clic en **New repository**. Nombre: `sql-data-warehouse-project`. Déjelo vacío (sin README, .gitignore ni licencia) y clic en **Create repository**.
3. En la página que aparece, clic en el enlace **uploading an existing file**.
4. En su computadora abra la carpeta del proyecto, entre a ella y presione **Ctrl+A** para seleccionar todo su contenido (`00_setup`, `01_datasets`, `README.md`, etc.). Arrastre la selección a la página del navegador. Arrastre el **contenido**, no la carpeta misma.
5. Espere a que termine de cargar. Escriba un mensaje (por ejemplo `Proyecto completo: bronze, silver y gold`) y clic en **Commit changes**.
6. Abra el `README.md` en GitHub: los diagramas de `02_docs` se ven directamente en el navegador.

Para cambios futuros: en el repositorio, **Add file > Upload files**, arrastre los archivos modificados y haga commit.
