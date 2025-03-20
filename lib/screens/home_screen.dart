import 'package:elderly/screens/help_screen.dart';
import 'package:flutter/material.dart';
import '../widgets/bottom_navigation.dart';
import 'alert_screen.dart';
import 'caregive_dashboard_screen.dart';
import 'doctor_screen.dart';
import 'reminder_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? receiverId;
  Map<String, dynamic> healthData = {};
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
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  Future<String> _getUsername() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        return userDoc['name'] ?? 'User';
      }
    }
    return 'User';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFE6E6FA),  // Light Lavender
                Color(0xFFD8BFD8),  // Thistle
              ],
            ),
          ),
        ),
        title: Text(
          'Elderly Care',
          style: TextStyle(
            color: Color(0xFF4B0082),  // Indigo
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome section
              FutureBuilder<String>(
                future: _getUsername(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else {
                    final username = snapshot.data ?? 'User';
                    return Container(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.blue[100],
                            child: Icon(Icons.person,
                                color: Colors.blue, size: 30),
                          ),
                          SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getGreeting(),
                                style: TextStyle(
                                  fontSize: 17,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                username,
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),

              // Increase the spacing here
              SizedBox(height: 32), // Changed from 24 to 32

              // Health Stats Section with additional padding
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Health Stats',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 12),
              _buildHealthStatsGrid(),

              SizedBox(height: 24),

              // Services Grid - now contains its own title
              _buildServicesGrid(context),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigation(currentIndex: 0),
    );
  }

  Widget _buildHealthStatsGrid() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF0E6FF).withOpacity(0.9),  // Lighter Lavender
            Color(0xFFE6E6FA).withOpacity(0.9),  // Light Lavender
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(16),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        childAspectRatio: 1.35,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _buildHealthCard(
            title: 'Steps Today',
            value: '${healthData['steps'] ?? 'N/A'}',
            icon: Icons.directions_walk,
            color: Color(0xFF4A90E2), // Modern blue
            trend: '86% of goal',
            trendPositive: true,
          ),
          _buildHealthCard(
            title: 'Mood',
            value: '${healthData['mood'] ?? 'N/A'}',
            icon: Icons.mood,
            color: Color(0xFFF5B041), // Warm orange
            trend: 'Better than yesterday',
            trendPositive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildHealthCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String trend,
    required bool trendPositive,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.1), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
              ],
            ),
            Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color.withOpacity(0.9),
              ),
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  trendPositive ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 14,
                  color: trendPositive ? Color(0xFF2ECC71) : Color(0xFFE74C3C),
                ),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    trend,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: trendPositive ? Color(0xFF2ECC71) : Color(0xFFE74C3C),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesGrid(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF0E6FF).withOpacity(0.9),  // Lighter Lavender
            Color(0xFFE6E6FA).withOpacity(0.9),  // Light Lavender
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Services',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.purple[700],
            ),
          ),
          SizedBox(height: 20),
          // First row - 3 items
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildServiceItem(
                context: context,
                icon: Icons.local_hospital,
                label: 'Doctor',
                color: Colors.cyan,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DoctorScreen()),
                ),
              ),
              _buildServiceItem(
                context: context,
                icon: Icons.notifications_active,
                label: 'Alerts',
                color: Colors.orange,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AlertsScreen()),
                ),
              ),
              _buildServiceItem(
                context: context,
                icon: Icons.alarm,
                label: 'Reminders',
                color: Colors.purple,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ReminderScreen()),
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          // Second row - 2 items centered
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildServiceItem(
                context: context,
                icon: Icons.people,
                label: 'Caregivers',
                color: Colors.teal,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CaregiverDashboardScreen()),
                ),
              ),
              SizedBox(width: 32),
              _buildServiceItem(
                context: context,
                icon: Icons.help_outline,
                label: 'About us',
                color: Colors.green,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HelpScreen()),
                ),
              ),
            ],
          ),
        ],
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
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 45), // Increased icon size
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 16, // Increased text size
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }


}