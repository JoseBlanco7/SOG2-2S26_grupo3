

from __future__ import annotations

import base64
import os
from pathlib import Path
from typing import Any

from dotenv import find_dotenv, load_dotenv
from google.adk.agents import Agent
from google.adk.tools.base_tool import BaseTool
from google.adk.tools.mcp_tool.mcp_session_manager import StdioConnectionParams
from google.adk.tools.mcp_tool.mcp_toolset import McpToolset
from google.adk.tools.tool_context import ToolContext
from google.genai import types as genai_types
from mcp import StdioServerParameters

load_dotenv(find_dotenv())

MODEL = os.getenv("GOOGLE_MODEL", "gemini-2.0-flash")
ROOT = Path(__file__).resolve().parents[1]
MCP_SERVER_FILE = ROOT / "MCP_SERVER" / "server.py"
MCP_SERVER_PYTHON = ROOT / "MCP_SERVER" / "venv" / "Scripts" / "python.exe"


def _mcp_python_command() -> str:
    if MCP_SERVER_PYTHON.exists():
        return str(MCP_SERVER_PYTHON)
    return "python"


MCP_TOOLSET = McpToolset(
    connection_params=StdioConnectionParams(
        server_params=StdioServerParameters(
            command=_mcp_python_command(),
            args=[str(MCP_SERVER_FILE)],
            cwd=str(MCP_SERVER_FILE.parent),
        )
    )
)

async def _adjuntar_grafico_como_artifact(
    tool: BaseTool,
    args: dict[str, Any],
    tool_context: ToolContext,
    tool_response: dict[str, Any],
) -> dict[str, Any] | None:
    if not tool.name.startswith("grafico_"):
        return None

    bloques = tool_response.get("content") or []
    bloque_imagen = next((b for b in bloques if b.get("type") == "image"), None)
    if bloque_imagen is None:
        return None

    imagen_bytes = base64.b64decode(bloque_imagen["data"])
    nombre_archivo = f"{tool.name}.png"
    await tool_context.save_artifact(
        filename=nombre_archivo,
        artifact=genai_types.Part.from_bytes(
            data=imagen_bytes, mime_type=bloque_imagen["mimeType"]
        ),
    )
    return {"resultado": f"Grafico generado y adjuntado como '{nombre_archivo}'."}


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
        "Si te piden un grafico, llama al tool 'grafico_...' correspondiente: "
        "la imagen se adjunta sola al chat, tu solo confirma que la generaste "
        "y describe brevemente que muestra. "
        "Cuando aplique, resume hallazgos clave y una recomendacion accionable."
    ),
    tools=[MCP_TOOLSET],
    after_tool_callback=_adjuntar_grafico_como_artifact,
)
