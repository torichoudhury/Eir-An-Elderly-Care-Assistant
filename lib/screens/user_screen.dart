import 'package:elderly/models/reminder.dart';
import 'package:elderly/screens/doctor_screen.dart';
import 'package:flutter/material.dart';
import '../services/sos_service.dart';
import '../services/fall_detection_service.dart';
import '../services/health_factory.dart' as health_service;
import '../services/reminder_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ai_assistant_screen.dart';
import 'sign_in_screen.dart';
import 'chat_screen.dart'; // Import the ChatScreen
import '../widgets/step_counter.dart';

class CareReceiverScreen extends StatefulWidget {
  const CareReceiverScreen({super.key});

  @override
  _CareReceiverScreenState createState() => _CareReceiverScreenState();
}

class _CareReceiverScreenState extends State<CareReceiverScreen> {
  final health_service.HealthFactory healthFactory =
      health_service.HealthFactory();
  final ReminderService reminderService = ReminderService();
  bool isLoading = true;
  Map<String, dynamic> healthData = {};
  Stream<QuerySnapshot>? remindersStream;
  String username = '';
  String address = '';
  String userId = '';
  String? caregiverId;
  int _currentSteps = 0;

  @override
  void initState() {
    super.initState();
    initializeData();
    _listenToStepUpdates();
  }

