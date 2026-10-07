from __future__ import annotations

import csv
import io
import zipfile
from datetime import date, datetime, timezone
from typing import Any

from fastapi import FastAPI, File, HTTPException, UploadFile
from pydantic import BaseModel

app = FastAPI(
    title="Dakar Bus API",
    version="0.2.0",
    description="API multimodale Dakar Bus — aucune donnée de transport n'est inventée.",
)

GTFS: dict[str, list[dict[str, str]]] = {}
GTFS_LOADED = False


class JourneyRequest(BaseModel):
    origin: str
    destination: str
    at: datetime | None = None
    modes: list[str] = ["walk", "ter", "brt", "ddd", "aftu"]


def rows(name: str) -> list[dict[str, str]]:
    return GTFS.get(name, [])


def parse_gtfs_time(value: str) -> int | None:
    try:
        h, m, s = value.split(":")
        return int(h) * 3600 + int(m) * 60 + int(s)
    except (ValueError, AttributeError):
        return None


def service_active(service_id: str, day: date) -> bool:
    calendars = {r["service_id"]: r for r in rows("calendar.txt")}
    exceptions = {
        (r["service_id"], r["date"]): r["exception_type"]
        for r in rows("calendar_dates.txt")
    }
    key = (service_id, day.strftime("%Y%m%d"))
    if key in exceptions:
        return exceptions[key] == "1"

    cal = calendars.get(service_id)
    if not cal:
        return True

    weekday = day.strftime("%A").lower()
    field = {
        "monday": "monday", "tuesday": "tuesday", "wednesday": "wednesday",
        "thursday": "thursday", "friday": "friday", "saturday": "saturday",
        "sunday": "sunday",
    }[weekday]
    return (
        cal.get(field) == "1"
        and cal.get("start_date", "") <= day.strftime("%Y%m%d")
        and cal.get("end_date", "99999999") >= day.strftime("%Y%m%d")
    )


def next_departures(stop_id: str, at: datetime, limit: int = 5) -> list[dict[str, Any]]:
    trips = {r["trip_id"]: r for r in rows("trips.txt")}
    routes = {r["route_id"]: r for r in rows("routes.txt")}
    target = at.hour * 3600 + at.minute * 60 + at.second
    result: list[dict[str, Any]] = []

    for st in rows("stop_times.txt"):
        if st.get("stop_id") != stop_id:
            continue
        trip = trips.get(st.get("trip_id", ""))
        if not trip or not service_active(trip.get("service_id", ""), at.date()):
            continue
        seconds = parse_gtfs_time(st.get("departure_time", ""))
        if seconds is None or seconds < target:
            continue
        route = routes.get(trip.get("route_id", ""), {})
        result.append({
            "trip_id": trip.get("trip_id"),
            "route_id": trip.get("route_id"),
            "route_name": route.get("route_long_name") or route.get("route_short_name"),
            "route_short_name": route.get("route_short_name"),
            "headsign": trip.get("trip_headsign"),
            "departure_time": st.get("departure_time"),
            "status": "SCHEDULED",
        })

    result.sort(key=lambda x: parse_gtfs_time(x["departure_time"]) or 10**9)
    return result[:limit]


@app.get("/health")
def health() -> dict[str, Any]:
    return {
        "status": "ok",
        "gtfs_loaded": GTFS_LOADED,
        "realtime": False,
        "server_time": datetime.now(timezone.utc).isoformat(),
    }


@app.get("/v1/network")
def network() -> dict[str, Any]:
    return {
        "gtfs_loaded": GTFS_LOADED,
        "files": sorted(GTFS.keys()),
        "realtime": False,
        "policy": "No invented schedules, frequencies, coordinates or LIVE status.",
    }


