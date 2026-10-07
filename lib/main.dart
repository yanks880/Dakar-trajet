import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'services/gps_service.dart';
import 'data/network_repository.dart';
import 'services/api_client.dart';

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
  final repository = NetworkRepository(api: ApiClient(baseUrl: const String.fromEnvironment('DAKAR_BUS_API_URL')));
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
            const StreetPage(),
            const SettingsPage(),
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
          NavigationDestination(icon: Icon(Icons.streetview_outlined), selectedIcon: Icon(Icons.streetview), label: 'Direct rue'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Paramètres'),
        ],
      ),
    );
  }
}

class ExplorerPage extends StatefulWidget {
  final VoidCallback onLocate;
  const ExplorerPage({super.key, required this.onLocate});
  @override
  State<ExplorerPage> createState() => _ExplorerPageState();
}

class _ExplorerPageState extends State<ExplorerPage> {
  final repository = NetworkRepository(api: ApiClient(baseUrl: const String.fromEnvironment('DAKAR_BUS_API_URL')));
  List<NetworkNearbyStop> nearby = const [];
  List<NetworkGeometry> geometries = const [];
  bool loadingNearby = false;

  Future<void> loadNearby() async {
    setState(() => loadingNearby = true);
    try {
      final position = await GpsService().currentPosition();
      if (position != null) {
        final stops = await repository.nearby(position.latitude, position.longitude, walkMinutes: 15);
        if (mounted) setState(() => nearby = stops);
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => loadingNearby = false);
    }
  }

  @override
  void initState() {
    super.initState();
    repository.geometries().then((value) {
      if (mounted) setState(() => geometries = value);
    }).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(slivers: [
      SliverPadding(padding: const EdgeInsets.fromLTRB(20, 18, 20, 8), sliver: SliverToBoxAdapter(
        child: Row(children: [
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('DAKAR BUS', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900, letterSpacing: -0.8)),
            SizedBox(height: 3), Text('Votre mobilité, simplement.', style: TextStyle(color: Colors.black54)),
          ])),
          Container(decoration: BoxDecoration(color: const Color(0xFFE3F6EE), borderRadius: BorderRadius.circular(16)),
            child: IconButton(onPressed: widget.onLocate, icon: const Icon(Icons.my_location, color: Color(0xFF008F60)))),
        ]),
      )),
      SliverPadding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 8), sliver: SliverToBoxAdapter(
        child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: const [
          _ModeChip('TER', Icons.train_outlined), SizedBox(width: 8),
          _ModeChip('BRT', Icons.directions_bus_outlined), SizedBox(width: 8),
          _ModeChip('DDD', Icons.directions_bus_filled_outlined), SizedBox(width: 8),
          _ModeChip('AFTU', Icons.airport_shuttle_outlined),
        ])),
      )),
      SliverPadding(padding: const EdgeInsets.fromLTRB(20, 4, 20, 10), sliver: SliverToBoxAdapter(
        child: Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .07), blurRadius: 24, offset: const Offset(0, 8))]),
          child: const Padding(padding: EdgeInsets.all(16), child: Row(children: [
            Icon(Icons.search, color: Color(0xFF008F60)), SizedBox(width: 12),
            Expanded(child: Text('Où voulez-vous aller ?', style: TextStyle(fontSize: 16, color: Colors.black54))),
            Icon(Icons.tune, size: 20, color: Colors.black45),
          ])),
        ),
      )),
      SliverPadding(padding: const EdgeInsets.fromLTRB(20, 4, 20, 12), sliver: SliverToBoxAdapter(
        child: ClipRRect(borderRadius: BorderRadius.circular(28), child: SizedBox(height: 410, child: Stack(children: [
          FlutterMap(options: const MapOptions(initialCenter: LatLng(14.7167, -17.4677), initialZoom: 11.7), children: [
            TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.dakarbus.app'),
            if (geometries.isNotEmpty) PolylineLayer(polylines: geometries.map((g) => Polyline(points: g.points.map((p) => LatLng(p.lat, p.lon)).toList(), strokeWidth: 4)).toList()),
            if (nearby.isNotEmpty) MarkerLayer(markers: nearby.map((s) => Marker(point: LatLng(s.lat, s.lon), width: 42, height: 42, child: const Icon(Icons.location_on, size: 34, color: Color(0xFF008F60)))).toList()),
            const RichAttributionWidget(attributions: [TextSourceAttribution('OpenStreetMap contributors')]),
          ]),
          const Positioned(top: 14, left: 14, child: _MapPill(icon: Icons.layers_outlined, label: 'Réseau Dakar')),
          Positioned(bottom: 14, left: 14, child: FloatingActionButton.small(heroTag: 'gps-explorer', backgroundColor: Colors.white, foregroundColor: const Color(0xFF008F60), onPressed: loadNearby, child: const Icon(Icons.my_location))),
          Positioned(bottom: 14, right: 14, child: FloatingActionButton.small(heroTag: 'ai-explorer', backgroundColor: const Color(0xFF008F60), foregroundColor: Colors.white, onPressed: () => showModalBottomSheet<void>(context: context, showDragHandle: true, builder: (_) => const _AiSheet()), child: const Icon(Icons.auto_awesome))),
        ]))),
      )),
      SliverPadding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 8), sliver: SliverToBoxAdapter(
        child: Row(children: [
          const Expanded(child: Text('Mobilités autour de vous', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
          TextButton(onPressed: loadNearby, child: const Text('15 min')),
        ]),
      )),
      if (loadingNearby) const SliverPadding(padding: EdgeInsets.symmetric(horizontal: 20), sliver: SliverToBoxAdapter(child: LinearProgressIndicator())),
      if (!loadingNearby && nearby.isEmpty) const SliverPadding(padding: EdgeInsets.fromLTRB(20, 4, 20, 12), sliver: SliverToBoxAdapter(
        child: _InfoCard(icon: Icons.location_searching, title: 'Mobilités proches', message: 'Activez le GPS pour rechercher les arrêts dans un rayon correspondant à 15 minutes de marche.'),
      )),
      if (nearby.isNotEmpty) SliverPadding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 20), sliver: SliverList.separated(
        itemCount: nearby.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => Card(child: ListTile(
          leading: const Icon(Icons.place_outlined, color: Color(0xFF008F60)),
          title: Text(nearby[i].name, style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text('À environ \${nearby[i].distanceM.round()} m · horaires vérifiés après sélection'),
          trailing: const Icon(Icons.chevron_right),
        )),
      )),
      const SliverPadding(padding: EdgeInsets.fromLTRB(20, 0, 20, 24), sliver: SliverToBoxAdapter(child: _DataNotice())),
    ]);
  }
}

