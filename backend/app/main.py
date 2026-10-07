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
    version="0.3.0",
    description="API multimodale Dakar Bus — aucune donnée de transport n'est inventée.",
)

GTFS: dict[str, list[dict[str, str]]] = {}
GTFS_LOADED = False


class JourneyRequest(BaseModel):
    origin: str
    destination: str
    at: datetime | None = None
    modes: list[str] = ["ter", "bus"]


REQUIRED_COLUMNS: dict[str, set[str]] = {
    "agency.txt": {"agency_id", "agency_name"},
    "stops.txt": {"stop_id", "stop_name", "stop_lat", "stop_lon"},
    "routes.txt": {"route_id", "route_type"},
    "trips.txt": {"route_id", "service_id", "trip_id"},
    "stop_times.txt": {"trip_id", "arrival_time", "departure_time", "stop_id", "stop_sequence"},
}

UNIQUE_KEYS = {
    "agency.txt": "agency_id",
    "stops.txt": "stop_id",
    "routes.txt": "route_id",
    "trips.txt": "trip_id",
}

FOREIGN_KEYS = {
    "trips.txt": [("route_id", "routes.txt", "route_id"), ("service_id", "calendar.txt", "service_id")],
    "stop_times.txt": [("trip_id", "trips.txt", "trip_id"), ("stop_id", "stops.txt", "stop_id")],
}


def rows(name: str) -> list[dict[str, str]]:
    return GTFS.get(name, [])


def parse_gtfs_time(value: str) -> int | None:
    try:
        h, m, s = value.split(":")
        h, m, s = int(h), int(m), int(s)
        if h < 0 or m not in range(60) or s not in range(60):
            return None
        return h * 3600 + m * 60 + s
    except (ValueError, AttributeError):
        return None


def validate_gtfs(parsed: dict[str, list[dict[str, str]]]) -> list[str]:
    errors: list[str] = []
    required = set(REQUIRED_COLUMNS)
    missing = sorted(required - parsed.keys())
    if missing:
        errors.append(f"missing required files: {', '.join(missing)}")
        return errors

    for filename, columns in REQUIRED_COLUMNS.items():
        actual = set(parsed[filename][0].keys()) if parsed[filename] else set()
        missing_columns = sorted(columns - actual)
        if missing_columns:
            errors.append(
                f"{filename}: missing required columns: {', '.join(missing_columns)}"
            )

    for filename, key in UNIQUE_KEYS.items():
        seen: set[str] = set()
        duplicates: set[str] = set()
        for row in parsed.get(filename, []):
            value = row.get(key, "").strip()
            if not value:
                errors.append(f"{filename}: empty {key}")
                continue
            if value in seen:
                duplicates.add(value)
            seen.add(value)
        if duplicates:
            errors.append(
                f"{filename}: duplicate {key}: {', '.join(sorted(duplicates)[:20])}"
            )

    for child_file, refs in FOREIGN_KEYS.items():
        for child_key, parent_file, parent_key in refs:
            if child_file == "trips.txt" and child_key == "service_id":
                parent_values = {
                    row.get(parent_key, "").strip()
                    for row in parsed.get("calendar.txt", [])
                } | {
                    row.get(parent_key, "").strip()
                    for row in parsed.get("calendar_dates.txt", [])
                }
                if not parent_values:
                    errors.append("trips.txt: service_id has no calendar.txt or calendar_dates.txt source")
                    continue
            else:
                parent_values = {
                    row.get(parent_key, "").strip()
                    for row in parsed.get(parent_file, [])
                }
            for row in parsed.get(child_file, []):
                value = row.get(child_key, "").strip()
                if value and value not in parent_values:
                    errors.append(
                        f"{child_file}: {child_key}={value} has no match in {parent_file}"
                    )
                    if len(errors) >= 50:
                        return errors

    for row in parsed.get("stop_times.txt", []):
        for key in ("arrival_time", "departure_time"):
            value = row.get(key, "")
            if parse_gtfs_time(value) is None:
                errors.append(f"stop_times.txt: invalid {key}={value}")
                if len(errors) >= 50:
                    return errors

    return errors[:50]


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

    field = day.strftime("%A").lower()
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


@app.get("/v1/stops")
def stops(limit: int = 100) -> dict[str, Any]:
    if not GTFS_LOADED:
        return {"status": "UNKNOWN", "stops": [], "message": "GTFS officiel non chargé."}
    safe_limit = max(1, min(limit, 500))
    return {
        "status": "SCHEDULED",
        "stops": [
            {"id": s.get("stop_id"), "name": s.get("stop_name"), "lat": s.get("stop_lat"), "lon": s.get("stop_lon"), "source_status": "GTFS"}
            for s in rows("stops.txt")[:safe_limit]
        ],
    }


