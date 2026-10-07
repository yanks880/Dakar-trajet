import '../models/mobility_models.dart';
import '../services/api_client.dart';

class NetworkSearchResult {
  final String id;
  final String name;
  final double? lat;
  final double? lon;
  const NetworkSearchResult({required this.id, required this.name, this.lat, this.lon});
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

  List<Route> get routes => const [];
  List<Stop> get stops => const [];
  List<Departure> departuresForStop(String stopId, DateTime now) => const [];
  List<Journey> searchJourneys({required Stop origin, required Stop destination, required DateTime now}) => const [];
}