  Future<void> initializeData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        userId = user.uid;
      });

      try {
        await healthFactory.initializeHealthData(userId);

        FirebaseFirestore.instance
            .collection('healthData')
            .doc(userId)
            .snapshots()
            .listen((snapshot) {
          if (snapshot.exists) {
            setState(() {
              healthData = snapshot.data() ?? {};
            });
          }
        });

        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        if (userDoc.exists) {
          setState(() {
            username = userDoc['name'] ?? '';
            address = userDoc['place'] ?? '';
          });
        }

        // Find the caregiver whose receiverId matches the user's ID
        final caregiverQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('userType', isEqualTo: 'Caregiver')
            .where('receiverId', isEqualTo: userId)
            .get();

        if (caregiverQuery.docs.isNotEmpty) {
          setState(() {
            caregiverId = caregiverQuery.docs.first.id;
          });
        }

        await fetchHealthData();
        startFallDetection();

        healthFactory.startStepTracking(userId);
        healthFactory.startActivityTracking(userId);

        setState(() {
          remindersStream = reminderService.getRemindersForUser(userId);
        });
      } catch (e) {
        print("Error initializing data: $e");
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> fetchHealthData() async {
    try {
      healthData = await healthFactory.fetchHealthData(userId);
      setState(() {});
    } catch (e) {
      print("Error fetching health data: $e");
      healthData = healthFactory.getDefaultHealthData();
    }
  }

  void startFallDetection() {
    final fallDetectionService = FallDetectionService();
    fallDetectionService.startMonitoring();
  }

  void sendSOS() async {
    final sosService = SOSService();
    await sosService.sendSOS();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Emergency contact notified'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => SignInScreen()),
        (route) => false,
      );
    }
  }

  void _showAddReminderDialog() {
    final titleController = TextEditingController();
    final dosageController = TextEditingController();
    final instructionsController = TextEditingController();
    TimeOfDay selectedTime = TimeOfDay.now();
    bool isRecurring = false;
    List<bool> selectedDays = List.generate(7, (_) => false);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text(
                'Add Medication Reminder',
                style: TextStyle(fontSize: 18),
              ),
              titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              contentPadding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleController,
                      style: const TextStyle(fontSize: 14),
                      decoration: const InputDecoration(
                        labelText: 'Medication Name',
                        labelStyle: TextStyle(fontSize: 14),
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.medication, size: 20),
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: dosageController,
                      style: const TextStyle(fontSize: 14),
                      decoration: const InputDecoration(
                        labelText: 'Dosage (e.g., 1 pill)',
                        labelStyle: TextStyle(fontSize: 14),
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.local_pharmacy, size: 20),
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: instructionsController,
                      style: const TextStyle(fontSize: 14),
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Instructions',
                        labelStyle: TextStyle(fontSize: 14),
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.info_outline, size: 20),
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.access_time, color: Colors.blue, size: 20),
                        const SizedBox(width: 8),
                        Text('Time:',
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey[700])),
                        const SizedBox(width: 8),
                        TextButton(
                          child: Text(
                            selectedTime.format(context),
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          onPressed: () async {
                            final TimeOfDay? picked = await showTimePicker(
                              context: context,
                              initialTime: selectedTime,
                            );
                            if (picked != null) {
                              setState(() => selectedTime = picked);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.repeat, color: Colors.blue, size: 20),
                        const SizedBox(width: 8),
                        Text('Recurring:',
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey[700])),
                        const Spacer(),
                        Switch(
                          value: isRecurring,
                          activeColor: Colors.blue,
                          onChanged: (value) =>
                              setState(() => isRecurring = value),
                        ),
                      ],
                    ),
                    if (isRecurring) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Select days:',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 4,
                        children: [
                          for (int i = 0; i < 7; i++)
                            FilterChip(
                              label: Text(
                                ['M', 'T', 'W', 'T', 'F', 'S', 'S'][i],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: selectedDays[i]
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                              selected: selectedDays[i],
                              selectedColor: Colors.blue,
                              showCheckmark: false,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 0),
                              onSelected: (selected) =>
                                  setState(() => selectedDays[i] = selected),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel', style: TextStyle(fontSize: 14)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                ElevatedButton(
                  child: const Text('Save', style: TextStyle(fontSize: 14)),
                  onPressed: () {
                    // Create reminder object
                    Reminder reminder = Reminder(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: titleController.text,
                      dosage: dosageController.text,
                      instructions: instructionsController.text,
                      time: DateTime(
                        DateTime.now().year,
                        DateTime.now().month,
                        DateTime.now().day,
                        selectedTime.hour,
                        selectedTime.minute,
                      ),
                      isRecurring: isRecurring,
                      recurringDays: selectedDays,
                      isTaken: false,
                    );

                    // Save reminder
                    reminderService.addReminderForCareReceiver(
                        userId, reminder);
                    Navigator.of(context).pop();
                  },
                ),
              ],
              actionsPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            );
          },
        );
      },
    );
  }

  void _listenToStepUpdates() {
    if (userId.isNotEmpty) {
      FirebaseFirestore.instance
          .collection('healthData')
          .doc(userId)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists) {
          final data = snapshot.data();
          if (data != null && data['steps'] != null) {
            setState(() {
              _currentSteps = data['steps'];
            });
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 100.0,
                  floating: false,
                  pinned: true,
                  elevation: 0,
                  actions: [], // Empty actions to ensure no icons
                  flexibleSpace: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF9C27B0),
                          Color(0xFF7B1FA2),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.withOpacity(0.2),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: FlexibleSpaceBar(
                      titlePadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      title: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back,',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            username,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  automaticallyImplyLeading: false,
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // SOS Button
                        Center(
                          child: GestureDetector(
                            onTap: sendSOS,
                            child: Container(
                              width: 120, // Reduced from 140
                              height: 120, // Reduced from 140
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const RadialGradient(
                                  colors: [
                                    Color(0xFFFF5252),  // Bright red
                                    Color(0xFFD32F2F),  // Darker red
                                  ],
                                  radius: 0.85,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF5252).withOpacity(0.3),
                                    spreadRadius: 2,
                                    blurRadius: 15,
                                    offset: const Offset(0, 4),
                                  ),
                                  BoxShadow(
                                    color: Colors.white,
                                    spreadRadius: -3,
                                    blurRadius: 10,
                                    offset: const Offset(0, -4),
                                  ),
                                ],
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Pulsing animation container
                                  TweenAnimationBuilder(
                                    tween: Tween<double>(begin: 0.8, end: 1.2),
                                    duration: const Duration(seconds: 2),
                                    curve: Curves.easeInOut,
                                    builder: (context, double value, child) {
                                      return Container(
                                        width: 110 * value, // Reduced from 130
                                        height: 110 * value, // Reduced from 130
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.red.withOpacity(0.5),
                                            width: 2,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  // Inner content - removed icon, kept only text
                                  const Text(
                                    'SOS',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 32, // Increased from 28 to make it more prominent
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Help text below SOS button
                        Center(
                          child: Text(
                            'Tap for Emergency Assistance',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Health Monitoring Section
                        _buildSectionCard(
                          'Health Tracking',
                          Icons.monitor_heart,
                          _buildHealthStatsGrid(),
                        ),

                        // Medications Section
                        _buildSectionCard(
                          'Medications',
                          Icons.medication,
                          _buildRemindersList(),
                        ),

                        // Replace the Services Section in the build method
                        // Direct Services Grid without section wrapper
                        _buildServicesGrid(context),
                        // Remove Daily Activities section
                      ],
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: Colors.purple,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assistant),
            label: 'Assistant',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.logout),
            label: 'Logout',
          ),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              // Do nothing since we're already on home
              break;
            case 1:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AIAssistantScreen()),
              );
              break;
            case 2:
              logout();
              break;
          }
        },
      ),
    );
  }

  Widget _buildHealthStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12, // Reduced spacing
      crossAxisSpacing: 12, // Reduced spacing
      childAspectRatio: 1.27, // Increased aspect ratio to make cards shorter
      children: [
        _buildHealthCard(
          title: 'Steps Today',
          icon: Icons.directions_walk,
          color: Colors.blue,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              StepCounter(
                onStepCountUpdated: (steps) {
                  setState(() {
                    _currentSteps = steps;
                  });
                },
              ),
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('healthData')
                    .doc(userId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data!.exists) {
                    final data = snapshot.data!.data() as Map<String, dynamic>?;
                    final steps = data?['steps'] ?? _currentSteps;
                    return Column(
                      children: [
                        Text(
                          steps.toString(),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        LinearProgressIndicator(
                          value: steps / 2000,
                          backgroundColor: Colors.blue.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                        Text(
                          'Goal: 2,000',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    );
                  }
                  return const CircularProgressIndicator();
                },
              ),
            ],
          ),
        ),
        _buildHealthCard(
          title: 'Mood',
          value: '${healthData['mood'] ?? 'Good'}',
          icon: Icons.mood,
          color: Colors.amber,
          subtitle: 'Feeling well',
          progress: 0.8,
        ),
      ],
    );
  }

  Widget _buildHealthCard({
    required String title,
    required IconData icon,
    required Color color,
    Widget? child,
    String? value,
    String? subtitle,
    double progress = 0.0,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 10, vertical: 8), // Adjusted padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.1),
            Colors.white,
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Added to prevent expansion
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(4), // Reduced padding
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 16), // Smaller icon
              ),
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 12, // Smaller font
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (child != null)
            child
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value ?? '',
                  style: const TextStyle(
                    fontSize: 20, // Reduced font size
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2), // Reduced spacing
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11, // Smaller font
                      color: Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 6), // Reduced spacing
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation(color),
                    minHeight: 3, // Slightly smaller progress bar
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildRemindersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: remindersStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.medication_outlined,
                    size: 36, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text(
                  'No medications scheduled',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap + to add medication reminders',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final reminders = snapshot.data!.docs.map((doc) {
          return Reminder.fromFirestore(doc);
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Today\'s Schedule',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child:
                          const Icon(Icons.add, size: 20, color: Colors.blue),
                    ),
                    onPressed: _showAddReminderDialog,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withOpacity(0.1)),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: reminders.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: Colors.grey.withOpacity(0.15),
                ),
                itemBuilder: (context, index) {
                  final reminder = reminders[index];
                  return ListTile(
                    dense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: reminder.isTaken
                            ? Colors.green.withOpacity(0.1)
                            : Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.medication,
                        color: reminder.isTaken ? Colors.green : Colors.blue,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      reminder.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        decoration: reminder.isTaken
                            ? TextDecoration.lineThrough
                            : null,
                        color: reminder.isTaken ? Colors.grey : Colors.black87,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Text(
                            reminder.dosage,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                              color: Colors.grey[400],
                              shape: BoxShape.circle,
                            ),
                          ),
                          Text(
                            DateFormat('h:mm a').format(reminder.time),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    trailing: Transform.scale(
                      scale: 0.9,
                      child: Checkbox(
                        value: reminder.isTaken,
                        activeColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        onChanged: (value) {
                          setState(() {
                            reminder.isTaken = value ?? false;
                          });
                          reminderService.updateReminderStatus(
                              userId, reminder.id, reminder.isTaken);
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildServicesGrid(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildServiceItem(
              context: context,
              icon: Icons.local_hospital,
              label: 'Doctor\nConsult',
              color: Colors.cyan,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DoctorScreen(),
                ),
              ),
            ),
            if (caregiverId != null) ...[
              const SizedBox(width: 24),
              _buildServiceItem(
                context: context,
                icon: Icons.chat,
                label: 'Chat with\nCaregiver',
                color: Colors.teal,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(receiverId: caregiverId!),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildServiceItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, Widget content) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.purple),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7B1FA2), // Purple 700
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            content,
          ],
        ),
      ),
    );
  }
}