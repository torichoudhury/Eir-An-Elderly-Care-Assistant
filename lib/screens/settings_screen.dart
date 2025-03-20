import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elderly/widgets/bottom_navigation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isLoading = true;

  // Settings values
  bool enableVoiceAssistant = true;
  bool enableEmergencyAlerts = true;
  bool enableMedicationReminders = true;
  bool enableLocationTracking = true;

  double voiceSpeed = 1.0;
  double voiceVolume = 0.8;
  String selectedLanguage = 'English';
  String selectedVoice = 'Female';
  String emergencyContactName = '';
  String emergencyContactNumber = '';
  String emergencyContactRelation = '';

  final List<String> languages = [
    'English',
    'Spanish',
    'French',
    'Chinese',
    'Hindi',
    'Arabic',
    'German',
  ];

  final List<String> voices = [
    'Female',
    'Male',
    'Neutral',
  ];

  @override
  void initState() {
    super.initState();
    loadSettings();
  }

  Future<void> loadSettings() async {
    // Fetch emergency contact data from Firebase
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        setState(() {
          emergencyContactName = doc['emergencyContactName'] ?? '';
          emergencyContactNumber = doc['emergencyContactNumber'] ?? '';
          emergencyContactRelation = doc['emergencyContactRelation'] ?? '';
        });
      }
    }

    // Simulate loading other settings
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      isLoading = false;
    });
  }

  Future<void> saveSettings() async {
    // Save emergency contact data to Firebase
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'emergencyContactName': emergencyContactName,
        'emergencyContactNumber': emergencyContactNumber,
        'emergencyContactRelation': emergencyContactRelation,
      });
    }

    // Simulate saving other settings
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Settings saved')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: saveSettings,
            tooltip: 'Save Settings',
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildVoiceAssistantSection(),
                  SizedBox(height: 24),
                  _buildNotificationSection(),
                  SizedBox(height: 24),
                  _buildLanguageSection(),
                  SizedBox(height: 24),
                  _buildEmergencyContactSection(),
                  SizedBox(height: 24),
                  _buildPrivacySection(),
                  SizedBox(height: 24),
                  _buildAdvancedSection(),
                ],
              ),
            ),
            bottomNavigationBar: BottomNavigation(currentIndex: 1),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildVoiceAssistantSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Voice Assistant'),
            SwitchListTile(
              title: Text('Enable Voice Assistant'),
              subtitle: Text('Use voice commands and responses'),
              value: enableVoiceAssistant,
              onChanged: (value) {
                setState(() {
                  enableVoiceAssistant = value;
                });
              },
            ),
            ListTile(
              title: Text('Voice Type'),
              trailing: DropdownButton<String>(
                value: selectedVoice,
                onChanged: enableVoiceAssistant
                    ? (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            selectedVoice = newValue;
                          });
                        }
                      }
                    : null,
                items: voices.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ),
            ListTile(
              title: Text('Voice Speed'),
              subtitle: Slider(
                value: voiceSpeed,
                min: 0.5,
                max: 2.0,
                divisions: 6,
                label: voiceSpeed.toStringAsFixed(1) + 'x',
                onChanged: enableVoiceAssistant
                    ? (value) {
                        setState(() {
                          voiceSpeed = value;
                        });
                      }
                    : null,
              ),
            ),
            ListTile(
              title: Text('Voice Volume'),
              subtitle: Slider(
                value: voiceVolume,
                min: 0.0,
                max: 1.0,
                divisions: 10,
                label: (voiceVolume * 100).toStringAsFixed(0) + '%',
                onChanged: enableVoiceAssistant
                    ? (value) {
                        setState(() {
                          voiceVolume = value;
                        });
                      }
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Notifications'),
            SwitchListTile(
              title: Text('Emergency Alerts'),
              subtitle: Text('Critical notifications for emergency situations'),
              value: enableEmergencyAlerts,
              onChanged: (value) {
                setState(() {
                  enableEmergencyAlerts = value;
                });
              },
            ),
            SwitchListTile(
              title: Text('Medication Reminders'),
              subtitle: Text('Notifications for medication schedules'),
              value: enableMedicationReminders,
              onChanged: (value) {
                setState(() {
                  enableMedicationReminders = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Language & Region'),
            ListTile(
              title: Text('Language'),
              trailing: DropdownButton<String>(
                value: selectedLanguage,
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      selectedLanguage = newValue;
                    });
                  }
                },
                items: languages.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ),
            ListTile(
              title: Text('Date Format'),
              trailing: DropdownButton<String>(
                value: 'MM/DD/YYYY',
                onChanged: (String? newValue) {
                  // Update setting
                },
                items: ['MM/DD/YYYY', 'DD/MM/YYYY', 'YYYY-MM-DD']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ),
            ListTile(
              title: Text('Time Format'),
              trailing: DropdownButton<String>(
                value: '12-hour',
                onChanged: (String? newValue) {
                  // Update setting
                },
                items: ['12-hour', '24-hour']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyContactSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Emergency Contacts'),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue.shade100,
                child: Text(emergencyContactName.isNotEmpty
                    ? emergencyContactName[0]
                    : ''),
              ),
              title: Text(emergencyContactName),
              subtitle: Text(emergencyContactRelation),
              trailing: IconButton(
                icon: Icon(Icons.edit),
                onPressed: () {
                  _showEditEmergencyContactDialog();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditEmergencyContactDialog() {
    final TextEditingController _nameController =
        TextEditingController(text: emergencyContactName);
    final TextEditingController _numberController =
        TextEditingController(text: emergencyContactNumber);
    final TextEditingController _relationController =
        TextEditingController(text: emergencyContactRelation);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Emergency Contact'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _numberController,
                  decoration: InputDecoration(
                    labelText: 'Number',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _relationController,
                  decoration: InputDecoration(
                    labelText: 'Relation',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text('Save'),
              onPressed: () {
                setState(() {
                  emergencyContactName = _nameController.text;
                  emergencyContactNumber = _numberController.text;
                  emergencyContactRelation = _relationController.text;
                });
                saveSettings();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildPrivacySection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Privacy & Location'),
            SwitchListTile(
              title: Text('Location Tracking'),
              subtitle: Text('Allow caregivers to view your location'),
              value: enableLocationTracking,
              onChanged: (value) {
                setState(() {
                  enableLocationTracking = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Advanced'),
            ListTile(
              title: Text('About'),
              subtitle: Text('Version 1.0.0'),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    Navigator.of(context).pushReplacementNamed('/login');
                  },
                  child: Text('Sign Out'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}