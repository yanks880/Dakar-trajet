import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'data/verified_network.dart';
import 'domain/mobility_models.dart';
import 'services/gps_service.dart';

void main() => runApp(const DakarBusApp());

class DakarBusApp extends StatelessWidget {
  const DakarBusApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Dakar Bus',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00A86B), brightness: Brightness.light),
      scaffoldBackgroundColor: const Color(0xFFF5F8F7),
    ),
    home: const HomePage(),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int tab = 0;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(child: IndexedStack(index: tab, children: const [ExplorerPage(), SearchPage(), AlertsPage()])),
    bottomNavigationBar: NavigationBar(
      selectedIndex: tab,
      onDestinationSelected: (i) => setState(() => tab = i),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map), label: 'Explorer'),
        NavigationDestination(icon: Icon(Icons.route_outlined), selectedIcon: Icon(Icons.route), label: 'Trajets'),
        NavigationDestination(icon: Icon(Icons.notifications_none), selectedIcon: Icon(Icons.notifications), label: 'Alertes'),
      ],
    ),
  );
}

class ExplorerPage extends StatefulWidget {
  const ExplorerPage({super.key});
  @override State<ExplorerPage> createState() => _ExplorerPageState();
}

class _ExplorerPageState extends State<ExplorerPage> {
  String gpsLabel = 'Ma position';

  Future<void> locate() async {
    final position = await GpsService().currentPosition();
    if (!mounted) return;
    setState(() {
      gpsLabel = position == null
          ? 'Position indisponible'
          : 'GPS · ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
    });
  }

  @override
  Widget build(BuildContext context) => CustomScrollView(
    slivers: [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
        sliver: SliverToBoxAdapter(
          child: Row(children: [
            const Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('DAKAR BUS', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900, letterSpacing: -0.8)),
                SizedBox(height: 3),
                Text('Votre mobilité, simplement.', style: TextStyle(color: Colors.black54)),
              ],
            )),
            Container(
              decoration: BoxDecoration(color: const Color(0xFFE3F6EE), borderRadius: BorderRadius.circular(16)),
              child: IconButton(tooltip: 'Utiliser le GPS', onPressed: locate, icon: const Icon(Icons.my_location, color: Color(0xFF008F60))),
            ),
          ]),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        sliver: SliverToBoxAdapter(child: Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: [BoxShadow(color: Colors.black.withOpacity(.07), blurRadius: 24, offset: const Offset(0, 8))]),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Row(children: [
              Icon(Icons.search, color: Color(0xFF008F60)), SizedBox(width: 12),
              Expanded(child: Text('Où voulez-vous aller ?', style: TextStyle(fontSize: 16, color: Colors.black54))),
              Icon(Icons.tune, size: 20, color: Colors.black45),
            ]),
          ),
        )),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
        sliver: SliverToBoxAdapter(child: Text(gpsLabel, style: const TextStyle(fontSize: 12, color: Colors.black54))),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
        sliver: SliverToBoxAdapter(child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: SizedBox(
            height: 300,
            child: Stack(children: [
              FlutterMap(
                options: const MapOptions(initialCenter: LatLng(14.7167, -17.4677), initialZoom: 12.2),
                children: [
                  TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.dakarbus.app'),
                  const RichAttributionWidget(attributions: [TextSourceAttribution('OpenStreetMap contributors')]),
                ],
              ),
              const Positioned(top: 14, left: 14, child: _MapPill(icon: Icons.layers_outlined, label: 'Réseau')),
              Positioned(
                bottom: 14, right: 14,
                child: FloatingActionButton.small(
                  heroTag: 'gps', backgroundColor: Colors.white, foregroundColor: const Color(0xFF008F60),
                  onPressed: locate, child: const Icon(Icons.my_location),
                ),
              ),
            ]),
          ),
        )),
      ),
      const SliverPadding(
        padding: EdgeInsets.fromLTRB(20, 8, 20, 6),
        sliver: SliverToBoxAdapter(child: Text('Horaires & passages', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
        sliver: SliverList.builder(
          itemCount: VerifiedNetwork.initialDepartures.length,
          itemBuilder: (context, index) => _ScheduleCard(departure: VerifiedNetwork.initialDepartures[index]),
        ),
      ),
      const SliverPadding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
        sliver: SliverToBoxAdapter(child: _DataNotice()),
      ),
    ],
  );
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  @override State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final from = TextEditingController();
  final to = TextEditingController();
  bool searching = false;

  void search() {
    FocusScope.of(context).unfocus();
    setState(() => searching = true);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => searching = false);
    });
  }

  @override
  void dispose() { from.dispose(); to.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
    children: [
      const Text('Planifier un trajet', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
      const SizedBox(height: 6),
      const Text('TER · BRT · DDD · AFTU · marche · correspondances', style: TextStyle(color: Colors.black54)),
      const SizedBox(height: 22),
      _SearchField(controller: from, label: 'Départ', icon: Icons.trip_origin),
      const SizedBox(height: 10),
      _SearchField(controller: to, label: 'Destination', icon: Icons.location_on_outlined),
      const SizedBox(height: 14),
      FilledButton.icon(
        onPressed: searching ? null : search,
        icon: const Icon(Icons.route),
        label: Text(searching ? 'Recherche…' : 'Rechercher'),
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
      ),
      const SizedBox(height: 18),
      const _EngineNotice(),
    ],
  );
}

