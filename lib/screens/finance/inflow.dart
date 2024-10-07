import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Import for date formatting
import 'package:trashure_thesis/sidebar.dart';

class Inflow extends StatefulWidget {
  const Inflow({super.key});

  @override
  State<Inflow> createState() => _InflowState();
}

class _InflowState extends State<Inflow> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<bool> _selectedItems = []; // State to manage checkbox selection

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Sidebar(),
      body: Builder(
        builder: (context) => Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: Padding(
            padding: const EdgeInsets.only(top: 20, left: 40, right: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 5),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.menu, color: Colors.green, size: 25),
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                    ),
                    Text(
                      'Inflow',
                      style: GoogleFonts.poppins(
                        textStyle: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                // Titles Container
                Container(
                  height: 40,
                  decoration: BoxDecoration(border: Border.all()),
                  child: Row(
                    children: [
                      title('Select', 1),
                      title('Authorized By', 2),
                      title('Customer Name', 2),
                      title('Date', 2),
                      title('Description', 3),
                      title('Overall Total', 2),
                      title('Payment Method', 2),
                    ],
                  ),
                ),
                // The main container for the list
                Expanded(
                  child: Container(
                    height: MediaQuery.of(context).size.height * .825,
                    decoration: BoxDecoration(border: Border.all()),
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _firestore.collection('inflow').snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return Center(child: CircularProgressIndicator());
                        }

                        var inflowDocs = snapshot.data!.docs;

                        // Initialize checkbox state if not already initialized
                        if (_selectedItems.length != inflowDocs.length) {
                          _selectedItems =
                              List.generate(inflowDocs.length, (_) => false);
                        }

                        return ListView.builder(
                          itemCount: inflowDocs.length,
                          itemBuilder: (context, index) {
                            var inflowData = inflowDocs[index];
                            return _buildInflowRow(inflowData, index);
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // This method builds each row in the list
  Widget _buildInflowRow(DocumentSnapshot inflowData, int index) {
    Timestamp timestamp = inflowData['date']; // Get the Firestore Timestamp
    DateTime date = timestamp.toDate(); // Convert to DateTime
    String formattedDate =
        DateFormat('yyyy-MM-dd').format(date); // Format the DateTime

    return Column(
      children: [
        Row(
          children: [
            // Checkbox is now separate and clickable
            Expanded(
              flex: 1,
              child: Checkbox(
                value: _selectedItems[index],
                activeColor: Colors.green, // Green checkbox when checked
                onChanged: (bool? value) {
                  setState(() {
                    _selectedItems[index] = value ?? false;
                  });
                },
              ),
            ),
            Expanded(
              flex: 9, // Give the expansion tile more space
              child: ExpansionTile(
                title: Row(
                  children: [
                    Expanded(
                        flex: 2,
                        child: Text(inflowData['authorized_by'] ?? 'N/A',
                            style: TextStyle(fontSize: 14))),
                    Expanded(
                        flex: 2,
                        child: Text(inflowData['customer_name'] ?? 'N/A',
                            style: TextStyle(fontSize: 14))),
                    Expanded(
                        flex: 2,
                        child: Text(formattedDate,
                            style: TextStyle(fontSize: 14))),
                    Expanded(
                        flex: 3,
                        child: Text(inflowData['description'] ?? 'N/A',
                            style: TextStyle(fontSize: 14))),
                    Expanded(
                        flex: 2,
                        child: Text(
                            inflowData['overall_total']?.toString() ?? 'N/A',
                            style: TextStyle(fontSize: 14))),
                    Expanded(
                        flex: 2,
                        child: Text(inflowData['payment_method'] ?? 'N/A',
                            style: TextStyle(fontSize: 14))),
                  ],
                ),
                children: [
                  _buildSubCollection(
                      inflowData.id), // Dropdown for subcollection
                ],
              ),
            ),
          ],
        ),
        Divider(), // Adds a dividing line between the rows
      ],
    );
  }

  // This method builds the subcollection display for each row
  Widget _buildSubCollection(String inflowId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('inflow')
          .doc(inflowId)
          .collection('sold')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        var soldDocs = snapshot.data!.docs;
        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: soldDocs.length,
          itemBuilder: (context, index) {
            var soldData = soldDocs[index];
            return ListTile(
              title: Text('Item: ${soldData['type']}'),
              subtitle: Text(
                  'Price: ${soldData['price']}, Weight: ${soldData['weight']}, Total: ${soldData['item_total']}'),
            );
          },
        );
      },
    );
  }

  // Widget to display each title
  Widget title(String text, int flex) {
    return Expanded(
      flex: flex,
      child: Container(
        height: 40,
        decoration: BoxDecoration(border: Border(right: BorderSide())),
        child: Center(
          child: Text(
            text,
            style: GoogleFonts.roboto(
                textStyle: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}
