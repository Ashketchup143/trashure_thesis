import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:trashure_thesis/screens/map.dart';

class BookingDetails extends StatelessWidget {
  final String bookingId;
  final Map<String, dynamic> bookingData;

  BookingDetails({required this.bookingId, required this.bookingData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.green,
        title: Row(
          children: [
            const Text(
              'Booking Details',
              style: TextStyle(color: Colors.white),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.map),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => Maps(bookingId: bookingId)),
                );
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Booking ID: $bookingId"),
            Text("Date: ${_formatDateTime(bookingData['date'])}"),
            Text(
                "Location: ${bookingData['location'] ?? 'No Location Assigned'}"),
            Text(
                "Time: ${_formatTime(bookingData['start_time'], bookingData['end_time'])}"),
            Text("Driver: ${bookingData['driver'] ?? 'No Driver Assigned'}"),
            Text("Vehicle: ${bookingData['vehicle'] ?? 'No Vehicle Assigned'}"),
            Text("Status: ${bookingData['status'] ?? 'No Status'}"),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                decoration: BoxDecoration(border: Border.all()),
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('bookings')
                      .doc(bookingId)
                      .collection('users')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    var users = snapshot.data?.docs ?? [];
                    if (users.isEmpty) {
                      return const Center(
                          child:
                              Text('No users associated with this booking.'));
                    }

                    return Column(
                      children: [
                        _buildTitlesRow(),
                        Expanded(
                          child: ListView.builder(
                            itemCount: users.length,
                            itemBuilder: (context, index) {
                              var userDoc = users[index];
                              var userData =
                                  userDoc.data() as Map<String, dynamic>;

                              return _buildUserTile(
                                  context, bookingId, userDoc.id, userData);
                            },
                          ),
                        ),
                        _buildOverallTotals(bookingId),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserTile(BuildContext context, String bookingId, String userId,
      Map<String, dynamic> userData) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .collection('users')
          .doc(userId)
          .collection('recyclables')
          .snapshots(),
      builder: (context, recyclablesSnapshot) {
        if (!recyclablesSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var recyclables = recyclablesSnapshot.data?.docs ?? [];
        double userTotalWeight = recyclables.fold(0.0, (sum, doc) {
          var data = doc.data() as Map<String, dynamic>;
          double weight = bookingData['status'] == 'collected' ||
                  bookingData['status'] == 'completed'
              ? data['final_weight'] ?? 0
              : data['weight'] ?? 0;
          return sum + weight;
        });

        double userTotalPrice = recyclables.fold(0.0, (sum, doc) {
          var data = doc.data() as Map<String, dynamic>;
          double itemPrice = bookingData['status'] == 'collected' ||
                  bookingData['status'] == 'completed'
              ? data['final_item_price'] ?? 0
              : data['item_price'] ?? 0;
          return sum + itemPrice;
        });

        return ExpansionTile(
          title: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                    "${userData['firstName'] ?? 'No First Name'} ${userData['lastName'] ?? 'No Last Name'}"),
              ),
              Expanded(
                flex: 3,
                child: Text(userData['email'] ?? 'No Email'),
              ),
              Expanded(
                flex: 3,
                child: Text(userData['address'] ?? 'No Address'),
              ),
              Expanded(
                flex: 2,
                child: Center(
                  child: Text("${userTotalWeight.toStringAsFixed(2)} kg"),
                ),
              ),
              Expanded(
                flex: 2,
                child: Center(
                  child: Text("₱${userTotalPrice.toStringAsFixed(2)}"),
                ),
              ),
            ],
          ),
          children: recyclables.map((recyclableDoc) {
            var recyclableData = recyclableDoc.data() as Map<String, dynamic>;
            double weight = bookingData['status'] == 'collected' ||
                    bookingData['status'] == 'completed'
                ? recyclableData['final_weight'] ?? 0
                : recyclableData['weight'] ?? 0;
            double price = recyclableData['price'] ?? 0;
            double itemPrice = bookingData['status'] == 'collected' ||
                    bookingData['status'] == 'completed'
                ? recyclableData['final_item_price'] ?? 0
                : recyclableData['item_price'] ?? 0;

            return ListTile(
              title: Text("Type: ${recyclableData['type'] ?? 'No Type'}"),
              subtitle: Text(
                  "Weight: $weight kg, Price: ₱${price.toStringAsFixed(2)}, Item Total: ₱${itemPrice.toStringAsFixed(2)}"),
              trailing: bookingData['status'] == 'collected' ||
                      bookingData['status'] == 'completed'
                  ? null
                  : _buildRecyclableActions(context, bookingId, userId,
                      recyclableDoc.id, recyclableData),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildOverallTotals(String bookingId) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var bookingData = snapshot.data?.data() as Map<String, dynamic>;
        double overallPrice = bookingData['status'] == 'collected' ||
                bookingData['status'] == 'completed'
            ? bookingData['final_overall_price'] ?? 0.0
            : bookingData['overall_price'] ?? 0.0;
        double overallWeight = bookingData['status'] == 'collected' ||
                bookingData['status'] == 'completed'
            ? bookingData['final_overall_weight'] ?? 0.0
            : bookingData['overall_weight'] ?? 0.0;

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Text(
                "Overall Weight for Booking: ${overallWeight.toStringAsFixed(2)} kg",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "Overall Total Price for Booking: ₱${overallPrice.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTitlesRow() {
    return Row(
      children: [
        title('Name', 3),
        title('Email', 3),
        title('Address', 3),
        title('Weight (kg)', 2),
        title('Total (₱)', 2),
      ],
    );
  }

  Expanded title(String title, int flex) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: const BoxDecoration(
          border: Border(
            right: BorderSide(color: Colors.black),
            bottom: BorderSide(color: Colors.black),
          ),
        ),
        child: Center(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  String _formatDateTime(Timestamp? timestamp) {
    if (timestamp == null) return 'No Date';
    DateTime dateTime = timestamp.toDate();
    return DateFormat('MMMM d, yyyy (EEEE)').format(dateTime);
  }

  String _formatTime(String? startTime, String? endTime) {
    if (startTime == null || endTime == null) return 'No Time';
    return "$startTime - $endTime";
  }

  Widget _buildRecyclableActions(BuildContext context, String bookingId,
      String userId, String recyclableId, Map<String, dynamic> recyclableData) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () {
            showEditRecyclableDialog(
                context, bookingId, userId, recyclableId, recyclableData);
          },
        ),
        IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () {
            FirebaseFirestore.instance
                .collection('bookings')
                .doc(bookingId)
                .collection('users')
                .doc(userId)
                .collection('recyclables')
                .doc(recyclableId)
                .delete();
          },
        ),
      ],
    );
  }

  void showEditRecyclableDialog(BuildContext context, String bookingId,
      String userId, String recyclableId, Map<String, dynamic> recyclableData) {
    final TextEditingController weightController =
        TextEditingController(text: recyclableData['weight'].toString());
    final TextEditingController priceController =
        TextEditingController(text: recyclableData['price'].toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Recyclable'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: weightController,
              decoration: const InputDecoration(labelText: 'Weight (kg)'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(labelText: 'Price'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              double weight = double.tryParse(weightController.text) ?? 0.0;
              double price = double.tryParse(priceController.text) ?? 0.0;

              await FirebaseFirestore.instance
                  .collection('bookings')
                  .doc(bookingId)
                  .collection('users')
                  .doc(userId)
                  .collection('recyclables')
                  .doc(recyclableId)
                  .update({
                'weight': weight,
                'price': price,
                'item_price': weight * price,
              });

              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
