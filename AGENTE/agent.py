"""
Agente de Google ADK conectado al MCP Server local del proyecto.

Ejecutar:
1) Levantar el MCP server en otra terminal:
   cd MCP_SERVER && python server.py
2) Correr este agente con ADK:
   cd AGENTE && adk web
"""

from __future__ import annotations

import os
from pathlib import Path

from dotenv import find_dotenv, load_dotenv
from google.adk.agents import Agent
from google.adk.tools.mcp_tool.mcp_toolset import McpToolset
from mcp import StdioServerParameters

load_dotenv(find_dotenv())

MODEL = os.getenv("GOOGLE_MODEL", "gemini-2.0-flash")
ROOT = Path(__file__).resolve().parents[1]
MCP_SERVER_FILE = ROOT / "MCP_SERVER" / "server.py"
MCP_SERVER_PYTHON = ROOT / "MCP_SERVER" / "venv" / "Scripts" / "python.exe"


def _mcp_python_command() -> str:
    # Usa el interprete del venv del servidor si ya existe.
    # Si no existe aun, cae al python del entorno actual.
    if MCP_SERVER_PYTHON.exists():
        return str(MCP_SERVER_PYTHON)
    return "python"


MCP_TOOLSET = McpToolset(
    connection_params=StdioServerParameters(
        command=_mcp_python_command(),
        args=[str(MCP_SERVER_FILE)],
        cwd=str(MCP_SERVER_FILE.parent),
    )
)

root_agent = Agent(
    name="ventas_analytics_agent",
    model=MODEL,
    description=(
        "Agente analista para ventas online 2021. Usa tools MCP conectadas "
        "a funciones SQL predefinidas para responder preguntas de EDA, "
        "tendencias, segmentacion y correlacion."
    ),
    instruction=(
        "Eres un analista de datos junior experto en explicar resultados de ventas. "
        "Responde en espanol claro. "
        "Siempre que la pregunta requiera datos, usa primero las tools MCP. "
        "No inventes resultados ni valores. "
        "Cuando aplique, resume hallazgos clave y una recomendacion accionable."
    ),
    tools=[MCP_TOOLSET],
)
