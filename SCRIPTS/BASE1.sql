
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


CREATE TABLE ventas (
    Id_cliente INT NOT NULL,
    Edad SMALLINT NOT NULL,
    Genero SMALLINT NOT NULL,
    Venta_total DECIMAL(12, 3) NOT NULL,
    N_Compras SMALLINT NOT NULL,
    FechaCompra DATE NOT NULL,
    MontoCompra DECIMAL(12, 3) NOT NULL,
    MetodoPago SMALLINT NOT NULL,
    Tiempo SMALLINT NOT NULL,
    Navegador SMALLINT NOT NULL,
    Boletin SMALLINT NOT NULL,
    Vale SMALLINT NOT NULL,
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
    CAST(Id_cliente AS INTEGER),
    CAST(Edad AS INTEGER),
    CAST(Genero AS INTEGER),
    CAST(Venta_total AS DECIMAL(12, 3)),
    CAST(N_Compras AS INTEGER),
    TO_DATE(FechaCompra, 'DD.MM.YY'),
    CAST(MontoCompra AS DECIMAL(12, 3)),
    CAST(MetodoPago AS INTEGER),
    CAST(Tiempo AS INTEGER),
    CAST(Navegador AS INTEGER),
    CAST(Boletin AS INTEGER),
    CAST(Vale AS INTEGER)
FROM ventas_staging;

SELECT COUNT(*) AS registros_cargados FROM ventas;
SELECT MIN(FechaCompra) AS fecha_inicial, MAX(FechaCompra) AS fecha_final
FROM ventas;
