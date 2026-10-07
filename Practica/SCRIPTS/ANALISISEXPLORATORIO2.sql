
-- sp_estadisticas_numericas: media de las variables numericas principales.
CREATE OR REPLACE FUNCTION sp_estadisticas_numericas()
RETURNS TABLE (
    registros bigint,
    promedio_edad numeric,
    promedio_venta_total numeric,
    promedio_compras numeric,
    promedio_monto_compra numeric,
    promedio_tiempo numeric
)
LANGUAGE sql STABLE AS $$
    SELECT
        COUNT(*) AS registros,
        ROUND(AVG(v.Edad), 2) AS promedio_edad,
        ROUND(AVG(v.Venta_total), 2) AS promedio_venta_total,
        ROUND(AVG(v.N_Compras), 2) AS promedio_compras,
        ROUND(AVG(v.MontoCompra), 2) AS promedio_monto_compra,
        ROUND(AVG(v.Tiempo), 2) AS promedio_tiempo
    FROM ventas v;
$$;

-- sp_medianas_numericas: mediana de las variables numericas principales.
CREATE OR REPLACE FUNCTION sp_medianas_numericas()
RETURNS TABLE (
    variable text,
    mediana numeric
)
LANGUAGE sql STABLE AS $$
    WITH valores AS (
        SELECT 'Edad' AS variable, CAST(v.Edad AS DECIMAL(18, 3)) AS valor FROM ventas v
        UNION ALL
        SELECT 'Venta_total', v.Venta_total FROM ventas v
        UNION ALL
        SELECT 'N_Compras', v.N_Compras FROM ventas v
        UNION ALL
        SELECT 'MontoCompra', v.MontoCompra FROM ventas v
        UNION ALL
        SELECT 'Tiempo', v.Tiempo FROM ventas v
    ), ordenados AS (
        SELECT
            val.variable,
            val.valor,
            ROW_NUMBER() OVER (PARTITION BY val.variable ORDER BY val.valor) AS posicion,
            COUNT(*) OVER (PARTITION BY val.variable) AS total
        FROM valores val
    )
    SELECT
        o.variable,
        ROUND(AVG(o.valor), 2) AS mediana
    FROM ordenados o
    WHERE o.posicion IN (FLOOR((o.total + 1) / 2.0), CEIL((o.total + 1) / 2.0))
    GROUP BY 1
    ORDER BY 1;
$$;

-- sp_modas_numericas: moda de las variables numericas principales.
CREATE OR REPLACE FUNCTION sp_modas_numericas()
RETURNS TABLE (
    variable text,
    moda numeric,
    frecuencia bigint
)
LANGUAGE sql STABLE AS $$
    WITH frecuencias AS (
        SELECT 'Edad' AS variable, CAST(v.Edad AS DECIMAL(18, 3)) AS valor, COUNT(*) AS frecuencia
        FROM ventas v GROUP BY v.Edad
        UNION ALL
        SELECT 'Venta_total', v.Venta_total, COUNT(*)
        FROM ventas v GROUP BY v.Venta_total
        UNION ALL
        SELECT 'N_Compras', v.N_Compras, COUNT(*)
        FROM ventas v GROUP BY v.N_Compras
        UNION ALL
        SELECT 'MontoCompra', v.MontoCompra, COUNT(*)
        FROM ventas v GROUP BY v.MontoCompra
        UNION ALL
        SELECT 'Tiempo', v.Tiempo, COUNT(*)
        FROM ventas v GROUP BY v.Tiempo
    ), ordenadas AS (
        SELECT
            f.variable,
            f.valor,
            f.frecuencia,
            DENSE_RANK() OVER (PARTITION BY f.variable ORDER BY f.frecuencia DESC) AS ranking
        FROM frecuencias f
    )
    SELECT o.variable, o.valor AS moda, o.frecuencia
    FROM ordenadas o
    WHERE o.ranking = 1
    ORDER BY 1, 2;
$$;

-- sp_ventas_por_mes: ventas totales por mes.
CREATE OR REPLACE FUNCTION sp_ventas_por_mes()
RETURNS TABLE (
    mes int,
    nombre_mes text,
    registros bigint,
    ventas_totales numeric,
    venta_promedio numeric
)
LANGUAGE sql STABLE AS $$
    SELECT
        EXTRACT(MONTH FROM v.FechaCompra)::int AS mes,
        TRIM(TO_CHAR(v.FechaCompra, 'Month')) AS nombre_mes,
        COUNT(*) AS registros,
        ROUND(SUM(v.Venta_total), 2) AS ventas_totales,
        ROUND(AVG(v.Venta_total), 2) AS venta_promedio
    FROM ventas v
    GROUP BY 1, 2
    ORDER BY 1;
$$;

-- sp_distribucion_metodo_pago: distribucion por metodo de pago.
CREATE OR REPLACE FUNCTION sp_distribucion_metodo_pago()
RETURNS TABLE (
    metodopago smallint,
    metodo text,
    registros bigint,
    ventas_totales numeric
)
LANGUAGE sql STABLE AS $$
    SELECT
        v.MetodoPago,
        CASE v.MetodoPago
            WHEN 0 THEN 'Efectivo'
            WHEN 1 THEN 'Tarjeta de credito'
            WHEN 2 THEN 'Tarjeta de debito'
        END AS metodo,
        COUNT(*) AS registros,
        ROUND(SUM(v.Venta_total), 2) AS ventas_totales
    FROM ventas v
    GROUP BY 1
    ORDER BY 1;
$$;

-- sp_distribucion_navegador: distribucion por navegador o canal.
CREATE OR REPLACE FUNCTION sp_distribucion_navegador()
RETURNS TABLE (
    navegador smallint,
    canal text,
    registros bigint,
    ventas_totales numeric
)
LANGUAGE sql STABLE AS $$
    SELECT
        v.Navegador,
        CASE v.Navegador
            WHEN 0 THEN 'Tienda fisica'
            ELSE CONCAT('Navegador ', v.Navegador)
        END AS canal,
        COUNT(*) AS registros,
        ROUND(SUM(v.Venta_total), 2) AS ventas_totales
    FROM ventas v
    GROUP BY 1
    ORDER BY 1;
$$;

-- sp_uso_boletin_vale: uso de boletin y vale.
CREATE OR REPLACE FUNCTION sp_uso_boletin_vale()
RETURNS TABLE (
    indicador text,
    valor smallint,
    descripcion text,
    registros bigint,
    ventas_totales numeric
)
LANGUAGE sql STABLE AS $$
    SELECT
        'Boletin' AS indicador,
        v.Boletin AS valor,
        CASE v.Boletin WHEN 1 THEN 'Si' ELSE 'No' END AS descripcion,
        COUNT(*) AS registros,
        ROUND(SUM(v.Venta_total), 2) AS ventas_totales
    FROM ventas v
    GROUP BY 2
    UNION ALL
    SELECT
        'Vale',
        v.Vale,
        CASE v.Vale WHEN 1 THEN 'Si' ELSE 'No' END,
        COUNT(*),
        ROUND(SUM(v.Venta_total), 2)
    FROM ventas v
    GROUP BY 2
    ORDER BY 1, 2;
$$;

-- Ejemplos de uso:
-- SELECT * FROM sp_estadisticas_numericas();
-- SELECT * FROM sp_medianas_numericas();
-- SELECT * FROM sp_modas_numericas();
-- SELECT * FROM sp_ventas_por_mes();
-- SELECT * FROM sp_distribucion_metodo_pago();
-- SELECT * FROM sp_distribucion_navegador();
-- SELECT * FROM sp_uso_boletin_vale();
