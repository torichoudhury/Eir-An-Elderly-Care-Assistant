import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reminder.dart';

class ReminderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addReminder(Reminder reminder) async {
    await _firestore
        .collection('reminders')
        .doc(reminder.id)
        .set(reminder.toMap());
  }

  Future<void> updateReminder(Reminder reminder) {
    return _firestore
        .collection('reminders')
        .doc(reminder.id)
        .update(reminder.toMap());
  }

  Future<void> deleteReminder(String id) {
    return _firestore.collection('reminders').doc(id).delete();
  }

  Stream<QuerySnapshot<Object?>> getRemindersStream() {
    return _firestore.collection('reminders').snapshots();
  }

  Stream<QuerySnapshot> getTodayReminders(String careReceiverId) {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

    return _firestore
        .collection('careReceivers')
        .doc(careReceiverId)
        .collection('reminders')
        .where('time', isGreaterThanOrEqualTo: startOfDay)
        .where('time', isLessThanOrEqualTo: endOfDay)
        .snapshots();
  }

  Stream<QuerySnapshot> getRemindersForDate(
      String careReceiverId, DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return _firestore
        .collection('careReceivers')
        .doc(careReceiverId)
        .collection('reminders')
        .where('time', isGreaterThanOrEqualTo: startOfDay)
        .where('time', isLessThanOrEqualTo: endOfDay)
        .snapshots();
  }

  Future<void> updateReminderStatus(
      String careReceiverId, String reminderId, bool isTaken) async {
    await _firestore
        .collection('careReceivers')
        .doc(careReceiverId)
        .collection('reminders')
        .doc(reminderId)
        .update({'isTaken': isTaken});
  }

  Future<void> addReminderForCareReceiver(
      String careReceiverId, Reminder reminder) async {
    await _firestore
        .collection('careReceivers')
        .doc(careReceiverId)
        .collection('reminders')
        .doc(reminder.id)
        .set(reminder.toMap());
  }

  // Ensure this method returns a Stream<QuerySnapshot>
  Stream<QuerySnapshot> getRemindersForUser(String userId) {
    return _firestore
        .collection('careReceivers')
        .doc(userId)
        .collection('reminders')
        .snapshots();
  }
}
