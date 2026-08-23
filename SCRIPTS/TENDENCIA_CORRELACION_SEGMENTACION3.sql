

-- sp_meses_venta_extremos: meses con mayor y menor venta total.
CREATE OR REPLACE FUNCTION sp_meses_venta_extremos()
RETURNS TABLE (
    mes int,
    nombre_mes text,
    ventas_totales numeric,
    registros bigint
)
LANGUAGE sql STABLE AS $$
    SELECT
        EXTRACT(MONTH FROM v.FechaCompra)::int AS mes,
        TRIM(TO_CHAR(v.FechaCompra, 'Month')) AS nombre_mes,
        ROUND(SUM(v.Venta_total), 2) AS ventas_totales,
        COUNT(*) AS registros
    FROM ventas v
    GROUP BY 1, 2
    ORDER BY 3 DESC;
$$;

-- sp_navegadores_preferencia: navegadores o canales ordenados por preferencia.
CREATE OR REPLACE FUNCTION sp_navegadores_preferencia()
RETURNS TABLE (
    navegador smallint,
    canal text,
    registros bigint,
    porcentaje_registros numeric
)
LANGUAGE sql STABLE AS $$
    SELECT
        v.Navegador,
        CASE v.Navegador
            WHEN 0 THEN 'Tienda fisica'
            ELSE CONCAT('Navegador ', v.Navegador)
        END AS canal,
        COUNT(*) AS registros,
        ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM ventas), 2) AS porcentaje_registros
    FROM ventas v
    GROUP BY 1
    ORDER BY 3 DESC;
$$;

-- sp_comparacion_metodo_pago: comparacion de efectivo con tarjetas.
CREATE OR REPLACE FUNCTION sp_comparacion_metodo_pago()
RETURNS TABLE (
    metodopago smallint,
    metodo text,
    registros bigint,
    ventas_totales numeric,
    porcentaje_ventas numeric
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
        ROUND(SUM(v.Venta_total), 2) AS ventas_totales,
        ROUND(100.0 * SUM(v.Venta_total) / (SELECT SUM(Venta_total) FROM ventas), 2) AS porcentaje_ventas
    FROM ventas v
    GROUP BY 1
    ORDER BY 4 DESC;
$$;

-- sp_meses_boletin_vale: meses con mayor uso de boletines y vales.
CREATE OR REPLACE FUNCTION sp_meses_boletin_vale()
RETURNS TABLE (
    mes int,
    nombre_mes text,
    boletines_usados bigint,
    vales_usados bigint,
    registros bigint
)
LANGUAGE sql STABLE AS $$
    SELECT
        EXTRACT(MONTH FROM v.FechaCompra)::int AS mes,
        TRIM(TO_CHAR(v.FechaCompra, 'Month')) AS nombre_mes,
        SUM(v.Boletin) AS boletines_usados,
        SUM(v.Vale) AS vales_usados,
        COUNT(*) AS registros
    FROM ventas v
    GROUP BY 1, 2
    ORDER BY 1;
$$;

-- sp_segmentacion_edad: segmentacion por grupos de edad.
CREATE OR REPLACE FUNCTION sp_segmentacion_edad()
RETURNS TABLE (
    grupo_edad text,
    registros bigint,
    venta_promedio numeric,
    ventas_totales numeric,
    compras_promedio numeric
)
LANGUAGE sql STABLE AS $$
    SELECT
        CASE
            WHEN v.Edad < 25 THEN '18-24'
            WHEN v.Edad < 35 THEN '25-34'
            WHEN v.Edad < 45 THEN '35-44'
            WHEN v.Edad < 55 THEN '45-54'
            ELSE '55 o mas'
        END AS grupo_edad,
        COUNT(*) AS registros,
        ROUND(AVG(v.Venta_total), 2) AS venta_promedio,
        ROUND(SUM(v.Venta_total), 2) AS ventas_totales,
        ROUND(AVG(v.N_Compras), 2) AS compras_promedio
    FROM ventas v
    GROUP BY 1
    ORDER BY 1;
$$;

-- sp_comparacion_genero: comparacion del comportamiento de compra por genero.
CREATE OR REPLACE FUNCTION sp_comparacion_genero()
RETURNS TABLE (
    genero smallint,
    genero_descripcion text,
    registros bigint,
    venta_promedio numeric,
    ventas_totales numeric,
    compras_promedio numeric
)
LANGUAGE sql STABLE AS $$
    SELECT
        v.Genero,
        CASE v.Genero WHEN 1 THEN 'Femenino' ELSE 'Masculino' END AS genero_descripcion,
        COUNT(*) AS registros,
        ROUND(AVG(v.Venta_total), 2) AS venta_promedio,
        ROUND(SUM(v.Venta_total), 2) AS ventas_totales,
        ROUND(AVG(v.N_Compras), 2) AS compras_promedio
    FROM ventas v
    GROUP BY 1
    ORDER BY 1;
$$;

-- sp_comparacion_boletin_vale: comparacion de clientes con boletin y vale.
CREATE OR REPLACE FUNCTION sp_comparacion_boletin_vale()
RETURNS TABLE (
    boletin smallint,
    vale smallint,
    usa_boletin text,
    usa_vale text,
    registros bigint,
    venta_promedio numeric,
    ventas_totales numeric
)
LANGUAGE sql STABLE AS $$
    SELECT
        v.Boletin,
        v.Vale,
        CASE v.Boletin WHEN 1 THEN 'Si' ELSE 'No' END AS usa_boletin,
        CASE v.Vale WHEN 1 THEN 'Si' ELSE 'No' END AS usa_vale,
        COUNT(*) AS registros,
        ROUND(AVG(v.Venta_total), 2) AS venta_promedio,
        ROUND(SUM(v.Venta_total), 2) AS ventas_totales
    FROM ventas v
    GROUP BY 1, 2
    ORDER BY 1 DESC, 2 DESC;
$$;

-- sp_correlacion_edad_venta: correlacion de Pearson entre edad y venta total.
CREATE OR REPLACE FUNCTION sp_correlacion_edad_venta()
RETURNS TABLE (
    correlacion_edad_venta_total numeric
)
LANGUAGE sql STABLE AS $$
    SELECT ROUND(
        (
            COUNT(*) * SUM(v.Edad * v.Venta_total) - SUM(v.Edad) * SUM(v.Venta_total)
        ) /
        NULLIF(SQRT(
            (
                (COUNT(*) * SUM(v.Edad * v.Edad) - SUM(v.Edad) * SUM(v.Edad)) *
                (COUNT(*) * SUM(v.Venta_total * v.Venta_total) - SUM(v.Venta_total) * SUM(v.Venta_total))
            )::numeric
        ), 0), 4
    ) AS correlacion_edad_venta_total
    FROM ventas v;
$$;

-- sp_genero_metodo_pago: tabla de relacion entre genero y metodo de pago.
CREATE OR REPLACE FUNCTION sp_genero_metodo_pago()
RETURNS TABLE (
    genero text,
    metodo text,
    registros bigint,
    porcentaje_dentro_genero numeric
)
LANGUAGE sql STABLE AS $$
    SELECT
        CASE v.Genero WHEN 1 THEN 'Femenino' ELSE 'Masculino' END AS genero,
        CASE v.MetodoPago
            WHEN 0 THEN 'Efectivo'
            WHEN 1 THEN 'Tarjeta de credito'
            WHEN 2 THEN 'Tarjeta de debito'
        END AS metodo,
        COUNT(*) AS registros,
        ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY v.Genero), 2) AS porcentaje_dentro_genero
    FROM ventas v
    GROUP BY v.Genero, v.MetodoPago
    ORDER BY 1, 2;
