import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // Import intl package for date formatting

class Driver extends StatefulWidget {
  const Driver({super.key});

  @override
  State<Driver> createState() => _DriverState();
}

class _DriverState extends State<Driver> {
  String name = 'Unknown Driver';
  String id = 'Unknown ID';
  bool isCollecting = false; // Flag to check if any booking is collecting

  @override
  void initState() {
    super.initState();
    _fetchDriverData(); // Fetch driver data when the page initializes
    _checkIfCollecting(); // Check if any booking has status "collecting"
  }

  // Function to fetch the logged-in driver’s information from Firebase
  Future<void> _fetchDriverData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String email = user.email ?? 'Unknown';

      // Query Firestore to get the driver’s information based on their email
      QuerySnapshot driverSnapshot = await FirebaseFirestore.instance
          .collection('employees')
          .where('email_address', isEqualTo: email)
          .get();

      if (driverSnapshot.docs.isNotEmpty) {
        var driverData =
            driverSnapshot.docs.first.data() as Map<String, dynamic>;
        setState(() {
          name = driverData['name'] ?? 'Unknown Driver';
          id = driverSnapshot.docs.first.id; // Get the document ID
        });
      }
    }
  }

  // Function to check if any booking already has the status "collecting"
  Future<void> _checkIfCollecting() async {
    QuerySnapshot collectingSnapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where('driverId', isEqualTo: id)
        .where('status', isEqualTo: 'collecting')
        .get();

    setState(() {
      isCollecting = collectingSnapshot.docs.isNotEmpty;
    });
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut(); // Sign out from Firebase
    Navigator.pushReplacementNamed(context, '/login'); // Navigate to login page
  }

  // Function to format Firestore Timestamp to "MM/dd/yyyy, DayOfWeek"
  String formatDate(Timestamp timestamp) {
    DateTime date =
        timestamp.toDate(); // Convert Firestore Timestamp to DateTime
    DateFormat formatter = DateFormat('MM/dd/yyyy'); // Define desired format
    String dayOfWeek =
        DateFormat('EEEE').format(date); // Get day of the week (e.g., Monday)
    return '${formatter.format(date)}, $dayOfWeek'; // Return formatted date and day of the week
  }

  // Function to update the status of the booking
  Future<void> _updateBookingStatus(String bookingId, String newStatus) async {
    await FirebaseFirestore.instance
        .collection('bookings')
        .doc(bookingId)
        .update({'status': newStatus}); // Update status to the new value
    _checkIfCollecting(); // Recheck if a booking is set to "collecting"
  }

  // Function to show a confirmation modal before changing status to "collecting"
  Future<void> _showCollectConfirmation(String bookingId) async {
    bool confirmed = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Collect Recyclables'),
          content: Text(
              'Are you going to collect the recyclables for this booking?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Cancel
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Confirm
              },
              child: Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _updateBookingStatus(bookingId, 'collecting');
    }
  }

  // Function to show a modal when a booking is already in progress
  void _showErrorModal() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Booking in Progress'),
          content: Text('You still have a booking in progress.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the modal
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.green,
        title: Row(
          children: [
            IconButton(
              icon: Icon(
                Icons.logout,
                color: Colors.white,
              ),
              onPressed: _logout, // Call the logout function
            ),
            Text(
              "Booking",
              style: TextStyle(color: Colors.white),
            ), // Display the driver's name in the app bar
          ],
        ),
      ),
      body: Container(
        child: Center(
          child: Container(
            width: MediaQuery.of(context).size.width * .95,
            height: MediaQuery.of(context).size.height * .90,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.green, width: 3),
              color: Colors.white, // Background color of the inner container
              borderRadius: BorderRadius.circular(20), // Rounded corners
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start, // Align content to the left
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Driver: $name', // Header for Booking data
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Text(
                    'Driver ID: $id', // Display the driver's ID
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('bookings')
                        .where('driverId', isEqualTo: id)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Center(child: CircularProgressIndicator());
                      }

                      var bookings = snapshot.data?.docs ?? [];

                      if (bookings.isEmpty) {
                        return Center(child: Text('No bookings found.'));
                      }

                      return ListView.builder(
                        itemCount: bookings.length,
                        itemBuilder: (context, index) {
                          var bookingData =
                              bookings[index].data() as Map<String, dynamic>;
                          var bookingId = bookings[index].id;
                          var bookingDate = bookingData['date'] as Timestamp;
                          var bookingStatus =
                              bookingData['status'] ?? 'Unknown';
                          var overallPrice =
                              bookingData['overall_price'] ?? 'Not set';
                          var overallWeight =
                              bookingData['overall_weight'] ?? 'Not set';

                          return Card(
                            margin: const EdgeInsets.all(10),
                            child: ListTile(
                              title: Text(
                                'Date: ${formatDate(bookingDate)}',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Booking ID: $bookingId'),
                                  Text('Status: $bookingStatus'),
                                  Text('Vehicle: ${bookingData['vehicle']}'),
                                  Text(
                                      'Vehicle ID: ${bookingData['vehicleId']}'),
                                  Text('Overall Price: ₱${overallPrice}'),
                                  Text('Overall Weight: ${overallWeight} kg'),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (bookingStatus != 'collecting')
                                    ElevatedButton(
                                      onPressed: isCollecting
                                          ? _showErrorModal // Show modal if another booking is collecting
                                          : () {
                                              _showCollectConfirmation(
                                                  bookingId);
                                            },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                      ),
                                      child: Text('Collect'),
                                    )
                                  else
                                    Row(
                                      children: [
                                        Text(
                                          'Collecting',
                                          style: TextStyle(
                                            color: Colors.orange,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        ElevatedButton(
                                          onPressed: () async {
                                            await _updateBookingStatus(
                                                bookingId, 'pending');
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.redAccent,
                                          ),
                                          child: Text('Set Pending'),
                                        ),
                                      ],
                                    ),
                                  IconButton(
                                    icon: Icon(Icons.info),
                                    onPressed: () {
                                      Navigator.pushNamed(
                                        context,
                                        '/driverbookingdetails',
                                        arguments: {
                                          'bookingId': bookingId,
                                          'status': bookingData['status'],
                                          'vehicle': bookingData['vehicle'],
                                          'vehicleId': bookingData['vehicleId'],
                                          'overall_price':
                                              bookingData['overall_price'],
                                          'overall_weight':
                                              bookingData['overall_weight'],
                                          'date': bookingData['date'],
                                        },
                                      );
                                    },
                                  ),
                                ],
                              ),
                              onTap: () {
                                print('Booking tapped');
                              },
                            ),
                          );
                        },
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
}
