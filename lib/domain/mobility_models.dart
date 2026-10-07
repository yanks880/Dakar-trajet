enum MobilityMode { walk, ter, brt, ddd, aftu, transfer }

enum ScheduleStatus { scheduled, estimated, realTime, unknown }

class Provenance {
  final String source;
  final String sourceType;
  final String? dateSource;
  final String? dateVerified;
  final String confidence;
  final String status;

  const Provenance({
    required this.source,
    required this.sourceType,
    this.dateSource,
    this.dateVerified,
    required this.confidence,
    required this.status,
  });
}

class Departure {
  final String serviceId;
  final String label;
  final MobilityMode mode;
  final String? direction;
  final DateTime? departureAt;
  final int? remainingMinutes;
  final ScheduleStatus status;
  final Provenance provenance;

  const Departure({
    required this.serviceId,
    required this.label,
    required this.mode,
    this.direction,
    this.departureAt,
    this.remainingMinutes,
    required this.status,
    required this.provenance,
  });

  String get waitLabel {
    if ((status == ScheduleStatus.realTime || status == ScheduleStatus.scheduled) &&
        remainingMinutes != null) {
      return formatWait(remainingMinutes!);
    }
    if (status == ScheduleStatus.estimated && remainingMinutes != null) {
      return 'Passage estimé · ${remainingMinutes!} mn';
    }
    return 'Horaire non disponible';
  }
}

String formatWait(int minutes) {
  if (minutes <= 0) return 'À l’approche';
  return '$minutes mn';
}

String modeLabel(MobilityMode mode) {
  switch (mode) {
    case MobilityMode.walk: return 'À pied';
    case MobilityMode.ter: return 'TER';
    case MobilityMode.brt: return 'BRT';
    case MobilityMode.ddd: return 'DDD';
    case MobilityMode.aftu: return 'AFTU';
    case MobilityMode.transfer: return 'Correspondance';
  }
}
