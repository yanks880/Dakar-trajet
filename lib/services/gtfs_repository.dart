import '../domain/mobility_models.dart';

class GtfsRepository {
  bool _loaded = false;
  bool get isLoaded => _loaded;

  Future<void> loadOfficialGtfs() async {
    _loaded = false;
  }

  Future<List<Departure>> departuresForStop(String stopId, DateTime at) async {
    if (!_loaded) return const [];
    return const [];
  }
}
