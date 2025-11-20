import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class OsmMapPage extends StatefulWidget {
  const OsmMapPage({super.key});
  @override
  State<OsmMapPage> createState() => _OsmMapPageState();
}

class _OsmMapPageState extends State<OsmMapPage> {
  Position? _pos;
  final mapController = MapController();
  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever ||
        perm == LocationPermission.denied)
      return;
    final p = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
    );
    setState(() {
      _pos = p;
    });
    _moveCamera();
  }

  void _moveCamera() {
    if (_pos == null) return;
    mapController.move(LatLng(_pos!.latitude, _pos!.longitude), 16);
  }

  @override
  Widget build(BuildContext context) {
    final center = _pos != null
        ? LatLng(_pos!.latitude, _pos!.longitude)
        : LatLng(-7.4246, 109.2332); // fallback
    return Scaffold(
      appBar: AppBar(title: const Text('OpenStreetMap')),
      body: FlutterMap(
        mapController: mapController,
        options: MapOptions(initialCenter: center, initialZoom: 14),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.event_kampus_locator',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: center,
                width: 40,
                height: 40,
                child: const Icon(
                  Icons.location_pin,
                  color: Colors.red,
                  size: 40,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
