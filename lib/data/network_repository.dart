import '../models/mobility_models.dart';
import '../services/api_client.dart';

class NetworkSearchResult {
  final String id;
  final String name;
  final double? lat;
  final double? lon;
  const NetworkSearchResult({required this.id, required this.name, this.lat, this.lon});
}

class NetworkStop {
  final String id;
  final String name;
  final double? lat;
  final double? lon;
  const NetworkStop({required this.id, required this.name, this.lat, this.lon});
}

class NetworkDeparture {
  final String? tripId;
  final String? routeId;
  final String? routeName;
  final String? routeShortName;
  final String? headsign;
  final String departureTime;
  final String status;
  const NetworkDeparture({
    this.tripId,
    this.routeId,
    this.routeName,
    this.routeShortName,
    this.headsign,
    required this.departureTime,
    required this.status,
  });
}

class NetworkStopDetail {
  final NetworkStop stop;
  final List<NetworkDeparture> departures;
  const NetworkStopDetail({required this.stop, required this.departures});
}


class NetworkNearbyStop {
  final String id, name;
  final double lat, lon, distanceM;
  final String? nextDeparture, nextRouteShortName, nextRouteName, nextHeadsign, nextStatus;
  const NetworkNearbyStop({
    required this.id,
    required this.name,
    required this.lat,
    required this.lon,
    required this.distanceM,
    this.nextDeparture,
    this.nextRouteShortName,
    this.nextRouteName,
    this.nextHeadsign,
    this.nextStatus,
  });
}

class NetworkGeometry {
  final String routeId;
  final String? shortName, longName;
  final List<({double lat, double lon})> points;
  const NetworkGeometry({required this.routeId, this.shortName, this.longName, required this.points});
}

class NetworkRepository {
  final ApiClient api;
  const NetworkRepository({required this.api});

  Future<bool> gtfsLoaded() async {
    final data = await api.getJson('/v1/network');
    return data['gtfs_loaded'] == true;
  }

  Future<List<NetworkSearchResult>> search(String query) async {
    final data = await api.getJson('/v1/search?q=${Uri.encodeQueryComponent(query)}');
    final raw = data['results'];
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((item) => NetworkSearchResult(
      id: item['id']?.toString() ?? '',
      name: item['name']?.toString() ?? '',
      lat: double.tryParse(item['lat']?.toString() ?? ''),
      lon: double.tryParse(item['lon']?.toString() ?? ''),
    )).where((x) => x.id.isNotEmpty && x.name.isNotEmpty).toList();
  }

  Future<List<NetworkStop>> stops({int limit = 100}) async {
    final data = await api.getJson('/v1/stops?limit=$limit');
    final raw = data['stops'];
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((item) => NetworkStop(
      id: item['id']?.toString() ?? '',
      name: item['name']?.toString() ?? '',
      lat: double.tryParse(item['lat']?.toString() ?? ''),
      lon: double.tryParse(item['lon']?.toString() ?? ''),
    )).where((x) => x.id.isNotEmpty && x.name.isNotEmpty).toList();
  }

  Future<NetworkStopDetail> stopDetail(String stopId) async {
    final data = await api.getJson('/v1/stops/${Uri.encodeComponent(stopId)}');
    final rawStop = data['stop'];
    if (rawStop is! Map) throw const ApiException('Arrêt introuvable');
    final stop = NetworkStop(
      id: rawStop['id']?.toString() ?? '',
      name: rawStop['name']?.toString() ?? '',
      lat: double.tryParse(rawStop['lat']?.toString() ?? ''),
      lon: double.tryParse(rawStop['lon']?.toString() ?? ''),
    );
    final rawDepartures = data['departures'];
    final departures = rawDepartures is List
        ? rawDepartures.whereType<Map>().map((item) => NetworkDeparture(
            tripId: item['trip_id']?.toString(),
            routeId: item['route_id']?.toString(),
            routeName: item['route_name']?.toString(),
            routeShortName: item['route_short_name']?.toString(),
            headsign: item['headsign']?.toString(),
            departureTime: item['departure_time']?.toString() ?? '',
            status: item['status']?.toString() ?? 'UNKNOWN',
          )).where((x) => x.departureTime.isNotEmpty).toList()
        : const <NetworkDeparture>[];
    return NetworkStopDetail(stop: stop, departures: departures);
  }

  Future<List<NetworkDeparture>> departures(String stopId) async {
    final data = await api.getJson('/v1/departures?stop_id=${Uri.encodeQueryComponent(stopId)}');
    final raw = data['departures'];
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((item) => NetworkDeparture(
      tripId: item['trip_id']?.toString(),
      routeId: item['route_id']?.toString(),
      routeName: item['route_name']?.toString(),
      routeShortName: item['route_short_name']?.toString(),
      headsign: item['headsign']?.toString(),
      departureTime: item['departure_time']?.toString() ?? '',
      status: item['status']?.toString() ?? 'UNKNOWN',
    )).where((x) => x.departureTime.isNotEmpty).toList();
  }


  Future<List<NetworkNearbyStop>> nearby(double lat, double lon, {int walkMinutes = 15}) async {
    final data = await api.getJson('/v1/nearby?lat=$lat&lon=$lon&walk_minutes=$walkMinutes');
    final raw = data['stops'];
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((item) => NetworkNearbyStop(
      id: item['id']?.toString() ?? '',
      name: item['name']?.toString() ?? '',
      lat: double.tryParse(item['lat']?.toString() ?? '') ?? 0,
      lon: double.tryParse(item['lon']?.toString() ?? '') ?? 0,
      distanceM: double.tryParse(item['distance_m']?.toString() ?? '') ?? 0,
      nextDeparture: item['next_departure']?.toString(),
      nextRouteShortName: item['next_route_short_name']?.toString(),
      nextRouteName: item['next_route_name']?.toString(),
      nextHeadsign: item['next_headsign']?.toString(),
      nextStatus: item['next_status']?.toString(),
    )).where((x) => x.id.isNotEmpty && x.name.isNotEmpty && x.lat != 0 && x.lon != 0).toList();
  }

  Future<List<NetworkGeometry>> geometries() async {
    final data = await api.getJson('/v1/geometries');
    final raw = data['routes'];
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((item) {
      final points = item['geometry'] is List
          ? (item['geometry'] as List).whereType<List>().map((p) => (lat: double.tryParse(p[0].toString()) ?? 0, lon: double.tryParse(p[1].toString()) ?? 0)).where((p) => p.lat != 0 && p.lon != 0).toList()
          : <({double lat, double lon})>[];
      return NetworkGeometry(routeId: item['route_id']?.toString() ?? '', shortName: item['route_short_name']?.toString(), longName: item['route_long_name']?.toString(), points: points);
    }).where((x) => x.routeId.isNotEmpty && x.points.length > 1).toList();
  }

  List<Route> get routes => const [];
  List<Stop> get allStops => const [];
  List<Departure> departuresForStop(String stopId, DateTime now) => const [];
  List<Journey> searchJourneys({required Stop origin, required Stop destination, required DateTime now}) => const [];
}