@app.get("/v1/search")
def search(q: str) -> dict[str, Any]:
    query = q.strip().lower()
    if not GTFS_LOADED or not query:
        return {"status": "UNKNOWN", "results": []}

    results = []
    for stop in rows("stops.txt"):
        name = stop.get("stop_name", "")
        if query in name.lower():
            results.append({
                "type": "stop",
                "id": stop.get("stop_id"),
                "name": name,
                "lat": stop.get("stop_lat"),
                "lon": stop.get("stop_lon"),
            })
    return {"status": "SCHEDULED", "results": results[:20]}


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
                if not name.endswith(".txt"):
                    continue
                with archive.open(name) as raw:
                    text = io.TextIOWrapper(raw, encoding="utf-8-sig", newline="")
                    parsed[name.rsplit("/", 1)[-1]] = list(csv.DictReader(text))
    except (zipfile.BadZipFile, UnicodeDecodeError) as exc:
        raise HTTPException(status_code=400, detail=f"Invalid GTFS archive: {exc}") from exc

    required = {"agency.txt", "stops.txt", "routes.txt", "trips.txt", "stop_times.txt"}
    missing = sorted(required - parsed.keys())
    if missing:
        raise HTTPException(status_code=422, detail={"missing_required_files": missing})

    GTFS.clear()
    GTFS.update(parsed)
    GTFS_LOADED = True

    return {
        "status": "imported",
        "files": {name: len(rows) for name, rows in parsed.items()},
        "realtime": False,
    }


@app.get("/v1/departures")
def departures(stop_id: str, at: datetime | None = None) -> dict[str, Any]:
    if not GTFS_LOADED:
        return {
            "status": "UNKNOWN",
            "stop_id": stop_id,
            "departures": [],
            "message": "GTFS officiel non chargé. Aucun horaire n'est inventé.",
        }

    moment = at or datetime.now().astimezone()
    return {
        "status": "SCHEDULED",
        "stop_id": stop_id,
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "departures": next_departures(stop_id, moment),
    }


@app.post("/v1/journeys")
def journeys(request: JourneyRequest) -> dict[str, Any]:
    if not GTFS_LOADED:
        return {
            "status": "UNKNOWN",
            "journeys": [],
            "message": "Le moteur multimodal attend le GTFS officiel. Aucun itinéraire horaire n'est inventé.",
        }

    # Phase 1: direct journeys only. Multileg routing is intentionally reserved
    # for the graph/PostGIS layer so no false path is returned.
    origin_matches = [
        s for s in rows("stops.txt")
        if request.origin.lower() in s.get("stop_name", "").lower()
    ]
    destination_matches = [
        s for s in rows("stops.txt")
        if request.destination.lower() in s.get("stop_name", "").lower()
    ]

    stop_times = rows("stop_times.txt")
    origin_ids = {s.get("stop_id") for s in origin_matches}
    destination_ids = {s.get("stop_id") for s in destination_matches}
    origin_trips = {x.get("trip_id") for x in stop_times if x.get("stop_id") in origin_ids}
    destination_trips = {x.get("trip_id") for x in stop_times if x.get("stop_id") in destination_ids}
    direct_trip_ids = origin_trips & destination_trips

    trips = {r["trip_id"]: r for r in rows("trips.txt")}
    routes = {r["route_id"]: r for r in rows("routes.txt")}
    journeys_out = []

    for trip_id in sorted(direct_trip_ids):
        trip = trips.get(trip_id, {})
        route = routes.get(trip.get("route_id", ""), {})
        mode = route.get("route_type")
        journeys_out.append({
            "trip_id": trip_id,
            "route_id": trip.get("route_id"),
            "route_short_name": route.get("route_short_name"),
            "route_long_name": route.get("route_long_name"),
            "mode": mode,
            "status": "SCHEDULED",
        })

    return {
        "status": "SCHEDULED",
        "journeys": journeys_out[:10],
        "message": "Phase 1: trajets directs issus du GTFS. Les correspondances multimodales seront calculées par le graphe PostGIS.",
    }
