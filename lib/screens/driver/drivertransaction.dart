import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // Import intl package for date formatting

class DriverTransactions extends StatefulWidget {
  const DriverTransactions({super.key});

  @override
  State<DriverTransactions> createState() => _DriverTransactionsState();
}

class _DriverTransactionsState extends State<DriverTransactions> {
  String name = 'Unknown Driver';
  String id = 'Unknown ID';

  @override
  void initState() {
    super.initState();
    _fetchDriverData(); // Fetch driver data when the page initializes
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

  // Function to format Firestore Timestamp to "MM/dd/yyyy, DayOfWeek"
  String formatDate(Timestamp timestamp) {
    DateTime date =
        timestamp.toDate(); // Convert Firestore Timestamp to DateTime
    DateFormat formatter = DateFormat('MM/dd/yyyy'); // Define desired format
    String dayOfWeek =
        DateFormat('EEEE').format(date); // Get day of the week (e.g., Monday)
    return '${formatter.format(date)}, $dayOfWeek'; // Return formatted date and day of the week
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
                Icons.arrow_back,
                color: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context); // Go back to the previous screen
              },
            ),
            Text(
              "Booking History",
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
                        .where('status', isEqualTo: 'collected')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Center(child: CircularProgressIndicator());
                      }

                      var bookings = snapshot.data?.docs ?? [];

                      if (bookings.isEmpty) {
                        return Center(
                            child: Text('No collected bookings found.'));
                      }

                      return ListView.builder(
                        itemCount: bookings.length,
                        itemBuilder: (context, index) {
                          var bookingData =
                              bookings[index].data() as Map<String, dynamic>;
                          var bookingId = bookings[index].id;
                          var bookingDate = bookingData['date'] as Timestamp;
                          var overallPrice =
                              bookingData['overall_price'] ?? 'Not set';
                          var overallWeight =
                              bookingData['overall_weight'] ?? 'Not set';

                          return Card(
                            margin: const EdgeInsets.all(10),
                            color: Colors.lightGreen[100],
                            child: ListTile(
                              title: Text(
                                'Date: ${formatDate(bookingDate)}',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Booking ID: $bookingId'),
                                  Text('Vehicle: ${bookingData['vehicle']}'),
                                  Text(
                                      'Vehicle ID: ${bookingData['vehicleId']}'),
                                  Text('Overall Price: ₱${overallPrice}'),
                                  Text('Overall Weight: ${overallWeight} kg'),
                                ],
                              ),
                              trailing: IconButton(
                                icon: Icon(Icons.info),
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/drivertransactiondetails',
                                    arguments: {
                                      'bookingId': bookingId,
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
