"""
Analisis exploratorio, de tendencias, segmentacion y correlacion sobre la
tabla `ventas` en Supabase.

Uso:
cd "ANALISIS"
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
python eda.py
"""

import os
from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd
from dotenv import find_dotenv, load_dotenv
from sqlalchemy import create_engine

load_dotenv(find_dotenv())

DATABASE_URL = os.environ["DATABASE_URL"]
OUTPUT_DIR = Path(__file__).parent / "graficos"
OUTPUT_DIR.mkdir(exist_ok=True)

engine = create_engine(DATABASE_URL)


def cargar(sp_nombre: str) -> pd.DataFrame:
    return pd.read_sql(f"SELECT * FROM {sp_nombre}();", engine)


def revisar_calidad_datos() -> None:
    staging = pd.read_sql("SELECT * FROM ventas_staging;", engine)

    print("=== Calidad de datos (staging, antes de cargar a `ventas`) ===")
    print(f"Filas en staging: {len(staging)}")

    vacios = (staging == "").sum()
    vacios = vacios[vacios > 0]
    if vacios.empty:
        print("Sin valores vacios/faltantes en staging.")
    else:
        print("Valores vacios por columna:")
        print(vacios)

    duplicados = staging["id_cliente"].duplicated().sum()
    print(f"Id_cliente duplicados en staging: {duplicados}")
    if duplicados:
        print(
            "Decision: se descartan al cargar a `ventas` porque Id_cliente es "
            "PRIMARY KEY ahi; el INSERT falla por violacion de PK si hay repetidos."
        )
    print()


def resumen_estadistico() -> None:
    medias = cargar("sp_estadisticas_numericas")
    medianas = cargar("sp_medianas_numericas")
    modas = cargar("sp_modas_numericas")

    print("=== Estadisticas descriptivas ===")
    print("Medias:")
    print(medias.to_string(index=False))
    print("\nMedianas:")
    print(medianas.to_string(index=False))
    print("\nModas:")
    print(modas.to_string(index=False))
    print()

    resumen_path = OUTPUT_DIR.parent / "resumen_estadistico.txt"
    with open(resumen_path, "w", encoding="utf-8") as f:
        f.write("MEDIAS\n" + medias.to_string(index=False) + "\n\n")
        f.write("MEDIANAS\n" + medianas.to_string(index=False) + "\n\n")
        f.write("MODAS\n" + modas.to_string(index=False) + "\n")
    print(f"Resumen guardado en {resumen_path}")


def grafico_ventas_por_mes() -> None:
    df = cargar("sp_ventas_por_mes").sort_values("mes")
    fig, ax = plt.subplots(figsize=(9, 5))
    ax.bar(df["nombre_mes"].str.strip(), df["ventas_totales"], color="#4C72B0")
    ax.set_title("Ventas totales por mes")
    ax.set_xlabel("Mes")
    ax.set_ylabel("Ventas totales")
    plt.xticks(rotation=45, ha="right")
    fig.tight_layout()
    fig.savefig(OUTPUT_DIR / "01_ventas_por_mes.png", dpi=150)
    plt.close(fig)


def grafico_metodo_pago() -> None:
    df = cargar("sp_distribucion_metodo_pago")
    fig, ax = plt.subplots(figsize=(7, 5))
    ax.bar(df["metodo"], df["ventas_totales"], color="#55A868")
    ax.set_title("Ventas totales por metodo de pago")
    ax.set_xlabel("Metodo de pago")
    ax.set_ylabel("Ventas totales")
    fig.tight_layout()
    fig.savefig(OUTPUT_DIR / "02_metodo_pago.png", dpi=150)
    plt.close(fig)


def grafico_navegador() -> None:
    df = cargar("sp_distribucion_navegador")
    fig, ax = plt.subplots(figsize=(7, 5))
    ax.bar(df["canal"], df["registros"], color="#C44E52")
    ax.set_title("Registros por navegador o canal")
    ax.set_xlabel("Canal")
    ax.set_ylabel("Registros")
    plt.xticks(rotation=30, ha="right")
    fig.tight_layout()
    fig.savefig(OUTPUT_DIR / "03_navegador.png", dpi=150)
    plt.close(fig)


