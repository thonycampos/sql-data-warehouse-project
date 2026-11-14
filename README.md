# SQL Data Warehouse Project

Almacén de datos en **SQL Server** con **arquitectura Medallion** (ISW-623, UTN).
Una sola base de datos `data_warehouse` con tres esquemas: `bronze`, `silver` y `gold`.

Consolida las ventas de dos sistemas de origen (CRM y ERP, en archivos CSV) en un modelo en estrella listo para análisis.

## Estructura

```
sql-data-warehouse-project/
├── 00_setup/       Guía de configuración (SSMS y GitHub)
├── 01_datasets/    Archivos CSV de origen (source_crm, source_erp)
├── 02_docs/        Convenciones, arquitectura, modelo de datos y calidad de datos
├── 03_scripts/
│   ├── init_database.sql   Crea la base de datos y los esquemas (ejecutar primero)
│   ├── bronze/             Tablas y carga de datos crudos
│   ├── silver/             Tablas y limpieza de datos
│   └── gold/               Vistas del modelo en estrella (dimensiones y hechos)
└── 04_tests/       Verificación de calidad de datos (Bronze, Silver y Gold)
```

## Orden de ejecución

| # | Script | Qué hace |
|---|---|---|
| 1 | `03_scripts/init_database.sql` | Crea `data_warehouse` y los esquemas |
| 2 | `03_scripts/bronze/ddl_bronze.sql` | Crea las tablas Bronze |
| 3 | `03_scripts/bronze/proc_load_bronze.sql` | Crea el procedimiento `bronze.load_bronze` |
| 4 | `EXEC bronze.load_bronze @datasets_path = 'C:\datasets';` | Carga los CSV |
| 5 | `03_scripts/silver/ddl_silver.sql` | Crea las tablas Silver |
| 6 | `03_scripts/silver/proc_load_silver.sql` | Crea el procedimiento `silver.load_silver` |
| 7 | `EXEC silver.load_silver;` | Limpia y carga Silver |
| 8 | `03_scripts/gold/ddl_gold.sql` | Crea las vistas Gold |
| 9 | `04_tests/*.sql` | Verifica Bronze, Silver y Gold |

Paso a paso detallado: [00_setup/guia_configuracion.md](00_setup/guia_configuracion.md)

## Modelo Gold

```
dim_customers ──┐
                ├──< fact_sales
dim_products  ──┘
```

Más detalle en [02_docs/modelo_de_datos_gold.md](02_docs/modelo_de_datos_gold.md).

## Documentación

- [Arquitectura y flujo de datos](02_docs/arquitectura_y_flujo_de_datos.md)
- [Modelo de datos Gold (diccionario de columnas)](02_docs/modelo_de_datos_gold.md)
- [Problemas de calidad y limpieza](02_docs/problemas_de_calidad_y_limpieza.md)
- [Convenciones de nomenclatura](02_docs/convenciones_nomenclatura_es.md)