@app.get("/v1/stops/{stop_id}")
def stop_detail(stop_id: str) -> dict[str, Any]:
    if not GTFS_LOADED:
        return {"status": "UNKNOWN", "stop": None, "departures": [], "message": "GTFS officiel non chargé."}
    stop = next((s for s in rows("stops.txt") if s.get("stop_id") == stop_id), None)
    if stop is None:
        raise HTTPException(status_code=404, detail="Stop not found")
    return {
        "status": "SCHEDULED",
        "stop": {"id": stop.get("stop_id"), "name": stop.get("stop_name"), "lat": stop.get("stop_lat"), "lon": stop.get("stop_lon")},
        "departures": next_departures(stop_id, datetime.now().astimezone()),
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

    errors = validate_gtfs(parsed)
    if errors:
        raise HTTPException(
            status_code=422,
            detail={
                "status": "REJECTED",
                "reason": "GTFS validation failed; existing canonical dataset was not replaced.",
                "errors": errors,
            },
        )

    GTFS.clear()
    GTFS.update(parsed)
    GTFS_LOADED = True

    return {
        "status": "IMPORTED",
        "files": {name: len(data) for name, data in parsed.items()},
        "realtime": False,
        "validation": "PASSED",
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
    """Return only journeys that can be proven from the loaded GTFS.

    This phase deliberately computes direct trips only. It never invents walking
    times, transfer times, frequencies, realtime positions or unsupported modes.
    """
    if not GTFS_LOADED:
        return {
            "status": "UNKNOWN",
            "journeys": [],
            "message": "Le moteur multimodal attend le GTFS officiel. Aucun itinéraire horaire n'est inventé.",
        }

    origin_query = request.origin.strip().lower()
    destination_query = request.destination.strip().lower()
    if not origin_query or not destination_query:
        return {"status": "UNKNOWN", "journeys": [], "message": "Origine et destination requises."}

    origin_ids = {
        s.get("stop_id") for s in rows("stops.txt")
        if origin_query in s.get("stop_name", "").lower()
    }
    destination_ids = {
        s.get("stop_id") for s in rows("stops.txt")
        if destination_query in s.get("stop_name", "").lower()
    }
    if not origin_ids or not destination_ids:
        return {
            "status": "UNKNOWN",
            "journeys": [],
            "message": "Origine ou destination absente du GTFS chargé.",
        }

    moment = request.at or datetime.now().astimezone()
    allowed_modes = {m.strip().lower() for m in request.modes if m.strip()}
    # GTFS route_type is authoritative. We only expose a local mode label when
    # the GTFS route_type can prove the family; operator-specific labels are not guessed.
    route_type_mode = {"2": "ter", "3": "bus"}
    trips = {r["trip_id"]: r for r in rows("trips.txt")}
    routes = {r["route_id"]: r for r in rows("routes.txt")}
    grouped: dict[str, list[dict[str, str]]] = {}
    for st in rows("stop_times.txt"):
        trip_id = st.get("trip_id", "")
        if trip_id:
            grouped.setdefault(trip_id, []).append(st)

    journeys_out: list[dict[str, Any]] = []
    target_seconds = moment.hour * 3600 + moment.minute * 60 + moment.second

    for trip_id, trip_stops in grouped.items():
        trip = trips.get(trip_id)
        if not trip or not service_active(trip.get("service_id", ""), moment.date()):
            continue
        route = routes.get(trip.get("route_id", ""), {})
        mode = route_type_mode.get(route.get("route_type", ""), "unknown")
        if allowed_modes and mode != "unknown" and mode not in allowed_modes and not (mode == "bus" and bool({"brt", "ddd", "aftu"} & allowed_modes)):
            continue

        ordered = sorted(
            trip_stops,
            key=lambda x: int(x.get("stop_sequence", "0") or "0"),
        )
        origin_rows = [x for x in ordered if x.get("stop_id") in origin_ids]
        destination_rows = [x for x in ordered if x.get("stop_id") in destination_ids]
        for origin_row in origin_rows:
            dep_seconds = parse_gtfs_time(origin_row.get("departure_time", ""))
            if dep_seconds is None or dep_seconds < target_seconds:
                continue
            for destination_row in destination_rows:
                if int(origin_row.get("stop_sequence", "0") or "0") >= int(destination_row.get("stop_sequence", "0") or "0"):
                    continue
                arr_seconds = parse_gtfs_time(destination_row.get("arrival_time", ""))
                if arr_seconds is None or arr_seconds < dep_seconds:
                    continue
                journeys_out.append({
                    "trip_id": trip_id,
                    "route_id": trip.get("route_id"),
                    "route_short_name": route.get("route_short_name"),
                    "route_long_name": route.get("route_long_name"),
                    "route_type": route.get("route_type"),
                    "mode": mode,
                    "headsign": trip.get("trip_headsign"),
                    "departure_time": origin_row.get("departure_time"),
                    "arrival_time": destination_row.get("arrival_time"),
                    "status": "SCHEDULED",
                    "source_status": "GTFS",
                })
                break

    journeys_out.sort(key=lambda x: (
        parse_gtfs_time(x.get("departure_time", "")) or 10**9,
        parse_gtfs_time(x.get("arrival_time", "")) or 10**9,
    ))
    return {
        "status": "SCHEDULED" if journeys_out else "UNKNOWN",
        "journeys": journeys_out[:10],
        "message": "Trajets directs calculés exclusivement à partir des horaires GTFS vérifiés." if journeys_out else "Aucun trajet direct vérifié trouvé pour le moment demandé.",
    }
