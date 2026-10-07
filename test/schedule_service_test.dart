import 'package:flutter_test/flutter_test.dart';
import 'package:dakar_bus/models/mobility_models.dart';
import 'package:dakar_bus/services/schedule_service.dart';

void main() {
  test('calculates verified scheduled wait without sub-minute wording', () {
    final now = DateTime(2026, 10, 7, 14, 38, 30);
    final departure = Departure(
      tripId: 'trip', routeId: 'route', stopId: 'stop', destination: 'destination',
      scheduledAt: DateTime(2026, 10, 7, 14, 40),
      status: ScheduleStatus.scheduled,
      provenance: const Provenance(source: 'test', sourceType: 'GTFS', status: 'VERIFIED'),
    );
    expect(const ScheduleService().waitLabel(departure, now), '2 mn');
  });

  test('unknown time stays unavailable', () {
    final departure = Departure(
      tripId: 'trip', routeId: 'route', stopId: 'stop', destination: 'destination',
      status: ScheduleStatus.unknown,
      provenance: const Provenance(source: 'none', sourceType: 'UNKNOWN', status: 'UNKNOWN'),
    );
    expect(const ScheduleService().waitLabel(departure, DateTime(2026, 10, 7)), 'Horaire indisponible');
  });
}
