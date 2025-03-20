import 'package:cloud_firestore/cloud_firestore.dart';

class Reminder {
  final String id;
  final String title;
  final String dosage;
  final String instructions;
  final DateTime time;
  final bool isRecurring;
  final List<bool> recurringDays;
  bool isTaken;

  Reminder({
    required this.id,
    required this.title,
    required this.dosage,
    required this.instructions,
    required this.time,
    this.isRecurring = false,
    this.recurringDays = const [
      false,
      false,
      false,
      false,
      false,
      false,
      false
    ],
    this.isTaken = false,
  });

  factory Reminder.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Reminder(
      id: doc.id,
      title: data['title'],
      dosage: data['dosage'],
      instructions: data['instructions'],
      time: (data['time'] as Timestamp).toDate(),
      isRecurring: data['isRecurring'] ?? false,
      recurringDays: List<bool>.from(data['recurringDays'] ??
          [false, false, false, false, false, false, false]),
      isTaken: data['isTaken'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'dosage': dosage,
      'instructions': instructions,
      'time': time,
      'isRecurring': isRecurring,
      'recurringDays': recurringDays,
      'isTaken': isTaken,
    };
  }
}
