"""
MCP Server que expone las funciones sp_... de la base `venta_online` 
como tools, para que el agente conversacional (Google ADK) pueda responder
preguntas de analisis exploratorio, tendencias, segmentacion y correlacion
sin tener que escribir SQL.

Cada tool ejecuta una funcion SQL fija y sin parametros de usuario

Uso:
cd "MCP_SERVER"
python -m venv venv
venv/Scripts/activate
pip install -r requirements.txt
python server.py
"""

import os
from datetime import date, datetime
from decimal import Decimal
from pathlib import Path
from typing import Any

import psycopg2
import psycopg2.extras
from dotenv import find_dotenv, load_dotenv
from mcp.server.fastmcp import FastMCP, Image

load_dotenv(find_dotenv())

DATABASE_URL = os.environ["DATABASE_URL"]
GRAFICOS_DIR = Path(__file__).resolve().parent.parent / "ANALISIS" / "graficos"

mcp = FastMCP("venta-online-analytics")


def _jsonable(value: Any) -> Any:
    if isinstance(value, Decimal):
        return float(value)
    if isinstance(value, (date, datetime)):
        return value.isoformat()
    return value


def _call_sp(nombre_funcion: str) -> list[dict[str, Any]]:
    conn = psycopg2.connect(DATABASE_URL)
    try:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute(f"SELECT * FROM {nombre_funcion}();")
            filas = cur.fetchall()
    finally:
        conn.close()
    return [{k: _jsonable(v) for k, v in fila.items()} for fila in filas]


def _leer_grafico(nombre_archivo: str) -> Image:
    ruta = GRAFICOS_DIR / nombre_archivo
    if not ruta.exists():
        raise FileNotFoundError(
            f"No se encontro '{nombre_archivo}' en {GRAFICOS_DIR}. "
            "Hay que correr ANALISIS/eda.py primero para generar los graficos."
        )
    return Image(data=ruta.read_bytes(), format="png")


@mcp.tool()
def estadisticas_numericas() -> list[dict[str, Any]]:
    """Media (promedio) de Edad, Venta_total, N_Compras, MontoCompra y Tiempo."""
    return _call_sp("sp_estadisticas_numericas")


@mcp.tool()
def medianas_numericas() -> list[dict[str, Any]]:
    """Mediana de las variables numericas principales (Edad, Venta_total, N_Compras, MontoCompra, Tiempo)."""
    return _call_sp("sp_medianas_numericas")


@mcp.tool()
def modas_numericas() -> list[dict[str, Any]]:
    """Moda (valor mas frecuente) de las variables numericas principales."""
    return _call_sp("sp_modas_numericas")


@mcp.tool()
def ventas_por_mes() -> list[dict[str, Any]]:
    """Ventas totales, registros y venta promedio agrupados por mes de FechaCompra."""
    return _call_sp("sp_ventas_por_mes")


@mcp.tool()
def distribucion_metodo_pago() -> list[dict[str, Any]]:
    """Registros y ventas totales agrupados por metodo de pago (efectivo, credito, debito)."""
    return _call_sp("sp_distribucion_metodo_pago")


@mcp.tool()
def distribucion_navegador() -> list[dict[str, Any]]:
    """Registros y ventas totales agrupados por navegador/canal (incluye tienda fisica)."""
    return _call_sp("sp_distribucion_navegador")


@mcp.tool()
def uso_boletin_vale() -> list[dict[str, Any]]:
    """Registros y ventas totales segun uso de Boletin y de Vale por separado."""
    return _call_sp("sp_uso_boletin_vale")


@mcp.tool()
def meses_venta_extremos() -> list[dict[str, Any]]:
    """Meses ordenados de mayor a menor venta total, para identificar el mejor y el peor mes."""
    return _call_sp("sp_meses_venta_extremos")


