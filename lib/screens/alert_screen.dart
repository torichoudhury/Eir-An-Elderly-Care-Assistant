import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  _AlertsScreenState createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen>
    with SingleTickerProviderStateMixin {
  bool isLoading = true;
  late TabController _tabController;
  List<Map<String, dynamic>> alerts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    fetchAlerts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> fetchAlerts() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Get alerts from Firestore
      final querySnapshot = await FirebaseFirestore.instance
          .collection('alerts')
          .orderBy('timestamp', descending: true)
          .get();

      final fetchedAlerts = querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        // Convert ISO 8601 string to DateTime
        if (data['timestamp'] is String) {
          data['timestamp'] = DateTime.parse(data['timestamp']);
        } else if (data['timestamp'] is Timestamp) {
          data['timestamp'] = (data['timestamp'] as Timestamp).toDate();
        }

        // Ensure ID is present
        if (!data.containsKey('id')) {
          data['id'] = doc.id;
        }

        return data;
      }).toList();

      setState(() {
        alerts = fetchedAlerts;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching alerts: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  void markAsResolved(String alertId) async {
    try {
      // Find the document with this alert ID
      final querySnapshot = await FirebaseFirestore.instance
          .collection('alerts')
          .where('id', isEqualTo: alertId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        await querySnapshot.docs.first.reference.update({'resolved': true});
      }

      setState(() {
        final alertIndex = alerts.indexWhere((alert) => alert['id'] == alertId);
        if (alertIndex != -1) {
          alerts[alertIndex]['resolved'] = true;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Alert marked as resolved')),
      );
    } catch (e) {
      print("Error marking alert as resolved: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: Could not resolve alert')),
      );
    }
  }

  void openMap(Map<String, dynamic> location) {
    // This would open maps app with the location
    final lat = location['lat'];
    final lng = location['lng'];
    launchUrl(
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng'));
  }

  List<Map<String, dynamic>> _filterAlerts(String filterType) {
    if (filterType == 'active') {
      return alerts.where((alert) => alert['resolved'] == false).toList();
    } else if (filterType == 'resolved') {
      return alerts.where((alert) => alert['resolved'] == true).toList();
    } else {
      return alerts;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Alerts & Emergency Logs'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'All'),
            Tab(text: 'Active'),
            Tab(text: 'Resolved'),
          ],
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAlertsList('all'),
                _buildAlertsList('active'),
                _buildAlertsList('resolved'),
              ],
            ),
    );
  }

  Widget _buildAlertsList(String filterType) {
    final filteredAlerts = _filterAlerts(filterType);

    if (filteredAlerts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text(
              filterType == 'active'
                  ? 'No active alerts'
                  : 'No alerts to display',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: filteredAlerts.length,
      itemBuilder: (context, index) {
        final alert = filteredAlerts[index];
        final timestamp =
            DateFormat('MMM d, h:mm a').format(alert['timestamp']);
        final isResolved = alert['resolved'] as bool;
        final severity = alert['severity'] as String;

        Color severityColor;
        switch (severity) {
          case 'high':
            severityColor = Colors.red;
            break;
          case 'medium':
            severityColor = Colors.orange;
            break;
          default:
            severityColor = Colors.blue;
        }

        return Card(
          margin: EdgeInsets.only(bottom: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: isResolved ? null : Colors.red.shade50,
          child: Column(
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: severityColor,
                  child: Icon(
                    _getAlertIcon(alert['type']),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                title: Text(
                  alert['type'],
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(timestamp),
                trailing: isResolved
                    ? Chip(
                        label: Text('Resolved'),
                        backgroundColor: Colors.green.shade100,
                      )
                    : OutlinedButton(
                        onPressed: () => markAsResolved(alert['id']),
                        child: Text('Resolve'),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert['description'],
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    InkWell(
                      onTap: () => openMap(alert['location']),
                      child: Row(
                        children: [
                          Icon(Icons.location_on, size: 18, color: Colors.blue),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              alert['location']['address'],
                              style: TextStyle(color: Colors.blue),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _getAlertIcon(String alertType) {
    switch (alertType) {
      case 'Fall Detection':
        return Icons.airline_seat_individual_suite;
      case 'SOS Button':
        return Icons.emergency;
      case 'Missed Medication':
        return Icons.medication;
      case 'Unusual Activity':
        return Icons.warning;
      case 'Health Warning':
        return Icons.favorite;
      default:
        return Icons.notification_important;
    }
  }
}