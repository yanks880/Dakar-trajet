# Dakar Bus

Assistant de mobilité multimodale pour Dakar : TER, BRT, Dakar Dem Dikk, AFTU, marche et correspondances.

## Règle absolue : aucune donnée inventée

Dakar Bus sépare les données officielles/opérateur des données géographiques OSM.
Un horaire exact n'est affiché que lorsqu'il provient d'un GTFS/flux autorisé.
REAL_TIME ne sera affiché que lorsqu'un flux GTFS-RT, SAE, CAPTRANS ou API opérateur réel sera connecté.

Le CETUD indique disposer de fichiers GTFS pour le réseau collectif et précise que ces données couvrent notamment horaires, arrêts, itinéraires et trajets.

## État actuel

- Flutter : interface premium verte, carte Dakar/OSM, recherche, horaires, alertes.
- GPS : branchement Geolocator préparé.
- BRT : plage officielle publiée par le CETUD : 06:00–21:00, 4 services, départ toutes les 6 minutes. Cette information est affichée comme service/fréquence, jamais comme faux stop_times GTFS.
- TER : source officielle identifiée, import GTFS/horaires détaillés encore nécessaire.
- DDD : réseau officiel identifié à 38 lignes ; horaires détaillés GTFS à importer.
- AFTU : réseau officiel identifié à 72 lignes ; horaires détaillés GTFS à importer.
- Backend : FastAPI avec import GTFS, recherche d'arrêts et calcul des prochains départs à partir de stop_times + calendrier.
- Itinéraires : phase 1 directe GTFS ; le graphe multimodal avec correspondances sera branché sur PostgreSQL/PostGIS.
- Temps réel : NON CONNECTÉ. Aucun badge LIVE.

## Backend

Le backend se trouve dans le dossier backend.

Endpoints principaux :
- GET /health
- GET /v1/network
- GET /v1/search?q=...
- GET /v1/departures?stop_id=...
- POST /v1/journeys
- POST /v1/gtfs/import

Le fichier GTFS officiel doit être fourni par une source autorisée avant import en production.

## Déploiement

Le workflow GitHub Actions analyse, teste et construit Flutter Web.
Il prépare le déploiement GitHub Pages sous /Dakar-trajet/.

## Sources de référence

- CETUD : système de données et GTFS.
- CETUD : réseaux DDD, AFTU et BRT.
- OpenStreetMap : uniquement contexte cartographique.

## Prochaine étape critique

Recevoir le GTFS autorisé CETUD/opérateurs, l'importer, valider automatiquement les fichiers, puis connecter PostgreSQL/PostGIS + moteur de correspondances + GTFS-RT/SAE/CAPTRANS si les flux sont autorisés.
