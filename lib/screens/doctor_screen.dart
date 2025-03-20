import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class DoctorScreen extends StatefulWidget {
  @override
  _DoctorScreenState createState() => _DoctorScreenState();
}

class _DoctorScreenState extends State<DoctorScreen> {
  // List of doctors with their details
  final List<Doctor> doctors = [
    Doctor(
      name: 'Dr. Vinod Prem Anand',
      specialty: 'Geriatrician',
      phoneNumber: '+1 (555) 123-4567',
      address: 'Old No. 52 ,New No. 111, 1st Main Road, Gandhi Nagar',
      rating: 4.8,
      latitude: 12.8230,  // Chennai central coordinates
      longitude: 80.0444,
      imageUrl: 'assets/images/doctor1.jpg',
    ),
    Doctor(
      name: 'Dr. Sankara Subramani Kumarauru',
      specialty: 'Cardiologist',
      phoneNumber: '+1 (555) 234-5678',
      address: 'Number 43, Lakshmi Talkies Road',
      rating: 4.7,
      latitude: 12.8350,  // Slightly north
      longitude: 80.0524,  // Slightly east
      imageUrl: 'assets/images/doctor2.jpg',
    ),
    Doctor(
      name: 'Dr. Ananth Padmanaban',
      specialty: 'Neurologist',
      phoneNumber: '+1 (555) 345-6789',
      address: '72, Nelson Manickam Road, Aminjikarai',
      rating: 4.9,
      latitude: 12.8150,  // Slightly south
      longitude: 80.0394,  // Slightly west
      imageUrl: 'assets/images/doctor3.jpg',
    ),
    Doctor(
      name: 'Dr. Jeysel Suraj',
      specialty: 'General Practitioner',
      phoneNumber: '+1 (555) 456-7890',
      address: 'Number 26, Ex-Servicemen Colony, 1st Street, Perumbakkam Main Road',
      rating: 4.6,
      latitude: 12.8280,  // Slightly north
      longitude: 80.0344,  // Slightly west
      imageUrl: 'assets/images/doctor4.jpg',
    ),
  ];

  int _selectedDoctorIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'Doctors',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Map section
          Container(
            height: 300,
            child: FlutterMap(
              options: MapOptions(
                initialCenter:
                    LatLng(12.8230, 80.0444), // Updated initial position
                initialZoom:
                    13.0, // You can set an initial zoom level if needed
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: ['a', 'b', 'c'],
                ),
                MarkerLayer(
                  markers: doctors.map((doctor) {
                    return Marker(
                      width: 200.0,
                      height: 60.0,
                      point: LatLng(doctor.latitude, doctor.longitude),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: doctors.indexOf(doctor) == _selectedDoctorIndex
                                  ? Colors.blue
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              doctor.name,
                              style: TextStyle(
                                color: doctors.indexOf(doctor) == _selectedDoctorIndex
                                    ? Colors.white
                                    : Colors.black87,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: doctors.indexOf(doctor) == _selectedDoctorIndex
                                  ? Colors.blue
                                  : Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: doctors.indexOf(doctor) == _selectedDoctorIndex
                                    ? Colors.blue
                                    : Colors.grey.shade300,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.location_on,
                              color: doctors.indexOf(doctor) == _selectedDoctorIndex
                                  ? Colors.white
                                  : Colors.red,
                              size: 30,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // Doctor list
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: doctors.length,
              itemBuilder: (context, index) {
                final doctor = doctors[index];
                return _buildDoctorCard(doctor, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorCard(Doctor doctor, int index) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDoctorIndex = index;
        });
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: _selectedDoctorIndex == index
                ? Colors.blue
                : Colors.grey.withOpacity(0.2),
            width: _selectedDoctorIndex == index ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            // Doctor info section
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Doctor image
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.blue,
                    ),
                  ),
                  SizedBox(width: 16),

                  // Doctor details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doctor.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          doctor.specialty,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 16),
                            SizedBox(width: 4),
                            Text(
                              doctor.rating.toString(),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          doctor.address,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Call button
            InkWell(
              onTap: () async {
                final Uri launchUri = Uri(
                  scheme: 'tel',
                  path: doctor.phoneNumber.replaceAll(RegExp(r'[^0-9]'), ''),
                );
                if (await canLaunchUrl(launchUri)) {
                  await launchUrl(launchUri);
                }
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.phone, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      doctor.phoneNumber,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Doctor {
  final String name;
  final String specialty;
  final String phoneNumber;
  final String address;
  final double rating;
  final double latitude;
  final double longitude;
  final String imageUrl;

  Doctor({
    required this.name,
    required this.specialty,
    required this.phoneNumber,
    required this.address,
    required this.rating,
    required this.latitude,
    required this.longitude,
    required this.imageUrl,
  });
}