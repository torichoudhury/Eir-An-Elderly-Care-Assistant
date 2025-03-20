import 'package:elderly/screens/user_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserDetailsScreen extends StatefulWidget {
  final String uid;

  const UserDetailsScreen({super.key, required this.uid});

  @override
  _UserDetailsScreenState createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _place = '';
  int _age = 0;
  String _gender = 'Male';
  String _userType = 'User';
  bool _isLoading = false;
  String _phoneNumber = '';
  String _emergencyContactName = '';
  String _emergencyContactNumber = '';
  String _emergencyContactRelation = '';
  String? _receiverId;
  List<Map<String, dynamic>> _users = [];

  // List of gender options
  final List<String> _genderOptions = ['Male', 'Female', 'Other'];

  // List of user type options
  final List<String> _userTypeOptions = ['User', 'Caregiver'];

  @override
  void initState() {
    super.initState();
    fetchUsers().then((users) {
      setState(() {
        _users = users;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.05),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header section

                    const SizedBox(height: 24),
                    Text(
                      'Personal Information',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),

                    // Name field
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Enter your full name' : null,
                      onChanged: (value) {
                        setState(() => _name = value);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Place field
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Location',
                        prefixIcon: const Icon(Icons.location_on),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Enter your location' : null,
                      onChanged: (value) {
                        setState(() => _place = value);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Age field
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Age',
                        prefixIcon: const Icon(Icons.calendar_today),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Enter your age';
                        }
                        final age = int.tryParse(value);
                        if (age == null || age <= 0) {
                          return 'Please enter a valid age';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          setState(() => _age = int.tryParse(value) ?? 0);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Phone number field
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: const Icon(Icons.phone),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) =>
                          value!.isEmpty ? 'Enter your phone number' : null,
                      onChanged: (value) {
                        setState(() => _phoneNumber = value);
                      },
                    ),
                    const SizedBox(height: 24),

                    // Gender dropdown
                    DropdownButtonFormField(
                      decoration: InputDecoration(
                        labelText: 'Gender',
                        prefixIcon: const Icon(Icons.people),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      value: _gender,
                      items: _genderOptions.map((gender) {
                        return DropdownMenuItem(
                          value: gender,
                          child: Text(gender),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _gender = value as String);
                      },
                    ),
                    const SizedBox(height: 16),

                    // User type selection with radio buttons
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.shade300,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'I am a:',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...List.generate(_userTypeOptions.length, (index) {
                            return RadioListTile<String>(
                              title: Text(_userTypeOptions[index]),
                              value: _userTypeOptions[index],
                              groupValue: _userType,
                              onChanged: (value) {
                                setState(() => _userType = value!);
                              },
                              activeColor: Theme.of(context).primaryColor,
                              contentPadding: EdgeInsets.zero,
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Conditionally render emergency contact fields
                    if (_userType == 'User') ...[
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Emergency Contact Name',
                          prefixIcon: const Icon(Icons.person),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (value) => value!.isEmpty
                            ? 'Enter emergency contact name'
                            : null,
                        onChanged: (value) {
                          setState(() => _emergencyContactName = value);
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Emergency Contact Number',
                          prefixIcon: const Icon(Icons.phone),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) => value!.isEmpty
                            ? 'Enter emergency contact number'
                            : null,
                        onChanged: (value) {
                          setState(() => _emergencyContactNumber = value);
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Relation with Emergency Contact',
                          prefixIcon: const Icon(Icons.family_restroom),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (value) => value!.isEmpty
                            ? 'Enter relation with emergency contact'
                            : null,
                        onChanged: (value) {
                          setState(() => _emergencyContactRelation = value);
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Conditionally render user selection dropdown
                    if (_userType == 'Caregiver') ...[
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Select User',
                          prefixIcon: const Icon(Icons.person_search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: _users.map((user) {
                          return DropdownMenuItem<String>(
                            value: user['uid'],
                            child: Text(user['name']),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _receiverId = value);
                        },
                        validator: (value) =>
                            value == null ? 'Select a user' : null,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Submit button
                    ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () async {
                              if (_formKey.currentState!.validate()) {
                                setState(() => _isLoading = true);
                                try {
                                  await Provider.of<AuthService>(context,
                                          listen: false)
                                      .saveUserDetails(
                                    widget.uid,
                                    _name,
                                    _place,
                                    _age,
                                    _gender,
                                    _userType,
                                    _phoneNumber, // Add phone number here
                                    _emergencyContactName,
                                    _emergencyContactNumber,
                                    _emergencyContactRelation,
                                    _receiverId,
                                  );

                                  if (!mounted) return;

                                  if (_userType == 'Caregiver') {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const HomeScreen()),
                                    );
                                  } else {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              CareReceiverScreen()),
                                    );
                                  }
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content:
                                            Text('Error: ${e.toString()}')),
                                  );
                                  setState(() => _isLoading = false);
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Submit',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> fetchUsers() async {
    final QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('userType', isEqualTo: 'User')
        .get();

    return snapshot.docs.map((doc) {
      return {
        'uid': doc.id,
        'name': doc['name'],
      };
    }).toList();
  }
}
