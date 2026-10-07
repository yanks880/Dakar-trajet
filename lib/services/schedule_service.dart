import '../models/mobility_models.dart';

class ScheduleService {
  const ScheduleService();

  int? remainingMinutes(Departure departure, DateTime now) {
    final at = departure.estimatedAt ?? departure.scheduledAt;
    if (at == null) return null;
    final seconds = at.difference(now).inSeconds;
    if (seconds <= 0) return 0;
    return (seconds / 60).ceil();
  }

  String waitLabel(Departure departure, DateTime now) {
    final minutes = remainingMinutes(departure, now);
    if (minutes == null) return 'Horaire indisponible';
    if (minutes == 0) return 'À l’arrêt';
    return minutes == 1 ? '1 mn' : '$minutes mn';
  }

  String statusLabel(ScheduleStatus status) => switch (status) {
    ScheduleStatus.scheduled => 'Horaire théorique',
    ScheduleStatus.estimated => 'Passage estimé',
    ScheduleStatus.realTime => 'Temps réel',
    ScheduleStatus.unknown => 'Donnée indisponible',
  };
}
