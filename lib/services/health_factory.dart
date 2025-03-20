import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:sensors_plus/sensors_plus.dart';

class HealthFactory {
  static final HealthFactory _instance = HealthFactory._internal();
  factory HealthFactory() => _instance;
  HealthFactory._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Stream<StepCount> _stepCountStream;
  late Stream<AccelerometerEvent> _accelerometerStream;
  int _steps = 0;
  int _sleepMinutes = 0;
  DateTime? _lastMovementTime;

  Future<void> initializeHealthData(String userId) async {
    try {
      DocumentSnapshot snapshot =
          await _firestore.collection('healthData').doc(userId).get();

      if (!snapshot.exists) {
        await _initializeBasicHealthData(userId);
      }
    } catch (e) {
      print("Error initializing health data: $e");
      await _initializeBasicHealthData(userId);
    }
  }

  Future<void> _initializeBasicHealthData(String userId) async {
    try {
      await _firestore.collection('healthData').doc(userId).set({
        'heartRate': 0,
        'steps': 0,
        'sleep': 0,
        'mood': 'Neutral',
        'lastUpdated': DateTime.now(),
      });
    } catch (e) {
      print("Error initializing basic health data: $e");
    }
  }

  Future<Map<String, dynamic>> fetchHealthData(String userId) async {
    try {
      await initializeHealthData(userId);
      DocumentSnapshot snapshot =
          await _firestore.collection('healthData').doc(userId).get();

      if (snapshot.exists) {
        return snapshot.data() as Map<String, dynamic>;
      }
      return getDefaultHealthData();
    } catch (e) {
      print("Error fetching health data: $e");
      return getDefaultHealthData();
    }
  }

  Map<String, dynamic> getDefaultHealthData() {
    return {
      'heartRate': 0,
      'steps': 0,
      'sleep': 0,
      'mood': 'Unknown',
      'lastUpdated': DateTime.now()
    };
  }

  Future<List<HealthTip>> fetchHealthTips() async {
    await Future.delayed(Duration(seconds: 1)); // Simulating delay

    return [
      HealthTip(
        title: "Walk More",
        description: "Try to increase your daily steps to 8,000",
        icon: Icons.directions_walk,
      ),
      HealthTip(
        title: "Stay Hydrated",
        description: "Drink at least 8 glasses of water a day",
        icon: Icons.local_drink,
      ),
    ];
  }

  Future<void> updateHealthData(
      String userId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('healthData').doc(userId).set(
        {
          ...data,
          'lastUpdated': DateTime.now(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      print("Error updating health data: $e");
    }
  }

  void startStepTracking(String userId) {
    _stepCountStream = Pedometer.stepCountStream;
    _stepCountStream.listen((StepCount event) {
      _steps = event.steps;
      updateHealthData(userId, {'steps': _steps});
    }).onError((error) {
      print("Error tracking steps: $error");
    });
  }

  void startActivityTracking(String userId) {
    _accelerometerStream = accelerometerEvents;
    _accelerometerStream.listen((AccelerometerEvent event) {
      // Process accelerometer data to determine activity
      // For simplicity, we'll just log the data here
      // print('Accelerometer: x=${event.x}, y=${event.y}, z=${event.z}');
      // You can implement more complex activity tracking logic here
    }).onError((error) {
      print("Error tracking activity: $error");
    });
  }

  void startSleepTracking(String userId) {
    _accelerometerStream = accelerometerEvents;
    _accelerometerStream.listen((AccelerometerEvent event) {
      final currentTime = DateTime.now();
      final movementDetected =
          event.x.abs() > 0.1 || event.y.abs() > 0.1 || event.z.abs() > 0.1;

      if (movementDetected) {
        _lastMovementTime = currentTime;
      } else if (_lastMovementTime != null) {
        final minutesSinceLastMovement =
            currentTime.difference(_lastMovementTime!).inMinutes;
        if (minutesSinceLastMovement > 5) {
          _sleepMinutes += minutesSinceLastMovement;
          _lastMovementTime = currentTime;
          updateHealthData(userId, {'sleep': _sleepMinutes ~/ 60});
        }
      }
    }).onError((error) {
      print("Error tracking sleep: $error");
    });
  }

  Future<void> fetchAndUpdateSleepData(String userId) async {
    // Simulate fetching sleep data
    await Future.delayed(Duration(seconds: 1));
    int sleepHours =
        _sleepMinutes ~/ 60; // Use the dynamically tracked sleep data

    await updateHealthData(userId, {'sleep': sleepHours});
  }
}

class HealthTip {
  final String title;
  final String description;
  final IconData icon;

  HealthTip({
    required this.title,
    required this.description,
    required this.icon,
  });
}
