import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/health_factory.dart' as health_factory;
import '../services/reminder_service.dart';
import '../models/reminder.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class HealthMonitoringScreen extends StatefulWidget {
  @override
  _HealthMonitoringScreenState createState() => _HealthMonitoringScreenState();
}

class _HealthMonitoringScreenState extends State<HealthMonitoringScreen> {
  final health_factory.HealthFactory healthFactory =
      health_factory.HealthFactory();
  final ReminderService reminderService = ReminderService();
  bool isLoading = true;
  Map<String, dynamic> healthData = {};
  List<health_factory.HealthTip> healthTips = [];
  String? receiverId;
  StreamSubscription<DocumentSnapshot>? _healthDataSubscription;

  @override
  void initState() {
    super.initState();
    fetchReceiverId().then((_) {
      fetchReceiverHealthData();
    });
  }

  @override
  void dispose() {
    _healthDataSubscription?.cancel();
    super.dispose();
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
          receiverId = caregiverDoc['receiverId'];
        });
      }
    }
  }

  Future<void> fetchReceiverHealthData() async {
    if (receiverId != null) {
      _healthDataSubscription = FirebaseFirestore.instance
          .collection('healthData')
          .doc(receiverId)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists) {
          setState(() {
            healthData = snapshot.data() ?? {};
          });
        }
      });

      healthFactory.startStepTracking(receiverId!);
      await fetchHealthTips();
      await fetchAndUpdateSleepData();

      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchHealthTips() async {
    healthTips = (await healthFactory.fetchHealthTips())
        .cast<health_factory.HealthTip>();
    setState(() {});
  }

  Future<void> fetchAndUpdateSleepData() async {
    await healthFactory.fetchAndUpdateSleepData(receiverId!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Health Monitoring'),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: alertCaregivers,
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Health Report',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    SizedBox(height: 20),
                    _buildHealthStatsGrid(),
                    SizedBox(height: 30),
                    Text(
                      'Weekly Trends',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    SizedBox(height: 16),
                    Container(
                      height: 200,
                      child: _buildHealthChart(),
                    ),
                    SizedBox(height: 30),
                    Text(
                      'AI Health Insights',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    SizedBox(height: 16),
                    ...healthTips.map((tip) => _buildHealthTip(tip)).toList(),
                    SizedBox(height: 20),
                    Center(
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.warning),
                        label: Text('Notify Users'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                        ),
                        onPressed: alertCaregivers,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHealthStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildHealthCard(
          title: 'Heart Rate',
          value: '${healthData['heartRate']} bpm',
          icon: Icons.favorite,
          color: Colors.red,
        ),
        _buildHealthCard(
          title: 'Steps Today',
          value: '${healthData['steps'] ?? 0}',
          icon: Icons.directions_walk,
          color: Colors.blue,
        ),
        _buildHealthCard(
          title: 'Sleep',
          value: '${healthData['sleep'] ?? 0} hrs',
          icon: Icons.bedtime,
          color: Colors.indigo,
        ),
        _buildHealthCard(
          title: 'Mood',
          value: '${healthData['mood'] ?? 'Unknown'}',
          icon: Icons.mood,
          color: Colors.amber,
        ),
      ],
    );
  }

  Widget _buildHealthCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                SizedBox(width: 8),
                Text(title, style: TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
            Spacer(),
            Text(
              value,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthChart() {
    // Mock data for the chart

    var series = [
      BarChartGroupData(
        x: 0,
        barRods: [
          BarChartRodData(toY: 75, color: Colors.blue),
        ],
      ),
      BarChartGroupData(
        x: 1,
        barRods: [
          BarChartRodData(toY: 72, color: Colors.blue),
        ],
      ),
      BarChartGroupData(
        x: 2,
        barRods: [
          BarChartRodData(toY: 70, color: Colors.blue),
        ],
      ),
      BarChartGroupData(
        x: 3,
        barRods: [
          BarChartRodData(toY: 74, color: Colors.blue),
        ],
      ),
      BarChartGroupData(
        x: 4,
        barRods: [
          BarChartRodData(toY: 71, color: Colors.blue),
        ],
      ),
      BarChartGroupData(
        x: 5,
        barRods: [
          BarChartRodData(toY: 68, color: Colors.blue),
        ],
      ),
      BarChartGroupData(
        x: 6,
        barRods: [
          BarChartRodData(toY: 72, color: Colors.blue),
        ],
      ),
    ];

    return BarChart(
      BarChartData(
        barGroups: series,
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true),
          ),
        ),
      ),
    );
  }

  Widget _buildHealthTip(health_factory.HealthTip tip) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: Icon(tip.icon, color: Colors.blue),
        ),
        title: Text(tip.title),
        subtitle: Text(tip.description),
      ),
    );
  }

  void alertCaregivers() async {
    try {
      if (receiverId != null) {
        // Create a reminder object
        Reminder reminder = Reminder(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: 'Health Alert',
          dosage: '',
          instructions: 'Please check your health stats',
          time: DateTime.now(),
          isRecurring: false,
          recurringDays: [false, false, false, false, false, false, false],
          isTaken: false,
        );

        // Send the reminder to the user
        await reminderService.addReminderForCareReceiver(receiverId!, reminder);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Alert sent to user')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Receiver ID not found')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send alert. Please try again.')),
      );
    }
  }
}
