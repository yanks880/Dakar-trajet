import '../domain/mobility_models.dart';

class VerifiedNetwork {
  static const brt = Provenance(
    source: 'CETUD / SunuBRT',
    sourceType: 'OFFICIAL',
    dateSource: '2026-10-07',
    dateVerified: '2026-10-07',
    confidence: 'HIGH',
    status: 'VERIFIED',
  );

  static const ter = Provenance(
    source: 'TER Dakar — horaires officiels',
    sourceType: 'OFFICIAL',
    dateVerified: '2026-10-07',
    confidence: 'HIGH',
    status: 'VERIFIED_SOURCE_PENDING_IMPORT',
  );

  static const ddd = Provenance(
    source: 'CETUD — réseau Dem Dikk',
    sourceType: 'OFFICIAL',
    dateVerified: '2026-10-07',
    confidence: 'HIGH',
    status: 'NETWORK_VERIFIED_SCHEDULE_PENDING',
  );

  static const aftu = Provenance(
    source: 'CETUD — réseau AFTU',
    sourceType: 'OFFICIAL',
    dateVerified: '2026-10-07',
    confidence: 'HIGH',
    status: 'NETWORK_VERIFIED_SCHEDULE_PENDING',
  );

  // CETUD publie 4 services BRT, départ toutes les 6 minutes de 06:00 à 21:00.
  // C’est une donnée de service/fréquence, pas une liste de stop_times GTFS.
  static const brtService = Departure(
    serviceId: 'brt-official-service-window',
    label: 'SunuBRT',
    mode: MobilityMode.brt,
    direction: 'Réseau BRT',
    status: ScheduleStatus.estimated,
    remainingMinutes: 6,
    provenance: brt,
  );

  static const List<Departure> initialDepartures = [
    brtService,
    Departure(
      serviceId: 'ter-pending',
      label: 'TER',
      mode: MobilityMode.ter,
      direction: 'Horaires officiels à importer',
      status: ScheduleStatus.unknown,
      provenance: ter,
    ),
    Departure(
      serviceId: 'ddd-pending',
      label: 'Dakar Dem Dikk',
      mode: MobilityMode.ddd,
      direction: 'Horaires GTFS à importer',
      status: ScheduleStatus.unknown,
      provenance: ddd,
    ),
    Departure(
      serviceId: 'aftu-pending',
      label: 'AFTU',
      mode: MobilityMode.aftu,
      direction: 'Horaires GTFS à importer',
      status: ScheduleStatus.unknown,
      provenance: aftu,
    ),
  ];
}
