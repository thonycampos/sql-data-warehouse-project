# Arquitectura y flujo de datos

Almacén de datos en SQL Server con **arquitectura Medallion**. Una sola base de datos (`data_warehouse`) con tres esquemas, uno por capa.

## Capas

| Capa | Esquema | Objetos | Responsabilidad |
|---|---|---|---|
| Bronze | `bronze` | 6 tablas | Datos originales, tal como vienen de los CSV (sin transformar) |
| Silver | `silver` | 6 tablas | Datos limpios, estandarizados y con tipos correctos |
| Gold | `gold` | 2 dimensiones y 1 tabla de hechos (vistas) | Modelo en estrella listo para análisis |

## Flujo de datos

```mermaid
flowchart LR
    subgraph Origenes[Sistemas de origen - CSV]
        direction TB
        C1[CRM: cust_info]
        C2[CRM: prd_info]
        C3[CRM: sales_details]
        E1[ERP: CUST_AZ12]
        E2[ERP: LOC_A101]
        E3[ERP: PX_CAT_G1V2]
    end

    subgraph Bronze[Bronze - datos crudos]
        direction TB
        B1[crm_cust_info]
        B2[crm_prd_info]
        B3[crm_sales_details]
        B4[erp_cust_az12]
        B5[erp_loc_a101]
        B6[erp_px_cat_g1v2]
    end

    subgraph Silver[Silver - datos limpios]
        direction TB
        S1[crm_cust_info]
        S2[crm_prd_info]
        S3[crm_sales_details]
        S4[erp_cust_az12]
        S5[erp_loc_a101]
        S6[erp_px_cat_g1v2]
    end

    subgraph Gold[Gold - modelo estrella]
        direction TB
        G1[dim_customers]
        G2[dim_products]
        G3[fact_sales]
    end

    C1 --> B1 --> S1
    C2 --> B2 --> S2
    C3 --> B3 --> S3
    E1 --> B4 --> S4
    E2 --> B5 --> S5
    E3 --> B6 --> S6

    S1 --> G1
    S4 --> G1
    S5 --> G1
    S2 --> G2
    S6 --> G2
    S3 --> G3
    G1 --> G3
    G2 --> G3
```

## Procesos de carga

| Paso | Procedimiento / script | Qué hace |
|---|---|---|
| Bronze | `bronze.load_bronze` (`BULK INSERT`) | Vacía y carga los 6 CSV sin modificar |
| Silver | `silver.load_silver` | Limpia, estandariza e inserta (Bronze → Silver) |
| Gold | `gold/ddl_gold.sql` (vistas) | Integra CRM y ERP en dimensiones y hechos |

Cada capa se alimenta únicamente de la anterior. Gold siempre refleja lo que hay en Silver, porque son vistas.

## Cómo se relacionan las fuentes

| Entidad | CRM | ERP | Llave de unión |
|---|---|---|---|
| Cliente | `cust_info` (`cst_key`) | `CUST_AZ12` (`CID`, con prefijo `NAS`), `LOC_A101` (`CID`, con guion) | `cst_key = cid`, tras limpiar el prefijo y los guiones en Silver |
| Producto | `prd_info` (`prd_key`) | `PX_CAT_G1V2` (`ID`) | `cat_id` extraído de `prd_key`, con `-` reemplazado por `_` |
| Ventas | `sales_details` | — | `sls_cust_id = cst_id`, `sls_prd_key = prd_key` |

## Alcance

Según los requisitos, solo se trabaja con el conjunto de datos más reciente y no se mantiene historial. Por eso `dim_products` solo contiene la versión vigente de cada producto (`prd_end_dt IS NULL`) y las cargas vacían las tablas antes de insertar.
