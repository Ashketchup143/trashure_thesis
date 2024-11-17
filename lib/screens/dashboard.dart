import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:trashure_thesis/sidebar.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DateTime _today = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Sidebar(),
      body: Builder(
        builder: (context) => Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon:
                          const Icon(Icons.menu, color: Colors.green, size: 25),
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Dashboard',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildTodaysBookingsTable(),
                const SizedBox(height: 20),
                _buildTodaysCollectedBookingsTable(),
                const SizedBox(height: 20),
                _buildMostRecentInflowTable(),
                const SizedBox(height: 20),
                _buildMostRecentOutflowTable(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<List<DocumentSnapshot>> _fetchTodaysBookings() async {
    QuerySnapshot snapshot = await _firestore.collection('bookings').get();
    return snapshot.docs;
  }

  Widget _buildTodaysBookingsTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Today's Bookings",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 10),
        FutureBuilder<List<DocumentSnapshot>>(
          future: _fetchTodaysBookings(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            var bookings = snapshot.data!.where((doc) {
              var data = doc.data() as Map<String, dynamic>;
              var bookingDate = (data['date'] as Timestamp).toDate();
              var status = data['status']?.toLowerCase() ?? '';
              return _isSameDay(bookingDate, _today) &&
                  (status == 'pending' || status == 'collecting');
            }).toList();
            return bookings.isEmpty
                ? Center(child: Text("No bookings for today."))
                : _buildBookingsTable(bookings);
          },
        ),
      ],
    );
  }

  Widget _buildTodaysCollectedBookingsTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Today's Collected Bookings",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 10),
        FutureBuilder<List<DocumentSnapshot>>(
          future: _fetchTodaysBookings(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            var collectedBookings = snapshot.data!.where((doc) {
              var data = doc.data() as Map<String, dynamic>;
              var bookingDate = (data['date'] as Timestamp).toDate();
              var status = data['status']?.toLowerCase() ?? '';
              return _isSameDay(bookingDate, _today) &&
                  (status == 'collected' || status == 'completed');
            }).toList();
            return collectedBookings.isEmpty
                ? Center(child: Text("No collected bookings for today."))
                : _buildBookingsTable(collectedBookings);
          },
        ),
      ],
    );
  }

  Widget _buildBookingsTable(List<DocumentSnapshot> bookings) {
    return Table(
      border: TableBorder.all(color: Colors.grey),
      columnWidths: const {
        0: FlexColumnWidth(1),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(2),
        3: FlexColumnWidth(2),
        4: FlexColumnWidth(2),
      },
      children: [
        TableRow(
          children: [
            _buildTableHeaderCell('Booking ID'),
            _buildTableHeaderCell('Date'),
            _buildTableHeaderCell('Status'),
            _buildTableHeaderCell('Driver'),
            _buildTableHeaderCell('Vehicle'), // New column for Vehicle
          ],
        ),
        ...bookings.map((booking) {
          var data = booking.data() as Map<String, dynamic>;
          var date = (data['date'] as Timestamp).toDate();
          var formattedDate = DateFormat('yyyy-MM-dd').format(date);
          return TableRow(
            children: [
              _buildTableCell(booking.id),
              _buildTableCell(formattedDate),
              _buildTableCell(data['status'] ?? 'N/A'),
              _buildTableCell(data['driver'] ?? 'N/A'),
              _buildTableCell(data['vehicle'] ?? 'N/A'), // Display vehicle
            ],
          );
        }).toList(),
      ],
    );
  }

  Widget _buildMostRecentInflowTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Most Recent Inflows',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8.0),
          ),
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              // Header Row
              Row(
                children: const [
                  Expanded(flex: 2, child: Text('Authorized By')),
                  Expanded(flex: 2, child: Text('Customer Name')),
                  Expanded(flex: 2, child: Text('Date')),
                  Expanded(flex: 2, child: Text('Total')),
                  Expanded(flex: 2, child: Text('Payment Method')),
                ],
              ),
              const Divider(),
              StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('inflow')
                    .orderBy('date', descending: true)
                    .limit(5)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  var inflows = snapshot.data!.docs;
                  if (inflows.isEmpty) {
                    return const Center(child: Text("No recent inflows."));
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: inflows.length,
                    itemBuilder: (context, index) {
                      var inflowData =
                          inflows[index].data() as Map<String, dynamic>;
                      var date = (inflowData['date'] as Timestamp).toDate();
                      var formattedDate = DateFormat('yyyy-MM-dd').format(date);
                      return ExpansionTile(
                        title: Row(
                          children: [
                            Expanded(
                                flex: 2,
                                child:
                                    Text(inflowData['authorized_by'] ?? 'N/A')),
                            Expanded(
                                flex: 2,
                                child:
                                    Text(inflowData['customer_name'] ?? 'N/A')),
                            Expanded(flex: 2, child: Text(formattedDate)),
                            Expanded(
                                flex: 2,
                                child: Text(
                                    'PHP ${inflowData['overall_total']?.toStringAsFixed(2) ?? '0.00'}')),
                            Expanded(
                                flex: 2,
                                child: Text(
                                    inflowData['payment_method'] ?? 'N/A')),
                          ],
                        ),
                        children: [
                          _buildSoldItems(inflows[index].id),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMostRecentOutflowTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Most Recent Outflows',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8.0),
          ),
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              // Header Row
              Row(
                children: const [
                  Expanded(flex: 2, child: Text('Category')),
                  Expanded(flex: 2, child: Text('Date')),
                  Expanded(flex: 2, child: Text('Price')),
                  Expanded(flex: 2, child: Text('Employee')),
                ],
              ),
              const Divider(),
              StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('outflow')
                    .orderBy('date', descending: true)
                    .limit(5)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  var outflows = snapshot.data!.docs;
                  if (outflows.isEmpty) {
                    return const Center(child: Text("No recent outflows."));
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: outflows.length,
                    itemBuilder: (context, index) {
                      var outflowData =
                          outflows[index].data() as Map<String, dynamic>;
                      var date = (outflowData['date'] as Timestamp).toDate();
                      var formattedDate = DateFormat('yyyy-MM-dd').format(date);
                      return ListTile(
                        title: Row(
                          children: [
                            Expanded(
                                flex: 2,
                                child: Text(outflowData['category'] ?? 'N/A')),
                            Expanded(flex: 2, child: Text(formattedDate)),
                            Expanded(
                                flex: 2,
                                child: Text(
                                    'PHP ${outflowData['price']?.toStringAsFixed(2) ?? '0.00'}')),
                            Expanded(
                                flex: 2,
                                child: Text(outflowData['employee'] ?? 'N/A')),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSoldItems(String inflowId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('inflow')
          .doc(inflowId)
          .collection('sold')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        var soldItems = snapshot.data!.docs;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: soldItems.length,
          itemBuilder: (context, index) {
            var soldData = soldItems[index].data() as Map<String, dynamic>;
            return ListTile(
              title: Text('Item: ${soldData['type']}'),
              subtitle: Text(
                'Price: PHP ${soldData['price']}, Weight: ${soldData['weight']} kg, Total: PHP ${soldData['item_total']}',
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTableHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        style:
            const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTableCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        textAlign: TextAlign.center,
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}
