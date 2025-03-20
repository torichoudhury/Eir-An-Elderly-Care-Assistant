import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../widgets/bottom_navigation.dart';
import '../models/reminder.dart';
import '../services/reminder_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReminderScreen extends StatefulWidget {
  @override
  _ReminderScreenState createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen>
    with SingleTickerProviderStateMixin {
  final ReminderService _reminderService = ReminderService();
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  String? _selectedCareReceiverId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchReceiverId();
  }

  Future<void> fetchReceiverId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final caregiverDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (caregiverDoc.exists) {
        setState(() {
          _selectedCareReceiverId = caregiverDoc['receiverId'];
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddReminderDialog() {
    final TextEditingController _titleController = TextEditingController();
    final TextEditingController _dosageController = TextEditingController();
    final TextEditingController _instructionsController =
        TextEditingController();

    TimeOfDay _selectedTime = TimeOfDay.now();
    bool _isRecurring = false;
    List<bool> _selectedDays = List.generate(7, (_) => false);
    String _selectedType = 'Medication';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Add Reminder'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedType,
                      items: ['Medication', 'Food', 'Water']
                          .map((type) => DropdownMenuItem<String>(
                                value: type,
                                child: Text(type),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedType = value!;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Reminder Type',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: _selectedType == 'Medication'
                            ? 'Medication Name'
                            : _selectedType == 'Food'
                                ? 'Food Item'
                                : 'Water Intake',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (_selectedType == 'Medication') ...[
                      SizedBox(height: 16),
                      TextField(
                        controller: _dosageController,
                        decoration: InputDecoration(
                          labelText: 'Dosage (e.g., 1 pill)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                    SizedBox(height: 16),
                    TextField(
                      controller: _instructionsController,
                      decoration: InputDecoration(
                        labelText: 'Instructions (e.g., take with food)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Text('Time: '),
                        SizedBox(width: 8),
                        TextButton(
                          child: Text(
                            '${_selectedTime.format(context)}',
                            style: TextStyle(fontSize: 16),
                          ),
                          onPressed: () async {
                            final TimeOfDay? picked = await showTimePicker(
                              context: context,
                              initialTime: _selectedTime,
                            );
                            if (picked != null) {
                              setState(() {
                                _selectedTime = picked;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Text('Recurring: '),
                        Switch(
                          value: _isRecurring,
                          onChanged: (value) {
                            setState(() {
                              _isRecurring = value;
                            });
                          },
                        ),
                      ],
                    ),
                    if (_isRecurring) ...[
                      SizedBox(height: 8),
                      Text('Select days:'),
                      SizedBox(height: 8),
                      Wrap(
                        spacing: 5,
                        children: [
                          for (int i = 0; i < 7; i++)
                            FilterChip(
                              label: Text(
                                ['M', 'T', 'W', 'T', 'F', 'S', 'S'][i],
                              ),
                              selected: _selectedDays[i],
                              onSelected: (selected) {
                                setState(() {
                                  _selectedDays[i] = selected;
                                });
                              },
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                ElevatedButton(
                  child: Text('Save'),
                  onPressed: () {
                    if (_selectedCareReceiverId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Receiver ID not found')),
                      );
                      return;
                    }

                    // Create reminder object
                    Reminder reminder = Reminder(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: _titleController.text,
                      dosage: _selectedType == 'Medication'
                          ? _dosageController.text
                          : '',
                      instructions: _instructionsController.text,
                      time: DateTime(
                        _selectedDate.year,
                        _selectedDate.month,
                        _selectedDate.day,
                        _selectedTime.hour,
                        _selectedTime.minute,
                      ),
                      isRecurring: _isRecurring,
                      recurringDays: _selectedDays,
                      isTaken: false,
                    );

                    // Save reminder
                    _reminderService.addReminderForCareReceiver(
                        _selectedCareReceiverId!, reminder);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Medications & Reminders'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Today'),
            Tab(text: 'All Reminders'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTodayView(),
          _buildAllRemindersView(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: _showAddReminderDialog,
      ),
      bottomNavigationBar: BottomNavigation(currentIndex: 1),
    );
  }

  Widget _buildTodayView() {
    return StreamBuilder<QuerySnapshot>(
      stream: _selectedCareReceiverId != null
          ? _reminderService.getTodayReminders(_selectedCareReceiverId!)
          : null,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No medications for today',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: Icon(Icons.add),
                  label: Text('Add Medication'),
                  onPressed: _showAddReminderDialog,
                ),
              ],
            ),
          );
        }

        List<Reminder> reminders = snapshot.data!.docs
            .map((doc) => Reminder.fromFirestore(doc))
            .toList();

        // Sort by time
        reminders.sort((a, b) => a.time.compareTo(b.time));

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: reminders.length,
          itemBuilder: (context, index) {
            final reminder = reminders[index];

            return Card(
              elevation: 2,
              margin: EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: reminder.isTaken ? Colors.green : Colors.blue,
                  width: 1,
                ),
              ),
              child: ListTile(
                contentPadding: EdgeInsets.all(16),
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color:
                        reminder.isTaken ? Colors.green[100] : Colors.blue[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.medication,
                    color: reminder.isTaken ? Colors.green : Colors.blue,
                    size: 30,
                  ),
                ),
                title: Text(
                  reminder.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 4),
                    if (reminder.dosage.isNotEmpty)
                      Text('Dosage: ${reminder.dosage}'),
                    if (reminder.instructions.isNotEmpty)
                      Text('Instructions: ${reminder.instructions}'),
                    SizedBox(height: 4),
                    Text(
                      'Time: ${DateFormat('h:mm a').format(reminder.time)}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (reminder.isRecurring)
                      Text(
                          'Recurring: ${_getRecurringDaysText(reminder.recurringDays)}'),
                  ],
                ),
                trailing: Checkbox(
                  value: reminder.isTaken,
                  onChanged: (value) {
                    _reminderService.updateReminderStatus(
                      _selectedCareReceiverId!,
                      reminder.id,
                      value ?? false,
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAllRemindersView() {
    return StreamBuilder<QuerySnapshot>(
      stream: _selectedCareReceiverId != null
          ? _reminderService.getRemindersForUser(_selectedCareReceiverId!)
          : null,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No reminders found',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: Icon(Icons.add),
                  label: Text('Add Reminder'),
                  onPressed: _showAddReminderDialog,
                ),
              ],
            ),
          );
        }

        List<Reminder> reminders = snapshot.data!.docs
            .map((doc) => Reminder.fromFirestore(doc))
            .toList();

        // Sort by time
        reminders.sort((a, b) => a.time.compareTo(b.time));

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: reminders.length,
          itemBuilder: (context, index) {
            final reminder = reminders[index];
            return Card(
              elevation: 2,
              margin: EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: reminder.isTaken ? Colors.green : Colors.blue,
                  width: 1,
                ),
              ),
              child: ListTile(
                contentPadding: EdgeInsets.all(16),
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color:
                        reminder.isTaken ? Colors.green[100] : Colors.blue[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.medication,
                    color: reminder.isTaken ? Colors.green : Colors.blue,
                    size: 30,
                  ),
                ),
                title: Text(
                  reminder.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 4),
                    if (reminder.dosage.isNotEmpty)
                      Text('Dosage: ${reminder.dosage}'),
                    if (reminder.instructions.isNotEmpty)
                      Text('Instructions: ${reminder.instructions}'),
                    SizedBox(height: 4),
                    Text(
                      'Time: ${DateFormat('h:mm a').format(reminder.time)}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (reminder.isRecurring)
                      Text(
                          'Recurring: ${_getRecurringDaysText(reminder.recurringDays)}'),
                  ],
                ),
                trailing: Checkbox(
                  value: reminder.isTaken,
                  onChanged: (value) {
                    _reminderService.updateReminderStatus(
                      _selectedCareReceiverId!,
                      reminder.id,
                      value ?? false,
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _getRecurringDaysText(List<bool> days) {
    List<String> dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    List<String> selectedDays = [];

    for (int i = 0; i < days.length; i++) {
      if (days[i]) selectedDays.add(dayNames[i]);
    }

    return selectedDays.join(', ');
  }
}
