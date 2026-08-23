# SOG2-2S26_grupo3

## Generar graficas
```powershell
cd ANALISIS
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
python eda.py
```

##  Levantar MCP Server

```powershell
cd MCP_SERVER
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
python server.py
```


## 3) Levantar Agente ADK

En otra terminal:

```powershell
cd AGENTE
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
.\venv\Scripts\adk.exe web
```

