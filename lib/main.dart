import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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
        fontFamily: 'sans',
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

  static const dakar = LatLng(14.7167, -17.4677);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: tab,
          children: const [
            ExplorerPage(),
            SearchPage(),
            AlertsPage(),
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
  const ExplorerPage({super.key});

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
                  child: IconButton(onPressed: () {}, icon: const Icon(Icons.my_location, color: Color(0xFF008F60))),
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
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(.07), blurRadius: 24, offset: const Offset(0, 8))],
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
                    Positioned(
                      top: 14,
                      left: 14,
                      child: _MapPill(icon: Icons.layers_outlined, label: 'Réseau'),
                    ),
                    Positioned(
                      bottom: 14,
                      right: 14,
                      child: FloatingActionButton.small(
                        heroTag: 'gps',
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF008F60),
                        onPressed: () {},
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
          sliver: SliverToBoxAdapter(child: Text('Réseau', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
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
          padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
          sliver: SliverToBoxAdapter(child: _DataNotice()),
        ),
      ],
    );
  }
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
        Text('Planifier un trajet', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
        SizedBox(height: 8),
        Text('Le moteur multimodal sera alimenté uniquement par les données vérifiées du réseau.', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54, height: 1.4)),
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
    decoration: BoxDecoration(color: Colors.white.withOpacity(.94), borderRadius: BorderRadius.circular(14), boxShadow: const [BoxShadow(blurRadius: 12, color: Color(0x22000000))]),
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
      Expanded(child: Text('Données vérifiées uniquement. Les horaires, fréquences et positions temps réel seront affichés seulement lorsqu’une source fiable est disponible.', style: TextStyle(color: Color(0xFF175B46), height: 1.35))),
    ]),
  );
}
