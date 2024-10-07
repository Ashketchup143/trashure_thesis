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

  // Function to update the status of the booking to "collecting"
  Future<void> _updateBookingStatus(String bookingId) async {
    await FirebaseFirestore.instance
        .collection('bookings')
        .doc(bookingId)
        .update({'status': 'collecting'}); // Update status to "collecting"
  }

  @override
  Widget build(BuildContext context) {
    // Retrieve the passed arguments and handle null safely
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    String name = args != null ? args['name'] : 'Unknown Driver';
    String id = args != null ? args['id'] : 'Unknown ID';

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
              name,
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
                    'Booking', // Header for Booking data
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
                        .where('driverId',
                            isEqualTo: id) // Changed to 'driverId'
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
                                  Text('Overall Price: \$${overallPrice}'),
                                  Text('Overall Weight: ${overallWeight} kg'),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  bookingStatus != 'collecting'
                                      ? ElevatedButton(
                                          onPressed: () async {
                                            await _updateBookingStatus(
                                                bookingId);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors
                                                .green, // Changed from `primary`
                                          ),
                                          child: Text('Collect'),
                                        )
                                      : Text(
                                          'Collecting',
                                          style: TextStyle(
                                            color: Colors.orange,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                  IconButton(
                                    icon: Icon(Icons.info),
                                    onPressed: () {
                                      // Ensure that all necessary fields are passed when navigating
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
                                          'date': bookingData[
                                              'date'], // Ensure this is a Timestamp
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
