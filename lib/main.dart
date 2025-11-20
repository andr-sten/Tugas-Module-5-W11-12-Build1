import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as gc; // opsional
import 'geolocator.dart';
import 'flutter_map.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Event Kampus Locator',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
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
  Position? _pos;
  String? _address;
  StreamSubscription<Position>? _sub;
  bool _tracking = false;
  String _status = 'Belum ada data lokasi';

  final events = [
    {'title': 'Seminar AI', 'lat': -7.4246, 'lng': 109.2332},
    {'title': 'Job Fair', 'lat': -7.4261, 'lng': 109.2315},
    {'title': 'Expo UKM', 'lat': -7.4229, 'lng': 109.2350},
  ];

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<bool> _ensureServiceAndPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(
        () => _status =
            'Location service OFF. Buka pengaturan untuk mengaktifkan.',
      );
      await Geolocator.openLocationSettings();
      return false;
    }
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever ||
        perm == LocationPermission.denied) {
      setState(() => _status = 'Izin lokasi ditolak. Aktifkan via Settings.');
      return false;
    }
    return true;
  }

  Future<void> _getCurrent() async {
    if (!await _ensureServiceAndPermission()) return;
    try {
      final p = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
      setState(() {
        _pos = p;
        _status = 'Lokasi diambil sekali.';
      });
      await _reverseGeocode(p);
    } catch (e) {
      setState(() => _status = 'Gagal mengambil lokasi: $e');
    }
  }

  Future<void> _reverseGeocode(Position p) async {
    try {
      final placemarks = await gc.placemarkFromCoordinates(
        p.latitude,
        p.longitude,
      );
      if (placemarks.isNotEmpty) {
        final m = placemarks.first;
        setState(() {
          _address = '${m.street}, ${m.locality},${m.administrativeArea}';
        });
      }
    } catch (_) {}
  }

  Future<void> _toggleTracking() async {
    if (_tracking) {
      await _sub?.cancel();
      setState(() {
        _tracking = false;
        _status = 'Tracking dihentikan.';
      });
      return;
    }
    if (!await _ensureServiceAndPermission()) return;
    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );
    _sub = Geolocator.getPositionStream(locationSettings: settings).listen(
      (p) {
        setState(() {
          _pos = p;
          _tracking = true;
          _status = 'Tracking aktif.';
        });
        _reverseGeocode(p);
      },
      onError: (e) {
        setState(() => _status = 'Error stream: $e');
      },
    );
  }

  double distanceM(Position me, Map e) => Geolocator.distanceBetween(
    me.latitude,
    me.longitude,
    e['lat'] as double,
    e['lng'] as double,
  );
  Widget buildEventList(Position me) {
    final items = events.map((e) {
      final d = distanceM(me, e);
      return ListTile(
        leading: const Icon(Icons.event),
        title: Text(e['title'] as String),
        subtitle: Text('${d.toStringAsFixed(0)} m dari lokasi Anda'),
      );
    }).toList();
    return ListView(children: items);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Event Kampus Locator')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: $_status'),
            const SizedBox(height: 8),
            if (_pos != null) ...[
              Text('Lat: ${_pos!.latitude.toStringAsFixed(6)}'),
              Text('Lng: ${_pos!.longitude.toStringAsFixed(6)}'),
              Text('Accuracy: ${_pos!.accuracy.toStringAsFixed(1)} m'),
              Text('Speed: ${(_pos!.speed * 3.6).toStringAsFixed(1)} km/h'),
              Text('Heading: ${_pos!.heading.toStringAsFixed(0)}°'),
              Text('Time: ${_pos!.timestamp}'),
              if (_address != null) Text('Alamat: $_address'),
            ] else
              const Text('Belum ada data lokasi.'),
            //--- POINT 6: Widget Event List ---
            const Spacer(),
            if (_pos != null)
              Expanded(child: buildEventList(_pos!))
            else
              const Spacer(),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton.icon(
                  onPressed: _getCurrent,
                  icon: const Icon(Icons.my_location),
                  label: const Text('Get Current'),
                ),
                FilledButton.icon(
                  onPressed: _toggleTracking,
                  icon: Icon(_tracking ? Icons.stop : Icons.play_arrow),
                  label: Text(_tracking ? 'Stop Tracking' : 'Start Tracking'),
                ),
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MapPage()),
                  ),
                  icon: const Icon(Icons.map),
                  label: const Text('Google Maps'),
                ),
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OsmMapPage()),
                  ),
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('OSM'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
