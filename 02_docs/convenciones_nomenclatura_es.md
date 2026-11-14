# **Convenciones de nomenclatura**

Este documento describe las convenciones de nomenclatura utilizadas para
los esquemas, las tablas, las vistas, las columnas y otros objetos del
almacén de datos.

## **Tabla de contenidos**

1.  [Principios generales](#principios-generales)
2.  [Convenciones para nombrar
    tablas](#convenciones-para-nombrar-tablas)
    -   [Reglas para Bronze](#reglas-para-bronze)
    -   [Reglas para Silver](#reglas-para-silver)
    -   [Reglas para Gold](#reglas-para-gold)
3.  [Convenciones para nombrar
    columnas](#convenciones-para-nombrar-columnas)
    -   [Claves subrogadas](#claves-subrogadas)
    -   [Columnas técnicas](#columnas-técnicas)
4.  [Convenciones para nombrar procedimientos
    almacenados](#convenciones-para-nombrar-procedimientos-almacenados)

------------------------------------------------------------------------

## **Principios generales**

-   **Convenciones de nomenclatura**: utilizar el formato `snake_case`,
    con letras minúsculas y guiones bajos (`_`) para separar las
    palabras.
-   **Idioma**: utilizar el inglés para todos los nombres.
-   **Evitar palabras reservadas**: no utilizar palabras reservadas de
    SQL como nombres de objetos.

## **Convenciones para nombrar tablas**

### **Reglas para Bronze**

-   Todos los nombres deben comenzar con el nombre del sistema de origen
    y los nombres de las tablas deben coincidir con los nombres
    originales, sin modificarlos.
-   **`<sourcesystem>_<entity>`**
    -   `<sourcesystem>`: nombre del sistema de origen (por ejemplo,
        `crm`, `erp`).
    -   `<entity>`: nombre exacto de la tabla en el sistema de origen.
    -   Ejemplo: `crm_customer_info` → información de clientes
        proveniente del sistema CRM.

### **Reglas para Silver**

-   Todos los nombres deben comenzar con el nombre del sistema de origen
    y los nombres de las tablas deben coincidir con los nombres
    originales, sin modificarlos.
-   **`<sourcesystem>_<entity>`**
    -   `<sourcesystem>`: nombre del sistema de origen (por ejemplo,
        `crm`, `erp`).
    -   `<entity>`: nombre exacto de la tabla en el sistema de origen.
    -   Ejemplo: `crm_customer_info` → información de clientes
        proveniente del sistema CRM.

### **Reglas para Gold**

-   Todos los nombres deben utilizar nombres significativos y alineados
    con el negocio. Los nombres de las tablas deben comenzar con el
    prefijo de categoría.
-   **`<category>_<entity>`**
    -   `<category>`: describe la función de la tabla, por ejemplo,
        `dim` (dimensión) o `fact` (tabla de hechos).
    -   `<entity>`: nombre descriptivo de la tabla, alineado con el
        dominio del negocio (por ejemplo, `customers`, `products`,
        `sales`).
    -   Ejemplos:
        -   `dim_customers` → tabla de dimensión que contiene
            información de clientes.
        -   `fact_sales` → tabla de hechos que contiene transacciones de
            ventas.

#### **Glosario de patrones de categorías**

  ------------------------------------------------------------------------
  Patrón                  Significado             Ejemplo(s)
  ----------------------- ----------------------- ------------------------
  `dim_`                  Tabla de dimensión      `dim_customer`,
                                                  `dim_product`

  `fact_`                 Tabla de hechos         `fact_sales`

  `report_`               Tabla de reportes       `report_customers`,
                                                  `report_sales_monthly`
  ------------------------------------------------------------------------

## **Convenciones para nombrar columnas**

### **Claves subrogadas**

-   Todas las claves primarias de las tablas de dimensiones deben
    utilizar el sufijo `_key`.
-   **`<table_name>_key`**
    -   `<table_name>`: hace referencia al nombre de la tabla o entidad
        a la que pertenece la clave.
    -   `_key`: sufijo que indica que la columna es una clave subrogada
        (*surrogate key*).
    -   Ejemplo: `customer_key` → clave subrogada de la tabla
        `dim_customers`.

### **Columnas técnicas**

-   Todas las columnas técnicas deben comenzar con el prefijo `dwh_`,
    seguido de un nombre descriptivo que indique el propósito de la
    columna.
-   **`dwh_<column_name>`**
    -   `dwh`: prefijo reservado exclusivamente para metadatos generados
        por el sistema.
    -   `<column_name>`: nombre descriptivo que indica el propósito de
        la columna.
    -   Ejemplo: `dwh_load_date` → columna generada por el sistema para
        almacenar la fecha en que se cargó el registro.

## **Convenciones para nombrar procedimientos almacenados**

-   Todos los procedimientos almacenados utilizados para cargar datos
    deben seguir el siguiente patrón de nomenclatura:
-   **`load_<layer>`**
    -   `<layer>`: representa la capa en la que se cargarán los datos,
        como `bronze`, `silver` o `gold`.
    -   Ejemplos:
        -   `load_bronze` → procedimiento almacenado para cargar datos
            en la capa Bronze.
        -   `load_silver` → procedimiento almacenado para cargar datos
            en la capa Silver.
