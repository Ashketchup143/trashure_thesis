import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:trashure_thesis/screens/map.dart'; // Import intl package for date formatting

class DriverBookingDetails extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    // Safeguarding the booking ID, if null, replace with 'Unknown'
    String bookingId = args?['bookingId'] ?? 'Unknown';
    String status = args?['status'] ?? 'Unknown';
    String vehicle = args?['vehicle'] ?? 'Unknown';
    String vehicleId = args?['vehicleId'] ?? 'Unknown';

    // Handle overall_price and overall_weight as numbers
    double overallPrice = args?['overall_price']?.toDouble() ?? 0.0;
    double overallWeight = args?['overall_weight']?.toDouble() ?? 0.0;

    Timestamp? timestamp = args?['date'];

    // Convert Timestamp to DateTime
    DateTime? date = timestamp?.toDate();

    // Format the date using intl package
    String formattedDate = date != null
        ? DateFormat('MM/dd/yyyy, EEEE')
            .format(date) // Example: 10/06/2024, Sunday
        : 'Unknown Date';

    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          "Booking Details",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: Icon(
              Icons.map,
              color: Colors.white,
            ), // Add the map icon
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        Maps(bookingId: bookingId)), // Pushing the Maps widget
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * .95,
          height: MediaQuery.of(context).size.height * .90,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.green, width: 3),
            color: Colors.white, // Background color of the inner container
            borderRadius: BorderRadius.circular(20), // Rounded corners
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Display the booking details header
                Text(
                  'Booking Details',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                // Display basic booking information
                Text('Booking ID: $bookingId', style: TextStyle(fontSize: 18)),
                Text('Status: $status', style: TextStyle(fontSize: 18)),
                Text('Vehicle: $vehicle', style: TextStyle(fontSize: 18)),
                Text('Vehicle ID: $vehicleId', style: TextStyle(fontSize: 18)),
                Text('Est. Total Price: ₱${overallPrice.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 18)),
                Text(
                    'Est. Total Weight: ${overallWeight.toStringAsFixed(2)} kg',
                    style: TextStyle(fontSize: 18)),
                Text('Date: $formattedDate', style: TextStyle(fontSize: 18)),
                SizedBox(height: 20),

                // Display the users list and recyclables inside an expanded widget
                Expanded(
                  child: StreamBuilder(
                    stream: FirebaseFirestore.instance
                        .collection('bookings')
                        .doc(bookingId)
                        .collection('users')
                        .snapshots(),
                    builder: (context, userSnapshot) {
                      if (!userSnapshot.hasData) {
                        return Center(child: CircularProgressIndicator());
                      }

                      var users = userSnapshot.data?.docs ?? [];

                      if (users.isEmpty) {
                        return Center(child: Text('No users found.'));
                      }

                      return ListView.builder(
                        itemCount: users.length,
                        itemBuilder: (context, userIndex) {
                          var userData =
                              users[userIndex].data() as Map<String, dynamic>;

                          String firstName = userData['firstName'] ?? 'Unknown';
                          String lastName = userData['lastName'] ?? 'Unknown';
                          String address = userData['address'] ?? 'Unknown';
                          String contact = userData['contact'] ?? 'Unknown';
                          String email = userData['email'] ?? 'Unknown';
                          double totalPrice = userData['total_price'] ?? 0.0;

                          return Card(
                            margin: const EdgeInsets.all(10),
                            child: ExpansionTile(
                              title: Text(
                                '$firstName $lastName',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                  'Address: $address, Contact: $contact\nEmail: $email\nTotal Price: ₱$totalPrice'),
                              children: [
                                StreamBuilder(
                                  stream: FirebaseFirestore.instance
                                      .collection('bookings')
                                      .doc(bookingId)
                                      .collection('users')
                                      .doc(users[userIndex]
                                          .id) // Correct user document
                                      .collection(
                                          'recyclables') // Subcollection
                                      .snapshots(),
                                  builder: (context, recyclableSnapshot) {
                                    if (!recyclableSnapshot.hasData) {
                                      return Center(
                                          child: CircularProgressIndicator());
                                    }

                                    var recyclables =
                                        recyclableSnapshot.data?.docs ?? [];

                                    return ListView.builder(
                                      itemCount: recyclables.length,
                                      shrinkWrap: true,
                                      physics:
                                          NeverScrollableScrollPhysics(), // Prevent nested scrolling
                                      itemBuilder: (context, recIndex) {
                                        var recyclableData =
                                            recyclables[recIndex].data()
                                                as Map<String, dynamic>;

                                        String type =
                                            recyclableData['type'] ?? 'Unknown';
                                        double weight =
                                            recyclableData['weight'] ?? 0.0;
                                        double price =
                                            recyclableData['price'] ?? 0.0;
                                        double itemPrice =
                                            recyclableData['item_price'] ?? 0.0;

                                        return Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text('Type: $type'),
                                              Text('Weight: $weight kg'),
                                              Text('Price: ₱$price'),
                                              Text('Item Price: ₱$itemPrice'),
                                              Divider(),
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ],
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
