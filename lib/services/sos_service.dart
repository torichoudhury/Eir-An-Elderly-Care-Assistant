import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:uuid/uuid.dart';

class SOSService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseReference _realtimeDatabase = FirebaseDatabase.instance.ref();

  Future<void> sendSOS() async {
    try {
      // Get current location
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Get address from coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      String address = 'Unknown location';
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        address = '${place.street}, ${place.locality}, ${place.country}';
      }

      // Create alert data
      final alertData = {
        'id': const Uuid().v4(),
        'type': 'SOS',
        'timestamp': DateTime.now().toIso8601String(),
        'description': 'SOS alert. Immediate assistance required.',
        'location': {
          'lat': position.latitude,
          'lng': position.longitude,
          'address': address,
        },
        'resolved': false,
        'severity': 'high',
      };

      // Save to Firestore
      await _firestore.collection('alerts').add(alertData);

      // Save to Realtime Database
      await _realtimeDatabase.child('alerts').push().set(alertData);

      print("SOS alert sent successfully!");
    } catch (e) {
      print("Error sending SOS alert: $e");
    }
  }
}
