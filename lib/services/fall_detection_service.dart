import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:uuid/uuid.dart';

class FallDetectionService {
  static final FallDetectionService _instance =
      FallDetectionService._internal();
  factory FallDetectionService() => _instance;
  FallDetectionService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseReference _realtimeDatabase =
      FirebaseDatabase.instance.ref();
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  bool _isMonitoring = false;

  // Fall detection threshold values
  final double _accelerationThreshold = 20.0; // Adjust based on testing
  final double _impactThreshold = 25.0; // Adjust based on testing

  // Used to prevent multiple detections in quick succession
  DateTime? _lastFallTime;
  final _debounceTime = Duration(seconds: 5);

  bool get isMonitoring => _isMonitoring;

  void startMonitoring() {
    if (_isMonitoring) return;

    _accelerometerSubscription =
        accelerometerEvents.listen((AccelerometerEvent event) {
      _processAccelerometerData(event);
    });

    _isMonitoring = true;
    print("Fall detection monitoring started");
  }

  void stopMonitoring() {
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
    _isMonitoring = false;
    print("Fall detection monitoring stopped");
  }

  void _processAccelerometerData(AccelerometerEvent event) {
    // Calculate total acceleration magnitude
    double acceleration = _calculateMagnitude(event.x, event.y, event.z);

    // Detect sudden acceleration changes that might indicate a fall
    if (acceleration > _accelerationThreshold) {
      _checkForFall(acceleration);
    }
  }

  double _calculateMagnitude(double x, double y, double z) {
    // Calculate the magnitude of acceleration vector
    return sqrt(x * x + y * y + z * z);
  }

  void _checkForFall(double acceleration) {
    // Prevent multiple detections within debounce period
    if (_lastFallTime != null) {
      if (DateTime.now().difference(_lastFallTime!) < _debounceTime) {
        return;
      }
    }

    // Check if acceleration exceeds impact threshold
    if (acceleration > _impactThreshold) {
      _lastFallTime = DateTime.now();
      _handleFallDetected();
    }
  }

  Future<void> _handleFallDetected() async {
    print("Fall detected!");

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
        'type': 'Fall Detection',
        'timestamp': DateTime.now().toIso8601String(),
        'description': 'Possible fall detected. Please check on the person.',
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
    } catch (e) {
      print("Error handling fall detection: $e");
    }
  }

  // Method to simulate a fall for testing purposes
  void simulateFall() {
    _handleFallDetected();
  }
}
