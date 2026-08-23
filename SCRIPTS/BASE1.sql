CREATE DATABASE IF NOT EXISTS venta_online
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE venta_online;

DROP TABLE IF EXISTS ventas;
DROP TABLE IF EXISTS ventas_staging;

CREATE TABLE ventas_staging (
    Id_cliente VARCHAR(20) NOT NULL,
    Edad VARCHAR(10) NOT NULL,
    Genero VARCHAR(10) NOT NULL,
    Venta_total VARCHAR(30) NOT NULL,
    N_Compras VARCHAR(10) NOT NULL,
    FechaCompra VARCHAR(20) NOT NULL,
    MontoCompra VARCHAR(30) NOT NULL,
    MetodoPago VARCHAR(10) NOT NULL,
    Tiempo VARCHAR(20) NOT NULL,
    Navegador VARCHAR(10) NOT NULL,
    Boletin VARCHAR(10) NOT NULL,
    Vale VARCHAR(10) NOT NULL
);

-- Cambiar ruta por la real del CSV.
SET GLOBAL local_infile = 1;

LOAD DATA LOCAL INFILE 'C:/temp/Venta_online_c.csv'
INTO TABLE ventas_staging
FIELDS TERMINATED BY ';'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;

CREATE TABLE ventas (
    Id_cliente INT NOT NULL,
    Edad TINYINT UNSIGNED NOT NULL,
    Genero TINYINT UNSIGNED NOT NULL,
    Venta_total DECIMAL(12, 3) NOT NULL,
    N_Compras SMALLINT UNSIGNED NOT NULL,
    FechaCompra DATE NOT NULL,
    MontoCompra DECIMAL(12, 3) NOT NULL,
    MetodoPago TINYINT UNSIGNED NOT NULL,
    Tiempo SMALLINT UNSIGNED NOT NULL,
    Navegador TINYINT UNSIGNED NOT NULL,
    Boletin TINYINT UNSIGNED NOT NULL,
    Vale TINYINT UNSIGNED NOT NULL,
    PRIMARY KEY (Id_cliente),
    CONSTRAINT chk_ventas_genero CHECK (Genero IN (0, 1)),
    CONSTRAINT chk_ventas_metodo_pago CHECK (MetodoPago IN (0, 1, 2)),
    CONSTRAINT chk_ventas_navegador CHECK (Navegador IN (0, 1, 2, 3, 4)),
    CONSTRAINT chk_ventas_boletin CHECK (Boletin IN (0, 1)),
    CONSTRAINT chk_ventas_vale CHECK (Vale IN (0, 1))
);

INSERT INTO ventas (
    Id_cliente, Edad, Genero, Venta_total, N_Compras, FechaCompra,
    MontoCompra, MetodoPago, Tiempo, Navegador, Boletin, Vale
)
SELECT
    CAST(Id_cliente AS UNSIGNED),
    CAST(Edad AS UNSIGNED),
    CAST(Genero AS UNSIGNED),
    CAST(Venta_total AS DECIMAL(12, 3)),
    CAST(N_Compras AS UNSIGNED),
    STR_TO_DATE(FechaCompra, '%d.%m.%y'),
    CAST(MontoCompra AS DECIMAL(12, 3)),
    CAST(MetodoPago AS UNSIGNED),
    CAST(Tiempo AS UNSIGNED),
    CAST(Navegador AS UNSIGNED),
    CAST(Boletin AS UNSIGNED),
    CAST(Vale AS UNSIGNED)
FROM ventas_staging;

SELECT COUNT(*) AS registros_cargados FROM ventas;
SELECT MIN(FechaCompra) AS fecha_inicial, MAX(FechaCompra) AS fecha_final
FROM ventas;