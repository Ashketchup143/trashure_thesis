import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class DriverProfileScreen extends StatefulWidget {
  const DriverProfileScreen({super.key});

  @override
  _DriverProfileScreenState createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  String name = 'Loading...';
  String email = 'Loading...';
  String phone = 'Loading...';
  String address = 'Loading...';
  String birthDate = 'Loading...';
  String status = 'Loading...';
  String id = 'Loading...';
  double totalDriverShare = 0.0;
  List<Map<String, dynamic>> bookingsList = [];

  final TextEditingController addressController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchDriverData();
  }

  Future<void> _fetchDriverData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      email = user.email ?? 'Unknown Email';

      QuerySnapshot driverSnapshot = await FirebaseFirestore.instance
          .collection('employees')
          .where('email_address', isEqualTo: email)
          .get();

      if (driverSnapshot.docs.isNotEmpty) {
        var driverData =
            driverSnapshot.docs.first.data() as Map<String, dynamic>;
        id = driverSnapshot.docs.first.id;

        setState(() {
          name = driverData['name'] ?? 'Unknown Driver';
          phone = driverData['contact_number'] ?? 'No phone number';
          address = driverData['address'] ?? 'No address provided';
          birthDate = driverData['birth_date'] ?? 'No birth date provided';
          status = driverData['status'] ?? 'Unknown';
          phoneController.text = phone;
          addressController.text = address;
        });

        // Fetch the bookings associated with the driver
        await _fetchDriverBookings();
      }
    }
  }

  Future<void> _fetchDriverBookings() async {
    try {
      QuerySnapshot bookingsSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('driverId', isEqualTo: id)
          .get();

      double totalShare = 0.0;
      List<Map<String, dynamic>> fetchedBookings = [];

      for (var doc in bookingsSnapshot.docs) {
        var bookingData = doc.data() as Map<String, dynamic>;
        double driverShare = (bookingData['driver_share'] ?? 0.0).toDouble();
        totalShare += driverShare;

        Timestamp timestamp = bookingData['date'] ?? Timestamp.now();
        String formattedDate =
            DateFormat('MM/dd/yyyy, EEEE').format(timestamp.toDate());

        fetchedBookings.add({
          'bookingId': doc.id,
          'date': formattedDate,
          'status': bookingData['status'] ?? 'Unknown',
          'vehicle': bookingData['vehicle'] ?? 'N/A',
          'overall_weight': bookingData['overall_weight'] ?? 'Not set',
          'overall_price': bookingData['overall_price'] ?? 'Not set',
          'driver_share': driverShare,
        });
      }

      fetchedBookings.sort((a, b) {
        DateTime dateA = DateFormat('MM/dd/yyyy, EEEE').parse(a['date']);
        DateTime dateB = DateFormat('MM/dd/yyyy, EEEE').parse(b['date']);
        return dateB.compareTo(dateA);
      });

      setState(() {
        totalDriverShare = totalShare;
        bookingsList = fetchedBookings;
      });
    } catch (e) {
      print('Error fetching bookings: $e');
    }
  }

  Future<void> _updateDriverInfo() async {
    try {
      await FirebaseFirestore.instance.collection('employees').doc(id).update({
        'contact_number': phoneController.text,
        'address': addressController.text,
      });
      setState(() {
        phone = phoneController.text;
        address = addressController.text;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully.')),
      );
    } catch (e) {
      print('Error updating profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update profile.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        backgroundColor: Colors.green,
        title: const Text('Driver Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              _showEditProfileDialog();
            },
          ),
        ],
      ),
      body: Container(
        child: Center(
          child: Container(
            width: MediaQuery.of(context).size.width * .95,
            height: MediaQuery.of(context).size.height * .90,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.green, width: 3),
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Driver: $name',
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: Text(
                    'Email: $email',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, top: 8),
                  child: Text(
                    'Phone: $phone',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, top: 8),
                  child: Text(
                    'Address: $address',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, top: 8),
                  child: Text(
                    'Birth Date: $birthDate',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, top: 8),
                  child: Text(
                    'Status: $status',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, top: 8),
                  child: Text(
                    'Total Driver Share: ₱${totalDriverShare.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Bookings:',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: bookingsList.isEmpty
                      ? const Center(child: Text('No bookings found.'))
                      : ListView.builder(
                          itemCount: bookingsList.length,
                          itemBuilder: (context, index) {
                            var booking = bookingsList[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  vertical: 8.0, horizontal: 16.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15.0),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Date: ${booking['date']}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text('Status: ${booking['status']}'),
                                    Text('Vehicle: ${booking['vehicle']}'),
                                    Text(
                                        'Overall Weight: ${booking['overall_weight'].toStringAsFixed(2)} kg'),
                                    Text(
                                        'Overall Price: ₱${booking['overall_price'].toStringAsFixed(2)}'),
                                    Text(
                                        'Driver Share: ₱${booking['driver_share'].toStringAsFixed(2)}'),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditProfileDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Contact Number'),
              ),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _updateDriverInfo();
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
