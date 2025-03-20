import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class StepCounter extends StatefulWidget {
  final Function(int) onStepCountUpdated;

  const StepCounter({Key? key, required this.onStepCountUpdated}) : super(key: key);

  @override
  _StepCounterState createState() => _StepCounterState();
}

class _StepCounterState extends State<StepCounter> {
  int _steps = 0;
  StreamSubscription<StepCount>? _stepCountSubscription;
  late Stream<StepCount> _stepCountStream;
  int _lastStepCount = 0;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  void initPlatformState() {
    _stepCountStream = Pedometer.stepCountStream;
    _stepCountSubscription = _stepCountStream.listen(
      onStepCount,
      onError: onStepCountError,
      cancelOnError: true,
    );
  }

  void onStepCount(StepCount event) {
    if (_lastStepCount == 0) {
      _lastStepCount = event.steps;
    }

    final stepsDiff = event.steps - _lastStepCount;
    if (stepsDiff > 0) {
      setState(() {
        _steps += stepsDiff;
        widget.onStepCountUpdated(_steps); // Notify parent widget
      });
      updateStepsToFirebase(_steps);
      _lastStepCount = event.steps;
    }
  }

  void onStepCountError(error) {
    print('Pedometer error: $error');
  }

  Future<void> updateStepsToFirebase(int steps) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final today = DateTime.now();
        final dateStr = '${today.year}-${today.month}-${today.day}';
        
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('healthData')
            .doc(dateStr)
            .set({
          'steps': steps,
          'lastUpdate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Also update the main healthData document for real-time updates
        await FirebaseFirestore.instance
            .collection('healthData')
            .doc(user.uid)
            .set({
          'steps': steps,
          'lastUpdate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print('Error updating steps: $e');
    }
  }

  @override
  void dispose() {
    _stepCountSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(); // This widget doesn't need to render anything
  }
}