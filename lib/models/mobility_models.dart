enum MobilityMode { walk, ter, brt, ddd, aftu, transfer }

enum ScheduleStatus { scheduled, estimated, realTime, unknown }

class Provenance {
  final String source;
  final String sourceType;
  final DateTime? dateVerified;
  final double? confidence;
  final String status;
  const Provenance({required this.source, required this.sourceType, this.dateVerified, this.confidence, required this.status});
}

class Stop {
  final String id, name;
  final double lat, lon;
  final Provenance provenance;
  const Stop({required this.id, required this.name, required this.lat, required this.lon, required this.provenance});
}

class Route {
  final String id, shortName, longName;
  final MobilityMode mode;
  final Provenance provenance;
  const Route({required this.id, required this.shortName, required this.longName, required this.mode, required this.provenance});
}

class Departure {
  final String tripId, routeId, stopId, destination;
  final DateTime? scheduledAt;
  final DateTime? estimatedAt;
  final ScheduleStatus status;
  final Provenance provenance;
  const Departure({required this.tripId, required this.routeId, required this.stopId, required this.destination, this.scheduledAt, this.estimatedAt, required this.status, required this.provenance});
}

class JourneyLeg {
  final MobilityMode mode;
  final String? routeId;
  final String fromStop, toStop;
  final DateTime? departureAt, arrivalAt;
  final ScheduleStatus status;
  const JourneyLeg({required this.mode, this.routeId, required this.fromStop, required this.toStop, this.departureAt, this.arrivalAt, required this.status});
}

class Journey {
  final List<JourneyLeg> legs;
  final bool verified;
  const Journey({required this.legs, required this.verified});
}
