# Problemas de calidad encontrados y cómo se resolvieron (Bronze → Silver)

| Tabla | Problema en los datos de origen | Solución en Silver |
|---|---|---|
| `crm_cust_info` | 4 registros sin `cst_id` y 9 clientes repetidos | Se descartan los nulos y se conserva el registro más reciente por cliente |
| `crm_cust_info` | Espacios sobrantes en nombres y apellidos | `TRIM` |
| `crm_cust_info` | Estado civil y género abreviados (`S`, `M`, `F`) o vacíos | Se expanden (`Single`, `Married`, `Female`, `Male`) y los vacíos pasan a `n/a` |
| `crm_prd_info` | `prd_key` mezcla categoría y producto en un solo campo | Se separa en `cat_id` (con `_`) y `prd_key` |
| `crm_prd_info` | Costo vacío | Se reemplaza por 0 |
| `crm_prd_info` | Línea de producto abreviada y con espacios | Se expande (`Mountain`, `Road`, `Other Sales`, `Touring`) |
| `crm_prd_info` | 200 filas con fecha fin anterior a la fecha inicio | `prd_end_dt` se recalcula con la fecha de inicio de la siguiente versión menos un día |
| `crm_sales_details` | Fechas guardadas como número (`20101229`) y 19 pedidos con valores inválidos (`0`, `32154`, `5489`) | Se convierten a `DATE`; los inválidos quedan en `NULL` |
| `crm_sales_details` | Ventas o precios nulos, negativos o que no cuadran con cantidad × precio (30 filas) | Se recalculan a partir de cantidad y precio |
| `erp_cust_az12` | `CID` con prefijo `NAS` que no existe en el CRM | Se quita el prefijo |
| `erp_cust_az12` | 16 fechas de nacimiento en el futuro | Se reemplazan por `NULL` |
| `erp_cust_az12` | Género con valores mezclados (`F`, `Female`, vacíos, espacios) | Se estandariza a `Female`, `Male` o `n/a` |
| `erp_loc_a101` | `CID` con guion (`AW-00011000`) | Se quita el guion |
| `erp_loc_a101` | Países en formas distintas (`DE`, `US`, `USA`) y vacíos | `Germany`, `United States`, y `n/a` para vacíos |
| `erp_px_cat_g1v2` | Posibles espacios sobrantes | `TRIM` |

Los conteos y las reglas se verifican con `04_tests/quality_checks_silver.sql` y `04_tests/quality_checks_gold.sql`.
