import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'services/gps_service.dart';

void main() => runApp(const DakarBusApp());

class DakarBusApp extends StatelessWidget {
  const DakarBusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dakar Bus',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00A86B),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F8F7),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int tab = 0;
  final gps = GpsService();

  Future<void> locate() async {
    final position = await gps.currentPosition();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(position == null
            ? 'Position indisponible. Vérifiez l’autorisation GPS.'
            : 'Position GPS obtenue.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: tab,
          children: [
            ExplorerPage(onLocate: locate),
            const SearchPage(),
            const AlertsPage(),
          ],
        ),
      ),
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
}

class ExplorerPage extends StatelessWidget {
  final VoidCallback onLocate;
  const ExplorerPage({super.key, required this.onLocate});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('DAKAR BUS', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900, letterSpacing: -0.8)),
                      SizedBox(height: 3),
                      Text('Votre mobilité, simplement.', style: TextStyle(color: Colors.black54)),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(color: const Color(0xFFE3F6EE), borderRadius: BorderRadius.circular(16)),
                  child: IconButton(onPressed: onLocate, icon: const Icon(Icons.my_location, color: Color(0xFF008F60))),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          sliver: SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .07), blurRadius: 24, offset: const Offset(0, 8))],
              ),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.search, color: Color(0xFF008F60)),
                    SizedBox(width: 12),
                    Expanded(child: Text('Où voulez-vous aller ?', style: TextStyle(fontSize: 16, color: Colors.black54))),
                    Icon(Icons.tune, size: 20, color: Colors.black45),
                  ],
                ),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          sliver: SliverToBoxAdapter(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: SizedBox(
                height: 330,
                child: Stack(
                  children: [
                    FlutterMap(
                      options: const MapOptions(initialCenter: LatLng(14.7167, -17.4677), initialZoom: 12.2),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.dakarbus.app',
                        ),
                        const RichAttributionWidget(
                          attributions: [TextSourceAttribution('OpenStreetMap contributors')],
                        ),
                      ],
                    ),
                    Positioned(top: 14, left: 14, child: _MapPill(icon: Icons.layers_outlined, label: 'Réseau')),
                    Positioned(
                      bottom: 14,
                      right: 14,
                      child: FloatingActionButton.small(
                        heroTag: 'gps',
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF008F60),
                        onPressed: onLocate,
                        child: const Icon(Icons.my_location),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 6),
          sliver: SliverToBoxAdapter(child: Text('Mobilités', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
          sliver: SliverToBoxAdapter(
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: const [
                _ModeChip('TER', Icons.train_outlined),
                _ModeChip('BRT', Icons.directions_bus_outlined),
                _ModeChip('DDD', Icons.directions_bus_filled_outlined),
                _ModeChip('AFTU', Icons.airport_shuttle_outlined),
              ],
            ),
          ),
        ),
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
          sliver: SliverToBoxAdapter(child: _SchedulePanel()),
        ),
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 24),
          sliver: SliverToBoxAdapter(child: _DataNotice()),
        ),
      ],
    );
  }
}

class _SchedulePanel extends StatelessWidget {
  const _SchedulePanel();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .05), blurRadius: 18, offset: const Offset(0, 7))],
    ),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(Icons.schedule_outlined, color: Color(0xFF008F60)),
          SizedBox(width: 10),
          Text('Horaires des trajets', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        ]),
        SizedBox(height: 12),
        Text('Aucun horaire vérifié à afficher pour le moment.', style: TextStyle(fontWeight: FontWeight.w700)),
        SizedBox(height: 5),
        Text('Dès qu’un GTFS officiel/opérateur sera importé, cette zone affichera la ligne, la direction et les prochains départs.', style: TextStyle(color: Colors.black54, height: 1.35)),
      ],
    ),
  );
}

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(28),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.route, size: 58, color: Color(0xFF00A86B)),
        SizedBox(height: 16),
        Text('Itinéraires multimodaux', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800), textAlign: TextAlign.center),
        SizedBox(height: 8),
        Text('Recherche WALK + TER + BRT + DDD + AFTU + correspondances. Aucun itinéraire n’est calculé tant que les données vérifiées ne sont pas disponibles.', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54, height: 1.4)),
      ]),
    ),
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

class _MapPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MapPill({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: .94), borderRadius: BorderRadius.circular(14), boxShadow: const [BoxShadow(blurRadius: 12, color: Color(0x22000000))]),
    child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9), child: Row(children: [Icon(icon, size: 18, color: const Color(0xFF008F60)), const SizedBox(width: 7), Text(label, style: const TextStyle(fontWeight: FontWeight.w700))])),
  );
}

class _ModeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _ModeChip(this.label, this.icon);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFDDE9E4))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 19, color: const Color(0xFF008F60)), const SizedBox(width: 7), Text(label, style: const TextStyle(fontWeight: FontWeight.w800))]),
  );
}

class _DataNotice extends StatelessWidget {
  const _DataNotice();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: const Color(0xFFEAF7F1), borderRadius: BorderRadius.circular(18)),
    child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(Icons.shield_outlined, color: Color(0xFF008F60)),
      SizedBox(width: 12),
      Expanded(child: Text('Données vérifiées uniquement. Les horaires, fréquences et positions temps réel ne seront affichés que lorsqu’une source fiable est disponible.', style: TextStyle(color: Color(0xFF175B46), height: 1.35))),
    ]),
  );
}