@mcp.tool()
def navegadores_preferencia() -> list[dict[str, Any]]:
    """Navegadores/canales ordenados por preferencia (cantidad de registros) con su porcentaje del total."""
    return _call_sp("sp_navegadores_preferencia")


@mcp.tool()
def comparacion_metodo_pago() -> list[dict[str, Any]]:
    """Compara efectivo vs tarjeta de credito vs tarjeta de debito en registros, ventas y porcentaje del total."""
    return _call_sp("sp_comparacion_metodo_pago")


@mcp.tool()
def meses_boletin_vale() -> list[dict[str, Any]]:
    """Boletines y vales usados por mes, para identificar en que meses se usaron mas."""
    return _call_sp("sp_meses_boletin_vale")


@mcp.tool()
def segmentacion_edad() -> list[dict[str, Any]]:
    """Clientes agrupados por rango de edad (18-24, 25-34, ...) con venta y compras promedio."""
    return _call_sp("sp_segmentacion_edad")


@mcp.tool()
def comparacion_genero() -> list[dict[str, Any]]:
    """Compara el comportamiento de compra (venta y compras promedio) entre generos."""
    return _call_sp("sp_comparacion_genero")


@mcp.tool()
def comparacion_boletin_vale() -> list[dict[str, Any]]:
    """Compara clientes segun combinacion de uso de Boletin y Vale (si/si, si/no, no/si, no/no)."""
    return _call_sp("sp_comparacion_boletin_vale")


@mcp.tool()
def correlacion_edad_venta() -> list[dict[str, Any]]:
    """Coeficiente de correlacion de Pearson entre Edad y Venta_total."""
    return _call_sp("sp_correlacion_edad_venta")


@mcp.tool()
def genero_metodo_pago() -> list[dict[str, Any]]:
    """Tabla de relacion entre genero y metodo de pago preferido, con porcentaje dentro de cada genero."""
    return _call_sp("sp_genero_metodo_pago")


@mcp.tool()
def coeficiente_phi_boletin_vale() -> list[dict[str, Any]]:
    """Coeficiente phi que mide la correlacion entre usar Boletin y usar Vale."""
    return _call_sp("sp_coeficiente_phi_boletin_vale")


@mcp.tool()
def grafico_ventas_por_mes() -> Image:
    """Grafico de barras con las ventas totales por mes (imagen PNG)."""
    return _leer_grafico("01_ventas_por_mes.png")


@mcp.tool()
def grafico_metodo_pago() -> Image:
    """Grafico de barras con las ventas totales por metodo de pago (imagen PNG)."""
    return _leer_grafico("02_metodo_pago.png")


@mcp.tool()
def grafico_navegador() -> Image:
    """Grafico de barras con los registros por navegador o canal (imagen PNG)."""
    return _leer_grafico("03_navegador.png")


@mcp.tool()
def grafico_boletin_vale() -> Image:
    """Grafico de barras con el uso de Boletin y Vale (imagen PNG)."""
    return _leer_grafico("04_boletin_vale.png")


@mcp.tool()
def grafico_segmentacion_edad() -> Image:
    """Grafico de barras con la venta promedio por grupo de edad (imagen PNG)."""
    return _leer_grafico("05_segmentacion_edad.png")


@mcp.tool()
def grafico_comparacion_genero() -> Image:
    """Grafico de barras con la venta promedio por genero (imagen PNG)."""
    return _leer_grafico("06_comparacion_genero.png")


@mcp.tool()
def grafico_correlacion_edad_venta() -> Image:
    """Grafico de dispersion de edad vs venta total, con el coeficiente de correlacion (imagen PNG)."""
    return _leer_grafico("07_correlacion_edad_venta.png")


@mcp.tool()
def grafico_tendencia_boletin_vale() -> Image:
    """Grafico de lineas con el uso de boletines y vales por mes (imagen PNG)."""
    return _leer_grafico("08_tendencia_boletin_vale.png")


if __name__ == "__main__":
    mcp.run()
