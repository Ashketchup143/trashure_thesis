import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class OutflowDetails extends StatelessWidget {
  final Map<String, dynamic> outflowData;

  const OutflowDetails({Key? key, required this.outflowData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print("Outflow Data: $outflowData"); // Debugging print

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Outflow Details',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Common Fields
              Text(
                'Category: ${outflowData['category'] ?? 'N/A'}',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 10),
              Text(
                'Date: ${outflowData['date'] != null ? DateFormat('MM/dd/yyyy, hh:mm a').format(outflowData['date'].toDate()) : 'N/A'}',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 10),
              Text(
                'Price: ₱${outflowData['price']?.toStringAsFixed(2) ?? '0.00'}',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 10),
              Text(
                'Employee: ${outflowData['employee'] ?? 'N/A'}',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 10),

              // Vehicle Field for applicable categories
              if (outflowData['category'] == 'Fuel' ||
                  outflowData['category'] == 'Delivery Fee' ||
                  outflowData['category'] == 'Vehicle Maintenance')
                Text(
                  'Vehicle: ${outflowData['vehicle'] ?? 'N/A'}',
                  style: const TextStyle(fontSize: 18),
                ),
              const SizedBox(height: 10),

              // Driver Field for Fuel and Delivery Fee
              if (outflowData['category'] == 'Fuel' ||
                  outflowData['category'] == 'Delivery Fee')
                Text(
                  'Driver: ${outflowData['driver'] ?? 'N/A'}',
                  style: const TextStyle(fontSize: 18),
                ),
              const SizedBox(height: 10),

              // Details Field for Etc. category
              if (outflowData['category'] == 'Etc.')
                Text(
                  'Details: ${outflowData['details'] ?? 'N/A'}',
                  style: const TextStyle(fontSize: 18),
                ),
              const SizedBox(height: 10),

              // Recyclables List for Booking, Guest Booking, and Onsite Collection
              if (outflowData['category'] == 'booking' ||
                  outflowData['category'] == 'guest booking' ||
                  outflowData['category'] == 'onsite collection')
                FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('outflow')
                      .doc(outflowData['id']) // Ensure 'id' is correct
                      .collection('recyclables')
                      .get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      print("Error: ${snapshot.error}"); // Debugging print
                      return const Text(
                        'Failed to load recyclables.',
                        style: TextStyle(color: Colors.red),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      print("No recyclables found."); // Debugging print
                      return const Text(
                        'No recyclables found.',
                        style: TextStyle(fontSize: 16),
                      );
                    }

                    // Display the recyclables list
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        const Text(
                          'Recyclables:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...snapshot.data!.docs.map((doc) {
                          final recyclableData =
                              doc.data() as Map<String, dynamic>;
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            child: ListTile(
                              title: Text(recyclableData['type']
                                      .toString()
                                      .toUpperCase() ??
                                  'Unknown Type'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      'Category: ${recyclableData['category'] ?? 'N/A'}'),
                                  Text(
                                      'Weight: ${recyclableData['weight']?.toStringAsFixed(2) ?? '0.00'} kg'),
                                  Text(
                                      'Price: ₱${recyclableData['price']?.toStringAsFixed(2) ?? '0.00'}'),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