def grafico_boletin_vale() -> None:
    df = cargar("sp_uso_boletin_vale")
    colores = {"Si": "#4C72B0", "No": "#DD8452"}
    fig, ax = plt.subplots(figsize=(7, 5))
    ax.bar(
        df["indicador"] + " (" + df["descripcion"] + ")",
        df["registros"],
        color=[colores[d] for d in df["descripcion"]],
    )
    ax.set_title("Uso de Boletin y Vale")
    ax.set_ylabel("Registros")
    plt.xticks(rotation=20, ha="right")
    fig.tight_layout()
    fig.savefig(OUTPUT_DIR / "04_boletin_vale.png", dpi=150)
    plt.close(fig)


def grafico_segmentacion_edad() -> None:
    df = cargar("sp_segmentacion_edad")
    fig, ax = plt.subplots(figsize=(7, 5))
    ax.bar(df["grupo_edad"], df["venta_promedio"], color="#8172B2")
    ax.set_title("Venta promedio por grupo de edad")
    ax.set_xlabel("Grupo de edad")
    ax.set_ylabel("Venta promedio")
    fig.tight_layout()
    fig.savefig(OUTPUT_DIR / "05_segmentacion_edad.png", dpi=150)
    plt.close(fig)


def grafico_comparacion_genero() -> None:
    df = cargar("sp_comparacion_genero")
    fig, ax = plt.subplots(figsize=(7, 5))
    ax.bar(df["genero_descripcion"], df["venta_promedio"], color="#937860")
    ax.set_title("Venta promedio por genero")
    ax.set_xlabel("Genero")
    ax.set_ylabel("Venta promedio")
    fig.tight_layout()
    fig.savefig(OUTPUT_DIR / "06_comparacion_genero.png", dpi=150)
    plt.close(fig)


def grafico_correlacion_edad_venta() -> None:
    df = pd.read_sql("SELECT edad, venta_total FROM ventas;", engine)
    r = cargar("sp_correlacion_edad_venta")["correlacion_edad_venta_total"].iloc[0]

    fig, ax = plt.subplots(figsize=(7, 5))
    ax.scatter(df["edad"], df["venta_total"], alpha=0.4, s=12, color="#4C72B0")
    ax.set_title(f"Edad vs Venta total (r = {r})")
    ax.set_xlabel("Edad")
    ax.set_ylabel("Venta total")
    fig.tight_layout()
    fig.savefig(OUTPUT_DIR / "07_correlacion_edad_venta.png", dpi=150)
    plt.close(fig)


def grafico_tendencia_boletin_vale() -> None:
    df = cargar("sp_meses_boletin_vale").sort_values("mes")
    fig, ax = plt.subplots(figsize=(9, 5))
    ax.plot(df["nombre_mes"].str.strip(), df["boletines_usados"], marker="o", label="Boletines")
    ax.plot(df["nombre_mes"].str.strip(), df["vales_usados"], marker="o", label="Vales")
    ax.set_title("Uso de boletines y vales por mes")
    ax.set_xlabel("Mes")
    ax.set_ylabel("Usos")
    ax.legend()
    plt.xticks(rotation=45, ha="right")
    fig.tight_layout()
    fig.savefig(OUTPUT_DIR / "08_tendencia_boletin_vale.png", dpi=150)
    plt.close(fig)


def main() -> None:
    revisar_calidad_datos()
    resumen_estadistico()

    grafico_ventas_por_mes()
    grafico_metodo_pago()
    grafico_navegador()
    grafico_boletin_vale()
    grafico_segmentacion_edad()
    grafico_comparacion_genero()
    grafico_correlacion_edad_venta()
    grafico_tendencia_boletin_vale()

    print(f"Graficos guardados en {OUTPUT_DIR}")


if __name__ == "__main__":
    main()
