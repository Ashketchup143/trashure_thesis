import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class OutflowDetails extends StatelessWidget {
  final Map<String, dynamic> outflowData;

  const OutflowDetails({Key? key, required this.outflowData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
              _buildField('Category', outflowData['category']),
              _buildField(
                'Date',
                outflowData['date'] != null
                    ? DateFormat('MM/dd/yyyy, hh:mm a')
                        .format(outflowData['date'].toDate())
                    : 'N/A',
              ),
              _buildField('Price',
                  '₱${outflowData['price']?.toStringAsFixed(2) ?? '0.00'}'),
              _buildField('Employee', outflowData['employee'] ?? "N/A"),
              if (_isVehicleRequired(outflowData['category']))
                _buildField('Vehicle', outflowData['vehicle'] ?? "N/A"),
              if (_isDriverRequired(outflowData['category']))
                _buildField('Driver', outflowData['driver'] ?? "N/A"),
              if (_isDetailsRequired(outflowData['category']))
                _buildField('Details', outflowData['details'] ?? "N/A"),
              if (_isRecyclablesCategory(outflowData['category']))
                _buildRecyclablesList(outflowData['id']),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        '$label: ${value ?? 'N/A'}',
        style: const TextStyle(fontSize: 18),
      ),
    );
  }

  /// Helper to check if the category requires Vehicle information
  bool _isVehicleRequired(String? category) {
    return category == 'Additional fuel' ||
        category == 'Vehicle Maintenance' ||
        category == 'Delivery Fee';
  }

  /// Helper to check if the category requires Driver information
  bool _isDriverRequired(String? category) {
    return category == 'Additional fuel' || category == 'Delivery Fee';
  }

  /// Helper to check if the category requires additional details
  bool _isDetailsRequired(String? category) {
    return category == 'Etc.'; // Add other categories if necessary
  }

  /// Helper to check if the category includes recyclables
  bool _isRecyclablesCategory(String? category) {
    return category == 'booking' ||
        category == 'guest booking' ||
        category == 'onsite collection';
  }

  Widget _buildRecyclablesList(String id) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('outflow')
          .doc(id)
          .collection('recyclables')
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Text(
            'Failed to load recyclables.',
            style: TextStyle(color: Colors.red),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text(
            'No recyclables found.',
            style: TextStyle(fontSize: 16),
          );
        }

        double totalWeight = 0.0;
        double totalPrice = 0.0;

        final recyclables = snapshot.data!.docs.map((doc) {
          final recyclableData = doc.data() as Map<String, dynamic>;
          double weight = recyclableData.containsKey('final_weight')
              ? (recyclableData['final_weight']?.toDouble() ?? 0.0)
              : (recyclableData['weight']?.toDouble() ?? 0.0);
          double price = recyclableData['price']?.toDouble() ?? 0.0;
          double itemTotal = weight * price;

          totalWeight += weight;
          totalPrice += itemTotal;

          return _buildRecyclableItem(recyclableData, weight, price, itemTotal);
        }).toList();

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
            ...recyclables,
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Weight: ${totalWeight.toStringAsFixed(2)} kg',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Total Price: ₱${totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecyclableItem(
      Map<String, dynamic> data, double weight, double price, double total) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: ListTile(
        title: Text(
          data['type']?.toString().toUpperCase() ?? 'Unknown Type',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Weight: ${weight.toStringAsFixed(2)} kg'),
            Text('Price per kg: ₱${price.toStringAsFixed(2)}'),
            Text('Total: ₱${total.toStringAsFixed(2)}'),
          ],
        ),
      ),
    );
  }
}