$$;

-- sp_coeficiente_phi_boletin_vale: coeficiente phi entre uso de boletin y uso de vale.
CREATE OR REPLACE FUNCTION sp_coeficiente_phi_boletin_vale()
RETURNS TABLE (
    a bigint,
    b bigint,
    c bigint,
    d bigint,
    coeficiente_phi numeric
)
LANGUAGE sql STABLE AS $$
    WITH tabla AS (
        SELECT
            SUM(CASE WHEN v.Boletin = 1 AND v.Vale = 1 THEN 1 ELSE 0 END) AS a,
            SUM(CASE WHEN v.Boletin = 1 AND v.Vale = 0 THEN 1 ELSE 0 END) AS b,
            SUM(CASE WHEN v.Boletin = 0 AND v.Vale = 1 THEN 1 ELSE 0 END) AS c,
            SUM(CASE WHEN v.Boletin = 0 AND v.Vale = 0 THEN 1 ELSE 0 END) AS d
        FROM ventas v
    )
    SELECT
        t.a, t.b, t.c, t.d,
        ROUND(
            (t.a * t.d - t.b * t.c) /
            NULLIF(SQRT(((t.a + t.b) * (t.c + t.d) * (t.a + t.c) * (t.b + t.d))::numeric), 0),
        4) AS coeficiente_phi
    FROM tabla t;
$$;

-- Ejemplos de uso:
-- SELECT * FROM sp_meses_venta_extremos();
-- SELECT * FROM sp_navegadores_preferencia();
-- SELECT * FROM sp_comparacion_metodo_pago();
-- SELECT * FROM sp_meses_boletin_vale();
-- SELECT * FROM sp_segmentacion_edad();
-- SELECT * FROM sp_comparacion_genero();
-- SELECT * FROM sp_comparacion_boletin_vale();
-- SELECT * FROM sp_correlacion_edad_venta();
-- SELECT * FROM sp_genero_metodo_pago();
-- SELECT * FROM sp_coeficiente_phi_boletin_vale();
