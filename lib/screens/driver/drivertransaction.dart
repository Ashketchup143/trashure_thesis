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
  String formatDate(Timestamp timestamp, String startTime, String endTime) {
    DateTime date = timestamp.toDate();
    DateFormat formatter = DateFormat('MM/dd/yyyy, EEEE');
    String formattedDate = formatter.format(date);
    return '$formattedDate, $startTime - $endTime';
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
              icon: const Icon(
                Icons.arrow_back,
                color: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context); // Go back to the previous screen
              },
            ),
            const Text(
              "Booking History",
              style: TextStyle(color: Colors.white),
            ),
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
                  padding: const EdgeInsets.only(left: 16),
                  child: Text(
                    'Driver ID: $id',
                    style: const TextStyle(
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
                        return const Center(child: CircularProgressIndicator());
                      }

                      var bookings = snapshot.data?.docs.where((doc) {
                        var status =
                            (doc['status'] ?? '').toString().toLowerCase();
                        return status == 'collected' || status == 'completed';
                      }).toList();

                      if (bookings == null || bookings.isEmpty) {
                        return const Center(
                            child: Text(
                                'No collected or completed bookings found.'));
                      }

                      return ListView.builder(
                        itemCount: bookings.length,
                        itemBuilder: (context, index) {
                          var bookingData =
                              bookings[index].data() as Map<String, dynamic>;
                          var bookingId = bookings[index].id;
                          var bookingDate = bookingData['date'] as Timestamp;
                          var bookingStatus =
                              bookingData['status'] ?? "Not set";
                          var overallPrice =
                              (bookingData['final_overall_price'] ?? 0.0)
                                  .toStringAsFixed(2);
                          var overallWeight =
                              (bookingData['final_overall_weight'] ?? 0.0)
                                  .toStringAsFixed(2);
                          var location = bookingData['location'] ?? 'Unknown';
                          var startTime =
                              bookingData['start_time'] ?? 'Unknown';
                          var endTime = bookingData['end_time'] ?? 'Unknown';
                          var calculatedPrice =
                              (bookingData['final_calculated_overall_price'] ??
                                      0.0)
                                  .toStringAsFixed(2);
                          var startingMileage =
                              (bookingData['starting_mileage'] ?? 0.0)
                                  .toStringAsFixed(2);
                          var endingMileage =
                              (bookingData['ending_mileage'] ?? 0.0)
                                  .toStringAsFixed(2);

                          return Card(
                            margin: const EdgeInsets.all(10),
                            color: Colors.lightGreen[100],
                            child: ListTile(
                              title: Text(
                                'Date: ${formatDate(bookingDate, startTime, endTime)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Location: $location'),
                                  Text('Booking ID: $bookingId'),
                                  Text('Status: $bookingStatus'),
                                  Text('Vehicle: ${bookingData['vehicle']}'),
                                  Text(
                                      'Vehicle ID: ${bookingData['vehicleId']}'),
                                  // Text('Overall Price: ₱$overallPrice'),
                                  Text('Calculated Price: ₱$calculatedPrice'),
                                  Text('Overall Weight: ${overallWeight} kg'),

                                  Text('Starting Mileage: $startingMileage km'),
                                  Text('Ending Mileage: $endingMileage km'),
                                  // Add StreamBuilder for user count
                                  StreamBuilder<QuerySnapshot>(
                                    stream: FirebaseFirestore.instance
                                        .collection('bookings')
                                        .doc(bookingId)
                                        .collection('users')
                                        .snapshots(),
                                    builder: (context, userSnapshot) {
                                      if (!userSnapshot.hasData) {
                                        return const Text(
                                          "Loading user count...",
                                          style: TextStyle(
                                              fontSize: 15, color: Colors.grey),
                                        );
                                      }
                                      // Count the number of users in the snapshot
                                      int userCount =
                                          userSnapshot.data?.docs.length ?? 0;
                                      return Text(
                                        "Number of Users: $userCount",
                                        style: const TextStyle(fontSize: 15),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.info),
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/drivertransactiondetails',
                                    arguments: {
                                      'bookingId': bookingId,
                                      'status': bookingStatus,
                                      'location': location,
                                      'vehicle': bookingData['vehicle'],
                                      'vehicleId': bookingData['vehicleId'],
                                      'driver_share':
                                          bookingData['driver_share'],
                                      'overall_price': overallPrice,
                                      'final_overall_price': overallPrice,
                                      'final_overall_weight': overallWeight,
                                      'overall_weight': overallWeight,
                                      'final_calculated_overall_price':
                                          calculatedPrice,
                                      'starting_mileage': startingMileage,
                                      'ending_mileage': endingMileage,
                                      'start_time': startTime,
                                      'end_time': endTime,
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
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
