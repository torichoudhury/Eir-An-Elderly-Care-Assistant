import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'tracker_screen.dart';
import 'chat_screen.dart';
import 'package:flutter/services.dart';

class CaregiverDashboardScreen extends StatefulWidget {
  @override
  _CaregiverDashboardScreenState createState() =>
      _CaregiverDashboardScreenState();
}

class _CaregiverDashboardScreenState extends State<CaregiverDashboardScreen> {
  String? receiverId;
  Map<String, dynamic>? receiverDetails;
  String? selectedMood;
  String? phoneNumber;
  String? emergencyContactNumber;
  
  // Swiggy-inspired color scheme
  final primaryColor = Color(0xFF00B37A);
  final secondaryColor = Color(0xFF0A8F60);
  final lightColor = Color(0xFFE6F7F1);
  final accentColor = Color(0xFF003D29);
  final backgroundColor = Color(0xFFF6FDFB);

  @override
  void initState() {
    super.initState();
    fetchReceiverId().then((_) {
      fetchReceiverDetails();
    });
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

  Future<void> fetchReceiverDetails() async {
    if (receiverId != null) {
      final receiverDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(receiverId)
          .get();

      if (receiverDoc.exists) {
        setState(() {
          receiverDetails = receiverDoc.data();
          selectedMood = receiverDetails!['mood'];
          phoneNumber = receiverDetails!['phoneNumber'];
          emergencyContactNumber = receiverDetails!['emergencyContactNumber'];
        });
      }
    }
  }

  Future<void> updateMood(String mood) async {
    if (receiverId != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(receiverId)
          .update({'mood': mood});
      setState(() {
        selectedMood = mood;
      });
    }
  }

  Future<void> _makePhoneCall(String? phoneNumber) async {
    if (phoneNumber != null) {
      final Uri launchUri = Uri(
        scheme: 'tel',
        path: phoneNumber,
      );
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        throw 'Could not launch $launchUri';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: AppBar(
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          title: Text(
            'Dashboard',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: secondaryColor,
          
        ),
      ),
      body: receiverDetails == null
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
            )
          : SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero banner section
                  Container(
                    padding: EdgeInsets.only(left: 20, right: 180, top: 18, bottom: 24),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'You\'re taking care of ${receiverDetails!['name']}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Quick Actions Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Container(
                    height: 100,
                    child: ListView(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      scrollDirection: Axis.horizontal,
                      physics: BouncingScrollPhysics(),
                      children: [
                        _buildQuickActionCard(
                          'Call',
                          Icons.call,
                          () => _makePhoneCall(phoneNumber),
                        ),
                        _buildQuickActionCard(
                          'Chat',
                          Icons.chat_bubble_outline,
                          () {
                            if (receiverId != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ChatScreen(receiverId: receiverId!),
                                ),
                              );
                            }
                          },
                        ),
                        _buildQuickActionCard(
                          'Location',
                          Icons.location_on_outlined,
                          () {
                            if (receiverId != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      TrackerScreen(userId: receiverId!),
                                ),
                              );
                            }
                          },
                        ),
                        _buildQuickActionCard(
                          'Emergency',
                          Icons.emergency_outlined,
                          () => _makePhoneCall(emergencyContactNumber),
                          isEmergency: true,
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Receiver Details Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Receiver Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundColor: lightColor,
                                  child: Icon(
                                    Icons.person,
                                    size: 36,
                                    color: primaryColor,
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${receiverDetails!['name']}',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: accentColor,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        '${receiverDetails!['age']} years • ${receiverDetails!['gender']}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.location_on,
                                            size: 16,
                                            color: primaryColor,
                                          ),
                                          SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              '${receiverDetails!['place']}',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Mood Tracker
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Mood Tracker',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: _getMoodColor(selectedMood).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      _getMoodIcon(selectedMood),
                                      color: _getMoodColor(selectedMood),
                                      size: 28,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Current Mood',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      '${selectedMood ?? 'Unknown'}',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: _getMoodColor(selectedMood),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Change Mood',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[700],
                              ),
                            ),
                            SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildMoodButton('Happy', Icons.sentiment_very_satisfied, Colors.green),
                                _buildMoodButton('Neutral', Icons.sentiment_neutral, Colors.amber[700]!),
                                _buildMoodButton('Sad', Icons.sentiment_dissatisfied, Colors.red),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildQuickActionCard(String title, IconData icon, VoidCallback onTap, {bool isEmergency = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 90,
          decoration: BoxDecoration(
            color: isEmergency ? Colors.red.withOpacity(0.1) : lightColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isEmergency ? Colors.red.withOpacity(0.3) : primaryColor.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isEmergency ? Colors.red.withOpacity(0.2) : primaryColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isEmergency ? Colors.red : primaryColor,
                  size: 24,
                ),
              ),
              SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isEmergency ? Colors.red : accentColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getMoodColor(String? mood) {
    if (mood == 'Happy') return Colors.green;
    if (mood == 'Neutral') return Colors.amber[700]!;
    if (mood == 'Sad') return Colors.red;
    return Colors.grey;
  }

  IconData _getMoodIcon(String? mood) {
    if (mood == 'Happy') return Icons.sentiment_very_satisfied;
    if (mood == 'Neutral') return Icons.sentiment_neutral;
    if (mood == 'Sad') return Icons.sentiment_dissatisfied;
    return Icons.mood;
  }

  Widget _buildMoodButton(String mood, IconData icon, Color color) {
    bool isSelected = selectedMood == mood;
    
    return InkWell(
      onTap: () {
        updateMood(mood);
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey[500],
              size: 20,
            ),
            SizedBox(width: 4),
            Text(
              mood,
              style: TextStyle(
                color: isSelected ? color : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}