class _AiSheet extends StatelessWidget {
  const _AiSheet();
  @override
  Widget build(BuildContext context) => const SafeArea(child: Padding(
    padding: EdgeInsets.fromLTRB(20, 8, 20, 28),
    child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Assistant mobilité', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
      SizedBox(height: 8),
      Text('L’assistant doit répondre à partir des données CETUD/GTFS réellement chargées. Il ne doit jamais inventer une ligne, un horaire, une alerte ou une position.', style: TextStyle(color: Colors.black54, height: 1.4)),
      SizedBox(height: 16), TextField(decoration: InputDecoration(hintText: 'Posez votre question…', border: OutlineInputBorder())),
    ]),
  ));
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

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final controller = TextEditingController();
  final repository = NetworkRepository(
    api: ApiClient(baseUrl: const String.fromEnvironment('DAKAR_BUS_API_URL')),
  );

  bool loading = false;
  String? error;
  List<NetworkSearchResult> results = const [];

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> search() async {
    final query = controller.text.trim();
    if (query.isEmpty) return;
    setState(() {
      loading = true;
      error = null;
      results = const [];
    });
    try {
      final found = await repository.search(query);
      if (!mounted) return;
      setState(() => results = found);
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> openStop(NetworkSearchResult result) async {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _StopSheet(repository: repository, result: result),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Trajets', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                SizedBox(height: 5),
                Text('Rechercher un arrêt vérifié dans le réseau chargé.', style: TextStyle(color: Colors.black54)),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          sliver: SliverToBoxAdapter(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => search(),
              decoration: InputDecoration(
                hintText: 'Nom d’arrêt ou de gare',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF008F60)),
                suffixIcon: IconButton(
                  onPressed: loading ? null : search,
                  icon: const Icon(Icons.arrow_forward_rounded),
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
        if (loading)
          const SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            sliver: SliverToBoxAdapter(child: LinearProgressIndicator()),
          ),
        if (error != null)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            sliver: SliverToBoxAdapter(
              child: _InfoCard(
                icon: Icons.cloud_off_outlined,
                title: 'Données indisponibles',
                message: 'L’API canonique n’est pas configurée ou ne répond pas. Aucun résultat n’est inventé.',
              ),
            ),
          ),
        if (!loading && error == null && controller.text.trim().isNotEmpty && results.isEmpty)
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 8),
            sliver: SliverToBoxAdapter(
              child: _InfoCard(
                icon: Icons.search_off_outlined,
                title: 'Aucun arrêt vérifié',
                message: 'Aucun arrêt correspondant n’a été retourné par le réseau canonique.',
              ),
            ),
          ),
        if (results.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            sliver: SliverList.separated(
              itemCount: results.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, index) {
                final item = results[index];
                return Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => openStop(item),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: Color(0xFFE3F6EE),
                            foregroundColor: Color(0xFF008F60),
                            child: Icon(Icons.place_outlined),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                                const SizedBox(height: 4),
                                Text(item.id, style: const TextStyle(color: Colors.black45, fontSize: 12)),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Colors.black38),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _StopSheet extends StatefulWidget {
  final NetworkRepository repository;
  final NetworkSearchResult result;
  const _StopSheet({required this.repository, required this.result});

  @override
  State<_StopSheet> createState() => _StopSheetState();
}

class _StopSheetState extends State<_StopSheet> {
  NetworkStopDetail? detail;
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final value = await widget.repository.stopDetail(widget.result.id);
      if (mounted) setState(() => detail = value);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final departures = detail?.departures ?? const <NetworkDeparture>[];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.result.name, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900)),
            const SizedBox(height: 5),
            Text(widget.result.id, style: const TextStyle(color: Colors.black45, fontSize: 12)),
            const SizedBox(height: 18),
            if (detail == null && error == null)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
            else if (error != null)
              _InfoCard(
                icon: Icons.cloud_off_outlined,
                title: 'Horaires indisponibles',
                message: 'La source canonique n’a pas fourni de départs. Aucun horaire n’est inventé.',
              )
            else if (departures.isEmpty)
              const _InfoCard(
                icon: Icons.schedule_outlined,
                title: 'Aucun départ vérifié',
                message: 'Aucun départ programmé n’a été retourné pour cet arrêt à cet instant.',
              )
            else
              ...departures.map((departure) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.schedule_outlined, color: Color(0xFF008F60)),
                    title: Text(
                      departure.routeShortName ?? departure.routeName ?? 'Ligne vérifiée',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(departure.headsign?.trim().isNotEmpty == true
                        ? departure.headsign!
                        : 'Direction non renseignée par le GTFS'),
                    trailing: Text(
                      departure.departureTime,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  const _InfoCard({required this.icon, required this.title, required this.message});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .05), blurRadius: 18, offset: const Offset(0, 7))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF008F60)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 5),
                  Text(message, style: const TextStyle(color: Colors.black54, height: 1.35)),
                ],
              ),
            ),
          ],
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


class StreetPage extends StatelessWidget {
  const StreetPage({super.key});
  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(28),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.streetview, size: 58, color: Color(0xFF00A86B)),
        SizedBox(height: 16),
        Text('Direct rue', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
        SizedBox(height: 8),
        Text('Vue rue et contexte géographique. Aucun flux vidéo ou position en direct ne sera simulé sans source disponible.', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54, height: 1.4)),
      ]),
    ),
  );
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: const [
      Text('Paramètres', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
      SizedBox(height: 16),
      Card(child: ListTile(leading: Icon(Icons.location_on_outlined), title: Text('Localisation'), subtitle: Text('Autorisation GPS utilisée pour les mobilités proches.'))),
      Card(child: ListTile(leading: Icon(Icons.verified_outlined), title: Text('Données vérifiées'), subtitle: Text('Aucun horaire, tracé ou statut temps réel n’est inventé.'))),
    ],
  );
}