class AlertsPage extends StatelessWidget {
  const AlertsPage({super.key});
  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(28),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.verified_outlined, size: 58, color: Color(0xFF00A86B)),
        SizedBox(height: 16),
        Text('Alertes fiables', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
        SizedBox(height: 8),
        Text('Aucune alerte LIVE ne sera affichée sans une source temps réel vérifiée.', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54, height: 1.4)),
      ]),
    ),
  );
}

class _ScheduleCard extends StatelessWidget {
  final Departure departure;
  const _ScheduleCard({required this.departure});
  @override
  Widget build(BuildContext context) {
    final available = departure.status != ScheduleStatus.unknown;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE1ECE7))),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: available ? const Color(0xFFE5F7EF) : const Color(0xFFF0F2F1), borderRadius: BorderRadius.circular(14)),
          child: Icon(departure.mode == MobilityMode.ter ? Icons.train_outlined : Icons.directions_bus_outlined, color: available ? const Color(0xFF008F60) : Colors.black45),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(departure.label, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 3),
          Text(departure.direction ?? '', style: const TextStyle(color: Colors.black54, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            departure.mode == MobilityMode.brt ? '06:00–21:00 · départ toutes les 6 mn' : departure.waitLabel,
            style: TextStyle(color: available ? const Color(0xFF008F60) : Colors.black45, fontWeight: FontWeight.w800, fontSize: 13),
          ),
        ])),
      ]),
    );
  }
}

class _EngineNotice extends StatelessWidget {
  const _EngineNotice();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: const Color(0xFFEAF7F1), borderRadius: BorderRadius.circular(18)),
    child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(Icons.route_outlined, color: Color(0xFF008F60)), SizedBox(width: 12),
      Expanded(child: Text('Le moteur affichera les itinéraires et heures exactes dès que le GTFS officiel sera chargé. Sans donnée source, Dakar Bus ne fabrique aucun trajet.', style: TextStyle(color: Color(0xFF175B46), height: 1.35))),
    ]),
  );
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  const _SearchField({required this.controller, required this.label, required this.icon});
  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    textInputAction: TextInputAction.next,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF008F60)),
      filled: true, fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
    ),
  );
}

class _MapPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MapPill({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(color: Colors.white.withOpacity(.94), borderRadius: BorderRadius.circular(14), boxShadow: const [BoxShadow(blurRadius: 12, color: Color(0x22000000))]),
    child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9), child: Row(children: [Icon(icon, size: 18, color: const Color(0xFF008F60)), const SizedBox(width: 7), Text(label, style: const TextStyle(fontWeight: FontWeight.w700))])),
  );
}

class _DataNotice extends StatelessWidget {
  const _DataNotice();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: const Color(0xFFEAF7F1), borderRadius: BorderRadius.circular(18)),
    child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(Icons.shield_outlined, color: Color(0xFF008F60)), SizedBox(width: 12),
      Expanded(child: Text('Données vérifiées uniquement. Les horaires exacts, fréquences et positions temps réel sont affichés seulement lorsqu’une source fiable est disponible.', style: TextStyle(color: Color(0xFF175B46), height: 1.35))),
    ]),
  );
}
