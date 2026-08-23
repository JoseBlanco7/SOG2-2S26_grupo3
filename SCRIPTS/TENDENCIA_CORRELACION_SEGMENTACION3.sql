USE venta_online;

-- Meses con mayor y menor venta total.
SELECT
    MONTH(FechaCompra) AS mes,
    MONTHNAME(FechaCompra) AS nombre_mes,
    ROUND(SUM(Venta_total), 2) AS ventas_totales,
    COUNT(*) AS registros
FROM ventas
GROUP BY MONTH(FechaCompra), MONTHNAME(FechaCompra)
ORDER BY ventas_totales DESC;

-- Navegadores o canales ordenados por preferencia.
SELECT
    Navegador,
    CASE Navegador
        WHEN 0 THEN 'Tienda fisica'
        ELSE CONCAT('Navegador ', Navegador)
    END AS canal,
    COUNT(*) AS registros,
    ROUND(100 * COUNT(*) / (SELECT COUNT(*) FROM ventas), 2) AS porcentaje_registros
FROM ventas
GROUP BY Navegador
ORDER BY registros DESC;

-- Comparacion de efectivo con tarjetas.
SELECT
    MetodoPago,
    CASE MetodoPago
        WHEN 0 THEN 'Efectivo'
        WHEN 1 THEN 'Tarjeta de credito'
        WHEN 2 THEN 'Tarjeta de debito'
    END AS metodo,
    COUNT(*) AS registros,
    ROUND(SUM(Venta_total), 2) AS ventas_totales,
    ROUND(100 * SUM(Venta_total) / (SELECT SUM(Venta_total) FROM ventas), 2) AS porcentaje_ventas
FROM ventas
GROUP BY MetodoPago
ORDER BY ventas_totales DESC;

-- Meses con mayor uso de boletines y vales.
SELECT
    MONTH(FechaCompra) AS mes,
    MONTHNAME(FechaCompra) AS nombre_mes,
    SUM(Boletin) AS boletines_usados,
    SUM(Vale) AS vales_usados,
    COUNT(*) AS registros
FROM ventas
GROUP BY MONTH(FechaCompra), MONTHNAME(FechaCompra)
ORDER BY mes;

-- Segmentacion por grupos de edad.
SELECT
    CASE
        WHEN Edad < 25 THEN '18-24'
        WHEN Edad < 35 THEN '25-34'
        WHEN Edad < 45 THEN '35-44'
        WHEN Edad < 55 THEN '45-54'
        ELSE '55 o mas'
    END AS grupo_edad,
    COUNT(*) AS registros,
    ROUND(AVG(Venta_total), 2) AS venta_promedio,
    ROUND(SUM(Venta_total), 2) AS ventas_totales,
    ROUND(AVG(N_Compras), 2) AS compras_promedio
FROM ventas
GROUP BY grupo_edad
ORDER BY grupo_edad;

-- Comparacion del comportamiento de compra por genero.
SELECT
    Genero,
    CASE Genero WHEN 1 THEN 'Femenino' ELSE 'Masculino' END AS genero_descripcion,
    COUNT(*) AS registros,
    ROUND(AVG(Venta_total), 2) AS venta_promedio,
    ROUND(SUM(Venta_total), 2) AS ventas_totales,
    ROUND(AVG(N_Compras), 2) AS compras_promedio
FROM ventas
GROUP BY Genero
ORDER BY Genero;

-- Comparacion de clientes con boletin y vale.
SELECT
    Boletin,
    Vale,
    CASE Boletin WHEN 1 THEN 'Si' ELSE 'No' END AS usa_boletin,
    CASE Vale WHEN 1 THEN 'Si' ELSE 'No' END AS usa_vale,
    COUNT(*) AS registros,
    ROUND(AVG(Venta_total), 2) AS venta_promedio,
    ROUND(SUM(Venta_total), 2) AS ventas_totales
FROM ventas
GROUP BY Boletin, Vale
ORDER BY Boletin DESC, Vale DESC;

-- Correlacion de Pearson entre edad y venta total.
SELECT ROUND(
    (
        COUNT(*) * SUM(Edad * Venta_total) - SUM(Edad) * SUM(Venta_total)
    ) /
    NULLIF(SQRT(
        (COUNT(*) * SUM(Edad * Edad) - SUM(Edad) * SUM(Edad)) *
        (COUNT(*) * SUM(Venta_total * Venta_total) - SUM(Venta_total) * SUM(Venta_total))
    ), 0), 4
) AS correlacion_edad_venta_total
FROM ventas;

-- Tabla de relacion entre genero y metodo de pago.
SELECT
    CASE Genero WHEN 1 THEN 'Femenino' ELSE 'Masculino' END AS genero,
    CASE MetodoPago
        WHEN 0 THEN 'Efectivo'
        WHEN 1 THEN 'Tarjeta de credito'
        WHEN 2 THEN 'Tarjeta de debito'
    END AS metodo,
    COUNT(*) AS registros,
    ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY Genero), 2) AS porcentaje_dentro_genero
FROM ventas
GROUP BY Genero, MetodoPago
ORDER BY Genero, MetodoPago;

-- Coeficiente phi entre uso de boletin y uso de vale.
WITH tabla AS (
    SELECT
        SUM(CASE WHEN Boletin = 1 AND Vale = 1 THEN 1 ELSE 0 END) AS a,
        SUM(CASE WHEN Boletin = 1 AND Vale = 0 THEN 1 ELSE 0 END) AS b,
        SUM(CASE WHEN Boletin = 0 AND Vale = 1 THEN 1 ELSE 0 END) AS c,
        SUM(CASE WHEN Boletin = 0 AND Vale = 0 THEN 1 ELSE 0 END) AS d
    FROM ventas
)
SELECT
    a, b, c, d,
    ROUND((a * d - b * c) / NULLIF(SQRT((a + b) * (c + d) * (a + c) * (b + d)), 0), 4) AS coeficiente_phi
FROM tabla;