# Dakar Bus API

Backend FastAPI préparé pour recevoir le GTFS officiel CETUD/opérateurs.

Aucun horaire, arrêt, fréquence, direction ou position n'est inventé.
REAL_TIME sera utilisé uniquement avec un flux temps réel réellement connecté.
Sans GTFS chargé, les endpoints horaires et itinéraires renvoient UNKNOWN.

Import minimal requis: agency.txt, stops.txt, routes.txt, trips.txt, stop_times.txt.

Lancer:
cd backend
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload

Importer:
curl -X POST http://localhost:8000/v1/gtfs/import -F file=@official-feed.zip
