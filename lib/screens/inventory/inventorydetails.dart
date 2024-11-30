import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class InventoryDetails extends StatelessWidget {
  final String itemId;
  final String itemType;

  const InventoryDetails(
      {Key? key, required this.itemId, required this.itemType})
      : super(key: key);

  // Helper method to format the date
  String _formatDate(DateTime date) {
    return DateFormat('MMMM d, yyyy - hh:mm a').format(date);
  }

  // Helper method to calculate the previous weight
  Future<double> _calculatePreviousWeight(double currentWeight) async {
    double totalAddWeight = 0.0;
    double totalMinusWeight = 0.0;

    try {
      // Get today's date without time
      DateTime today = DateTime.now();
      DateTime currentDateOnly = DateTime(today.year, today.month, today.day);

      // Fetch the weight history subcollection
      QuerySnapshot weightHistorySnapshot = await FirebaseFirestore.instance
          .collection('inventory')
          .doc(itemId)
          .collection('weight_history')
          .orderBy('timestamp', descending: true)
          .get();

      // Iterate over the weight history documents
      for (var historyDoc in weightHistorySnapshot.docs) {
        var historyData = historyDoc.data() as Map<String, dynamic>;
        String operation = historyData['operation'] ?? '';
        double weightChange = (historyData['weight'] ?? 0.0).toDouble();
        Timestamp timestamp = historyData['timestamp'] as Timestamp;
        DateTime historyDate = timestamp.toDate();

        // Extract only the date part
        DateTime historyDateOnly =
            DateTime(historyDate.year, historyDate.month, historyDate.day);

        // Compare only the date part
        if (historyDateOnly == currentDateOnly) {
          if (operation == 'add') {
            totalAddWeight += weightChange;
          } else if (operation == 'minus') {
            totalMinusWeight += weightChange;
          }
        }
      }

      // Calculate the previous weight
      double previousWeight = currentWeight - totalAddWeight + totalMinusWeight;
      return previousWeight;
    } catch (e) {
      print('Error calculating previous weight: $e');
      return currentWeight; // Fallback to current weight if error occurs
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          'Weight History for $itemType',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('inventory')
            .doc(itemId)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final itemData = snapshot.data!.data() as Map<String, dynamic>?;
          if (itemData == null) {
            return const Center(child: Text('Item details not found.'));
          }

          final category = itemData['category'] ?? 'N/A';
          final currentWeight = (itemData['weight'] ?? 0.0).toDouble();

          return FutureBuilder<double>(
            future: _calculatePreviousWeight(currentWeight),
            builder: (context, previousWeightSnapshot) {
              if (!previousWeightSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final previousWeight =
                  previousWeightSnapshot.data!.toStringAsFixed(2);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Item Details',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        const SizedBox(height: 10),
                        Text('Category: $category'),
                        Text('Type: $itemType'),
                        Text(
                            'Current Weight: ${currentWeight.toStringAsFixed(2)} kg'),
                        Text('Previous Weight: $previousWeight kg'),
                      ],
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('inventory')
                          .doc(itemId)
                          .collection('weight_history')
                          .orderBy('timestamp', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        final weightHistory = snapshot.data!.docs;

                        if (weightHistory.isEmpty) {
                          return const Center(
                            child: Text(
                              'No weight history found.',
                              style: TextStyle(fontSize: 16),
                            ),
                          );
                        }

                        return ListView.builder(
                          itemCount: weightHistory.length,
                          itemBuilder: (context, index) {
                            final historyData = weightHistory[index].data()
                                as Map<String, dynamic>;
                            final operation = historyData['operation'] ?? '';
                            final weight = historyData['weight'] ?? 0.0;
                            final timestamp =
                                (historyData['timestamp'] as Timestamp)
                                    .toDate();
                            final price = historyData['price'] ?? null;
                            final category = historyData['category'] ??
                                'From Booking'; // Default to "From Booking"

                            // Determine category display text
                            final categoryDisplay =
                                category == 'Onsite Collection'
                                    ? 'Onsite Collection'
                                    : 'From Booking';

                            // Format the display text based on operation type
                            final weightDisplay = (operation == 'add')
                                ? '+ ${weight.toStringAsFixed(2)} kg'
                                : '- ${weight.toStringAsFixed(2)} kg';

                            // Format the date
                            final formattedDate = _formatDate(timestamp);

                            // Optional price display
                            final priceDisplay = price != null
                                ? 'Price: ₱${price.toStringAsFixed(2)}'
                                : '';

                            return ListTile(
                              leading: Icon(
                                operation == 'add'
                                    ? Icons.add_circle
                                    : Icons.remove_circle,
                                color: operation == 'add'
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              title: Text(
                                weightDisplay,
                                style: TextStyle(
                                  color: operation == 'add'
                                      ? Colors.green
                                      : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                'Category: $categoryDisplay\nDate: $formattedDate\n$priceDisplay',
                                style: const TextStyle(fontSize: 14),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
