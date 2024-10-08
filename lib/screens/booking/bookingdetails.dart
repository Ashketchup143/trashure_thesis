import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trashure_thesis/screens/map.dart';

class BookingDetails extends StatelessWidget {
  final String bookingId;
  final Map<String, dynamic> bookingData;

  BookingDetails({required this.bookingId, required this.bookingData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Colors.green,
        title: Row(
          children: [
            Text(
              'Booking Details',
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
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display booking fields
            Text("Booking ID: $bookingId"),
            Text("Date: ${bookingData['date']?.toDate() ?? 'No Date'}"),
            Text("Driver: ${bookingData['driver'] ?? 'No Driver Assigned'}"),
            Text("Vehicle: ${bookingData['vehicle'] ?? 'No Vehicle Assigned'}"),
            Text("Status: ${bookingData['status'] ?? 'No Status'}"),
            SizedBox(height: 20),

            // Fetch and display user data with recyclables
            Center(
              child: Expanded(
                child: Container(
                  height: MediaQuery.of(context).size.height * .5,
                  width: MediaQuery.of(context).size.width * .95,
                  decoration: BoxDecoration(border: Border.all()),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('bookings')
                        .doc(bookingId)
                        .collection('users')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Center(child: CircularProgressIndicator());
                      }

                      var users = snapshot.data?.docs ?? [];
                      if (users.isEmpty) {
                        return Center(
                            child:
                                Text('No users associated with this booking.'));
                      }

                      double overallTotal = 0; // Initialize overall total

                      // Iterate over all users to compute the overall total
                      return FutureBuilder(
                        future: _calculateOverallTotal(users),
                        builder: (context, totalSnapshot) {
                          if (!totalSnapshot.hasData) {
                            return Center(child: CircularProgressIndicator());
                          }

                          overallTotal = totalSnapshot.data ?? 0;

                          return Column(
                            children: [
                              Expanded(
                                child: ListView.builder(
                                  itemCount: users.length,
                                  itemBuilder: (context, index) {
                                    var userDoc = users[index];
                                    var userData =
                                        userDoc.data() as Map<String, dynamic>;

                                    return StreamBuilder<QuerySnapshot>(
                                      stream: FirebaseFirestore.instance
                                          .collection('bookings')
                                          .doc(bookingId)
                                          .collection('users')
                                          .doc(userDoc.id)
                                          .collection('recyclables')
                                          .snapshots(),
                                      builder: (context, recyclablesSnapshot) {
                                        if (!recyclablesSnapshot.hasData) {
                                          return Center(
                                              child:
                                                  CircularProgressIndicator());
                                        }

                                        var recyclables =
                                            recyclablesSnapshot.data?.docs ??
                                                [];
                                        double userTotal = 0;

                                        // Calculate the user total from recyclables
                                        if (recyclables.isNotEmpty) {
                                          recyclables.forEach((recyclableDoc) {
                                            var recyclableData = recyclableDoc
                                                .data() as Map<String, dynamic>;
                                            double weight =
                                                recyclableData['weight'] ?? 0;
                                            double price =
                                                recyclableData['price'] ?? 0;
                                            double itemTotal = weight * price;

                                            userTotal += itemTotal;
                                          });
                                        }

                                        return ExpansionTile(
                                          title: Text(
                                            "UID: ${userData['uid'] ?? 'No UID'} | Name: ${userData['name'] ?? 'No Name'} | Email: ${userData['email'] ?? 'No Email'} | Address: ${userData['address'] ?? 'No Address'} | Number: ${userData['number'] ?? 'No Number'}",
                                          ),
                                          subtitle: Text(
                                              "Total for user: ₱${userTotal.toStringAsFixed(2)}"),
                                          children: [
                                            Column(
                                              children: recyclables
                                                  .map((recyclableDoc) {
                                                var recyclableData =
                                                    recyclableDoc.data()
                                                        as Map<String, dynamic>;

                                                double weight =
                                                    recyclableData['weight'] ??
                                                        0;
                                                double price =
                                                    recyclableData['price'] ??
                                                        0;
                                                double itemTotal = weight *
                                                    price; // Calculate item total

                                                return ListTile(
                                                  title: Text(
                                                      "Type: ${recyclableData['type'] ?? 'No Type'}"),
                                                  subtitle: Text(
                                                      "Weight: $weight kg, Price: ₱${price.toStringAsFixed(2)}, Item Total: ₱${itemTotal.toStringAsFixed(2)}"),
                                                  trailing: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      IconButton(
                                                        icon: Icon(Icons.edit),
                                                        onPressed: () {
                                                          // Edit recyclable
                                                          showEditRecyclableDialog(
                                                              context,
                                                              bookingId,
                                                              userDoc.id,
                                                              recyclableDoc.id,
                                                              recyclableData);
                                                        },
                                                      ),
                                                      IconButton(
                                                        icon:
                                                            Icon(Icons.delete),
                                                        onPressed: () {
                                                          // Delete recyclable
                                                          FirebaseFirestore
                                                              .instance
                                                              .collection(
                                                                  'bookings')
                                                              .doc(bookingId)
                                                              .collection(
                                                                  'users')
                                                              .doc(userDoc.id)
                                                              .collection(
                                                                  'recyclables')
                                                              .doc(recyclableDoc
                                                                  .id)
                                                              .delete();
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }).toList(),
                                            ),
                                            ElevatedButton(
                                              onPressed: () {
                                                // Add new recyclable
                                                showAddRecyclableDialog(context,
                                                    bookingId, userDoc.id);
                                              },
                                              child: Text("Add Recyclable"),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                              // Display overall total for booking
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  "Overall Total for Booking: ₱${overallTotal.toStringAsFixed(2)}",
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<double> _calculateOverallTotal(
      List<QueryDocumentSnapshot> users) async {
    double overallTotal = 0;
    for (var userDoc in users) {
      var recyclablesSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .collection('users')
          .doc(userDoc.id)
          .collection('recyclables')
          .get();

      for (var recyclableDoc in recyclablesSnapshot.docs) {
        var recyclableData = recyclableDoc.data() as Map<String, dynamic>;
        double weight = recyclableData['weight'] ?? 0;
        double price = recyclableData['price'] ?? 0;
        double itemTotal = weight * price;

        overallTotal += itemTotal;
      }
    }

    return overallTotal;
  }

  void showEditRecyclableDialog(BuildContext context, String bookingId,
      String userId, String recyclableId, Map<String, dynamic> recyclableData) {
    final TextEditingController typeController =
        TextEditingController(text: recyclableData['type']);
    final TextEditingController weightController =
        TextEditingController(text: recyclableData['weight'].toString());
    final TextEditingController priceController =
        TextEditingController(text: recyclableData['price'].toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Recyclable'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: typeController,
              decoration: InputDecoration(labelText: 'Type'),
            ),
            TextField(
              controller: weightController,
              decoration: InputDecoration(labelText: 'Weight (kg)'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: priceController,
              decoration: InputDecoration(labelText: 'Price'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              // Update recyclable
              FirebaseFirestore.instance
                  .collection('bookings')
                  .doc(bookingId)
                  .collection('users')
                  .doc(userId)
                  .collection('recyclables')
                  .doc(recyclableId)
                  .update({
                'type': typeController.text,
                'weight': double.tryParse(weightController.text) ?? 0.0,
                'price': double.tryParse(priceController.text) ?? 0.0,
              });
              Navigator.of(context).pop();
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void showAddRecyclableDialog(
      BuildContext context, String bookingId, String userId) {
    final TextEditingController typeController = TextEditingController();
    final TextEditingController weightController = TextEditingController();
    final TextEditingController priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Recyclable'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: typeController,
              decoration: InputDecoration(labelText: 'Type'),
            ),
            TextField(
              controller: weightController,
              decoration: InputDecoration(labelText: 'Weight (kg)'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: priceController,
              decoration: InputDecoration(labelText: 'Price'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              // Add new recyclable
              FirebaseFirestore.instance
                  .collection('bookings')
                  .doc(bookingId)
                  .collection('users')
                  .doc(userId)
                  .collection('recyclables')
                  .add({
                'type': typeController.text,
                'weight': double.tryParse(weightController.text) ?? 0.0,
                'price': double.tryParse(priceController.text) ?? 0.0,
              });
              Navigator.of(context).pop();
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }
}
