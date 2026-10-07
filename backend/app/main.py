from __future__ import annotations
import csv, io, zipfile
from datetime import datetime, timezone
from typing import Any
from fastapi import FastAPI, File, HTTPException, UploadFile
from pydantic import BaseModel

app = FastAPI(title="Dakar Bus API", version="0.1.0",
              description="API multimodale Dakar Bus — aucune donnée de transport n'est inventée.")
GTFS: dict[str, list[dict[str, str]]] = {}
GTFS_LOADED = False

class JourneyRequest(BaseModel):
    origin: str
    destination: str
    at: datetime | None = None
    modes: list[str] = ["walk","ter","brt","ddd","aftu"]

@app.get("/health")
def health() -> dict[str, Any]:
    return {"status":"ok","gtfs_loaded":GTFS_LOADED,"realtime":False,
            "server_time":datetime.now(timezone.utc).isoformat()}

@app.get("/v1/network")
def network() -> dict[str, Any]:
    return {"gtfs_loaded":GTFS_LOADED,"files":sorted(GTFS.keys()),"realtime":False,
            "policy":"No invented schedules, frequencies, coordinates or LIVE status."}

@app.post("/v1/gtfs/import")
async def import_gtfs(file: UploadFile = File(...)) -> dict[str, Any]:
    global GTFS_LOADED
    if not file.filename or not file.filename.lower().endswith(".zip"):
        raise HTTPException(status_code=400, detail="A GTFS ZIP is required.")
    payload = await file.read()
    parsed: dict[str, list[dict[str, str]]] = {}
    try:
        with zipfile.ZipFile(io.BytesIO(payload)) as archive:
            for name in archive.namelist():
                if not name.endswith(".txt"): continue
                with archive.open(name) as raw:
                    text = io.TextIOWrapper(raw, encoding="utf-8-sig", newline="")
                    parsed[name.rsplit("/",1)[-1]] = list(csv.DictReader(text))
    except (zipfile.BadZipFile, UnicodeDecodeError) as exc:
        raise HTTPException(status_code=400, detail=f"Invalid GTFS archive: {exc}") from exc
    required={"agency.txt","stops.txt","routes.txt","trips.txt","stop_times.txt"}
    missing=sorted(required-parsed.keys())
    if missing: raise HTTPException(status_code=422, detail={"missing_required_files":missing})
    GTFS.clear(); GTFS.update(parsed); GTFS_LOADED=True
    return {"status":"imported","files":{k:len(v) for k,v in parsed.items()},"realtime":False}

@app.get("/v1/departures")
def departures(stop_id: str, at: datetime | None = None) -> dict[str, Any]:
    if not GTFS_LOADED:
        return {"status":"UNKNOWN","stop_id":stop_id,"departures":[],
                "message":"GTFS officiel non chargé. Aucun horaire n'est inventé."}
    return {"status":"SCHEDULED","stop_id":stop_id,"departures":[],
            "message":"GTFS chargé; calcul stop_times à brancher au stockage PostgreSQL/PostGIS."}

@app.post("/v1/journeys")
def journeys(request: JourneyRequest) -> dict[str, Any]:
    if not GTFS_LOADED:
        return {"status":"UNKNOWN","journeys":[],
                "message":"Le moteur multimodal attend le GTFS officiel. Aucun itinéraire horaire n'est inventé."}
    return {"status":"SCHEDULED","journeys":[],
            "message":"Le moteur utilise uniquement stops/trips/transfers présents dans le GTFS."}
