import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:trashure_thesis/screens/map.dart';

class DriverBookingDetails extends StatefulWidget {
  @override
  _DriverBookingDetailsState createState() => _DriverBookingDetailsState();
}

class _DriverBookingDetailsState extends State<DriverBookingDetails> {
  Map<String, bool> isEditingWeight =
      {}; // Track whether the user is editing the weight for each recyclable
  Map<String, TextEditingController> weightControllers =
      {}; // Store controllers for each weight input
  Map<String, double> updatedWeights = {}; // Track updated weights locally

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
        title: Row(
          children: [
            Text(
              "Booking Details",
              style: TextStyle(color: Colors.white),
            ),
            Spacer(),
            IconButton(
              icon: Icon(Icons.map), // Add the map icon
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => Maps(
                          bookingId: bookingId)), // Pushing the Maps widget
                );
              },
            ),
          ],
        ),
        backgroundColor: Colors.green,
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
                Text('Total Price: ₱${overallPrice.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 18)),
                Text('Total Weight: ${overallWeight.toStringAsFixed(2)} kg',
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
                                      .doc(users[userIndex].id)
                                      .collection('recyclables')
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

                                        // Dynamically calculate item price
                                        double itemPrice = weight * price;

                                        String recyclableId =
                                            recyclables[recIndex].id;

                                        // Initialize weight controller if not yet initialized
                                        if (!weightControllers
                                            .containsKey(recyclableId)) {
                                          weightControllers[recyclableId] =
                                              TextEditingController(
                                                  text: weight.toString());
                                          updatedWeights[recyclableId] = weight;
                                        }

                                        // Track if the user is editing this specific recyclable's weight
                                        bool isEditing =
                                            isEditingWeight[recyclableId] ??
                                                false;

                                        return Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text('Type: $type'),
                                              Row(
                                                children: [
                                                  isEditing
                                                      ? Expanded(
                                                          child: TextFormField(
                                                            controller:
                                                                weightControllers[
                                                                    recyclableId],
                                                            decoration:
                                                                InputDecoration(
                                                              labelText:
                                                                  'Weight (kg)',
                                                              border:
                                                                  OutlineInputBorder(),
                                                            ),
                                                            keyboardType:
                                                                TextInputType
                                                                    .number,
                                                          ),
                                                        )
                                                      : Text(
                                                          'Weight: ${updatedWeights[recyclableId]!.toStringAsFixed(2)} kg'),
                                                  IconButton(
                                                    icon: Icon(isEditing
                                                        ? Icons.check
                                                        : Icons.edit),
                                                    onPressed: () {
                                                      setState(() {
                                                        if (isEditing) {
                                                          // Save the edited value locally
                                                          double newWeight =
                                                              double.tryParse(
                                                                      weightControllers[
                                                                              recyclableId]!
                                                                          .text) ??
                                                                  weight;

                                                          updatedWeights[
                                                                  recyclableId] =
                                                              newWeight; // Update weight locally

                                                          // Update item price dynamically
                                                          itemPrice =
                                                              newWeight * price;
                                                        }
                                                        isEditingWeight[
                                                                recyclableId] =
                                                            !isEditing;
                                                      });
                                                    },
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 8),
                                              Text('Price: ₱$price'),
                                              Text(
                                                  'Item Price: ₱${(updatedWeights[recyclableId]! * price).toStringAsFixed(2)}'),
                                              Divider(),
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                                ElevatedButton(
                                  onPressed: () async {
                                    // Mark the user as collected and update recyclables' final_weight and final_item_price
                                    await _markAsCollected(
                                        bookingId, users[userIndex].id);
                                  },
                                  child: Text('Collected'),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green),
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

  // Function to mark a user's recyclables as collected
  Future<void> _markAsCollected(String bookingId, String userId) async {
    var recyclablesSnapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .doc(bookingId)
        .collection('users')
        .doc(userId)
        .collection('recyclables')
        .get();

    var batch = FirebaseFirestore.instance.batch();

    for (var rec in recyclablesSnapshot.docs) {
      var recyclableData = rec.data() as Map<String, dynamic>;
      String recyclableId = rec.id;

      // Use the locally updated weight or the original weight if not edited
      double finalWeight =
          updatedWeights[recyclableId] ?? recyclableData['weight'];
      double price = recyclableData['price'] ?? 0.0;
      double finalItemPrice = finalWeight * price;

      // Update the final_weight and final_item_price fields in Firestore
      batch.update(
        rec.reference,
        {
          'final_weight': finalWeight,
          'final_item_price': finalItemPrice,
        },
      );
    }

    // Update the user's status to "collected"
    var userRef = FirebaseFirestore.instance
        .collection('bookings')
        .doc(bookingId)
        .collection('users')
        .doc(userId);

    batch.update(userRef, {'status': 'collected'});

    await batch.commit();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('User marked as collected')),
    );
  }
}
