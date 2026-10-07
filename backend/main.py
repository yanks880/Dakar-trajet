from datetime import datetime
from fastapi import FastAPI

app = FastAPI(title='Dakar Bus API', version='0.1.0')

@app.get('/health')
def health():
    return {'ok': True, 'service': 'dakar-bus-api'}

@app.get('/routes')
def routes():
    return {'data': [], 'status': 'UNKNOWN', 'message': 'GTFS non importé'}

@app.get('/stops')
def stops():
    return {'data': [], 'status': 'UNKNOWN', 'message': 'GTFS non importé'}

@app.get('/departures')
def departures(stop_id: str, at: datetime | None = None):
    return {'data': [], 'status': 'UNKNOWN', 'message': 'Aucun horaire vérifié disponible pour cet arrêt'}

@app.get('/journeys')
def journeys(origin: str, destination: str, at: datetime | None = None):
    return {'data': [], 'status': 'UNKNOWN', 'message': 'Itinéraires indisponibles tant que les données GTFS vérifiées ne sont pas importées'}

@app.get('/alerts')
def alerts():
    return {'data': [], 'status': 'UNKNOWN', 'message': 'Aucune alerte temps réel vérifiée disponible'}
