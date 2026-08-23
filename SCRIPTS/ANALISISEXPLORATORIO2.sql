USE venta_online;

-- Variables numericas principales.
SELECT
    COUNT(*) AS registros,
    ROUND(AVG(Edad), 2) AS promedio_edad,
    ROUND(AVG(Venta_total), 2) AS promedio_venta_total,
    ROUND(AVG(N_Compras), 2) AS promedio_compras,
    ROUND(AVG(MontoCompra), 2) AS promedio_monto_compra,
    ROUND(AVG(Tiempo), 2) AS promedio_tiempo
FROM ventas;

-- Medianas de las variables numericas principales
WITH valores AS (
    SELECT 'Edad' AS variable, CAST(Edad AS DECIMAL(18, 3)) AS valor FROM ventas
    UNION ALL
    SELECT 'Venta_total', Venta_total FROM ventas
    UNION ALL
    SELECT 'N_Compras', N_Compras FROM ventas
    UNION ALL
    SELECT 'MontoCompra', MontoCompra FROM ventas
    UNION ALL
    SELECT 'Tiempo', Tiempo FROM ventas
), ordenados AS (
    SELECT
        variable,
        valor,
        ROW_NUMBER() OVER (PARTITION BY variable ORDER BY valor) AS posicion,
        COUNT(*) OVER (PARTITION BY variable) AS total
    FROM valores
)
SELECT
    variable,
    ROUND(AVG(valor), 2) AS mediana
FROM ordenados
WHERE posicion IN (FLOOR((total + 1) / 2), CEIL((total + 1) / 2))
GROUP BY variable
ORDER BY variable;

-- Modas de las variables numericas principales.
WITH frecuencias AS (
    SELECT 'Edad' AS variable, CAST(Edad AS DECIMAL(18, 3)) AS valor, COUNT(*) AS frecuencia
    FROM ventas GROUP BY Edad
    UNION ALL
    SELECT 'Venta_total', Venta_total, COUNT(*)
    FROM ventas GROUP BY Venta_total
    UNION ALL
    SELECT 'N_Compras', N_Compras, COUNT(*)
    FROM ventas GROUP BY N_Compras
    UNION ALL
    SELECT 'MontoCompra', MontoCompra, COUNT(*)
    FROM ventas GROUP BY MontoCompra
    UNION ALL
    SELECT 'Tiempo', Tiempo, COUNT(*)
    FROM ventas GROUP BY Tiempo
), ordenadas AS (
    SELECT
        variable,
        valor,
        frecuencia,
        DENSE_RANK() OVER (PARTITION BY variable ORDER BY frecuencia DESC) AS ranking
    FROM frecuencias
)
SELECT variable, valor AS moda, frecuencia
FROM ordenadas
WHERE ranking = 1
ORDER BY variable, valor;

-- Ventas totales por mes.
SELECT
    MONTH(FechaCompra) AS mes,
    MONTHNAME(FechaCompra) AS nombre_mes,
    COUNT(*) AS registros,
    ROUND(SUM(Venta_total), 2) AS ventas_totales,
    ROUND(AVG(Venta_total), 2) AS venta_promedio
FROM ventas
GROUP BY MONTH(FechaCompra), MONTHNAME(FechaCompra)
ORDER BY mes;

-- Distribucion por metodo de pago.
SELECT
    MetodoPago,
    CASE MetodoPago
        WHEN 0 THEN 'Efectivo'
        WHEN 1 THEN 'Tarjeta de credito'
        WHEN 2 THEN 'Tarjeta de debito'
    END AS metodo,
    COUNT(*) AS registros,
    ROUND(SUM(Venta_total), 2) AS ventas_totales
FROM ventas
GROUP BY MetodoPago
ORDER BY MetodoPago;

-- Distribucion por navegador o canal.
SELECT
    Navegador,
    CASE Navegador
        WHEN 0 THEN 'Tienda fisica'
        ELSE CONCAT('Navegador ', Navegador)
    END AS canal,
    COUNT(*) AS registros,
    ROUND(SUM(Venta_total), 2) AS ventas_totales
FROM ventas
GROUP BY Navegador
ORDER BY Navegador;

-- Uso de boletin y vale.
SELECT
    'Boletin' AS indicador,
    Boletin AS valor,
    CASE Boletin WHEN 1 THEN 'Si' ELSE 'No' END AS descripcion,
    COUNT(*) AS registros,
    ROUND(SUM(Venta_total), 2) AS ventas_totales
FROM ventas
GROUP BY Boletin
UNION ALL
SELECT
    'Vale',
    Vale,
    CASE Vale WHEN 1 THEN 'Si' ELSE 'No' END,
    COUNT(*),
    ROUND(SUM(Venta_total), 2)
FROM ventas
GROUP BY Vale
ORDER BY indicador, valor;