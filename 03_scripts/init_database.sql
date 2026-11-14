/*
=============================================================
Crear base de datos y esquemas
=============================================================
Propósito:
    Crea la base de datos 'data_warehouse' y dentro de ella los tres
    esquemas de la arquitectura Medallion: bronze, silver y gold.
    (Una sola base de datos, tres esquemas.)

ADVERTENCIA:
    Si la base de datos 'data_warehouse' ya existe, se ELIMINA y se
    vuelve a crear. Se pierden todos sus datos.

Ejecutar PRIMERO, completo (Ctrl+A y luego F5).
=============================================================
*/

USE master;
GO

-- Si la base de datos ya existe, se elimina para empezar desde cero
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'data_warehouse')
BEGIN
    ALTER DATABASE data_warehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE data_warehouse;
END;
GO

-- Crear la base de datos
CREATE DATABASE data_warehouse;
GO

USE data_warehouse;
GO

-- Crear los esquemas (cada CREATE SCHEMA debe ir en su propio lote, por eso el GO)
CREATE SCHEMA bronze;   -- Datos originales, tal como vienen de los CSV
GO

CREATE SCHEMA silver;   -- Datos limpios y transformados
GO

CREATE SCHEMA gold;     -- Datos listos para análisis (modelo dimensional)
GO
