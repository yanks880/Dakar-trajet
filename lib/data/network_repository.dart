import '../models/mobility_models.dart';

class NetworkRepository {
  const NetworkRepository();
  List<Route> get routes => const [];
  List<Stop> get stops => const [];
  List<Departure> departuresForStop(String stopId, DateTime now) => const [];
  List<Journey> searchJourneys({required Stop origin, required Stop destination, required DateTime now}) => const [];
}
