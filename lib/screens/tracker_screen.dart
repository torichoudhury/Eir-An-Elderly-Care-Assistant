import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class TrackerScreen extends StatefulWidget {
  final String userId;

  const TrackerScreen({super.key, required this.userId});

  @override
  _TrackerScreenState createState() => _TrackerScreenState();
}

class _TrackerScreenState extends State<TrackerScreen> {
  late DatabaseReference _locationRef;
  LatLng _currentLocation = LatLng(0, 0);
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();

    _locationRef = FirebaseDatabase.instance
        .ref()
        .child('users')
        .child(widget.userId)
        .child('location');

    _locationRef.onValue.listen((event) {
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>?;

        if (data != null && data.containsKey('latitude') && data.containsKey('longitude')) {
          final latitude = (data['latitude'] as num).toDouble();
          final longitude = (data['longitude'] as num).toDouble();

          setState(() {
            _currentLocation = LatLng(latitude, longitude);
            _mapController.move(_currentLocation, _mapController.camera.zoom);
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tracker'),
        backgroundColor: Colors.teal,
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _currentLocation,
          initialZoom: 15.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: ['a', 'b', 'c'],
          ),
          MarkerLayer(
            markers: [
              Marker(
                width: 80.0,
                height: 80.0,
                point: _currentLocation,
                child: const Icon(
                  Icons.location_on,
                  color: Colors.red,
                  size: 40.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
