import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Import for date formatting
import 'package:trashure_thesis/sidebar.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:html' as html;

class Inflow extends StatefulWidget {
  const Inflow({super.key});

  @override
  State<Inflow> createState() => _InflowState();
}

class _InflowState extends State<Inflow> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<bool> _selectedItems = []; // State to manage checkbox selection
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

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
                      'Revenue',
                      style: GoogleFonts.poppins(
                        textStyle: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: () => _printInflowData(),
                      icon: const Icon(
                        Icons.print,
                        color: Colors.white,
                      ),
                      label: const Text(
                        "Print",
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                    ),
                  ],
                ),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    height: 30,
                    decoration: BoxDecoration(
                      border: Border.all(),
                      borderRadius: BorderRadius.circular(17.5),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText:
                            'Search by category, name, vehicle, or status',
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) {
                        setState(() {}); // Trigger a rebuild for filtering
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const SizedBox(width: 10),
                      _buildDatePickerField('Start Date', _startDateController),
                      const SizedBox(width: 10),
                      _buildDatePickerField('End Date', _endDateController),
                    ],
                  ),
                ]),

                SizedBox(height: 20),
                // Titles Container
                Container(
                  height: 40,
                  decoration: BoxDecoration(border: Border.all()),
                  child: Row(
                    children: [
                      title('Select', 1),
                      title('Authorized By', 3),
                      title('Customer Name', 3),
                      title('Company Name',
                          3), // Add this line for "Company Name"
                      title('Date', 3),
                      title('Overall Total', 3),
                      title('Payment Method', 3),
                    ],
                  ),
                ),
                Container(
                  height: MediaQuery.of(context).size.height * .75,
                  decoration: BoxDecoration(border: Border.all()),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('inflow')
                        .orderBy('date', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Center(child: CircularProgressIndicator());
                      }

                      var inflowDocs = snapshot.data!.docs;

                      // Ensure _selectedItems list has the correct length
                      if (_selectedItems.length != inflowDocs.length) {
                        _selectedItems =
                            List.generate(inflowDocs.length, (_) => false);
                      }

                      // Filter by search query and date range
                      final searchText = _searchController.text.toLowerCase();
                      final startDate = _parseDate(_startDateController.text);
                      final endDate = _parseDate(_endDateController.text);

                      inflowDocs = inflowDocs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final authorizedBy =
                            data['authorized_by']?.toString().toLowerCase() ??
                                '';
                        final customerName = data['representative_name']
                                ?.toString()
                                .toLowerCase() ??
                            '';
                        final description =
                            data['description']?.toString().toLowerCase() ?? '';
                        final date = (data['date'] as Timestamp?)?.toDate();

                        // Check if the search term matches any of the relevant fields
                        final matchesSearch =
                            authorizedBy.contains(searchText) ||
                                customerName.contains(searchText) ||
                                description.contains(searchText);

                        // Check if the date falls within the selected date range
                        final matchesDateRange = date != null &&
                            (startDate == null || !date.isBefore(startDate)) &&
                            (endDate == null || !date.isAfter(endDate));

                        return matchesSearch && matchesDateRange;
                      }).toList();

                      // Calculate total overall after filtering
                      double totalOverall = _calculateTotalOverall(inflowDocs);

                      return Column(
                        children: [
                          Expanded(
                            child: ListView.builder(
                              itemCount: inflowDocs.length,
                              itemBuilder: (context, index) {
                                var inflowData = inflowDocs[index];
                                return _buildInflowRow(inflowData, index);
                              },
                            ),
                          ),
                          Divider(),
                          Container(
                            padding: const EdgeInsets.all(8.0),
                            alignment: Alignment.centerRight,
                            child: Text(
                              'Total Overall: PHP ${totalOverall.toStringAsFixed(2)}',
                              style: GoogleFonts.poppins(
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
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

  double _calculateTotalOverall(List<DocumentSnapshot> inflowDocs) {
    double totalOverall = 0.0;
    for (var doc in inflowDocs) {
      final data = doc.data() as Map<String, dynamic>?;
      totalOverall += data?['overall_total']?.toDouble() ?? 0.0;
    }
    return totalOverall;
  }

  DateTime? _parseDate(String date) {
    try {
      return DateFormat('MM/dd/yyyy').parseStrict(date);
    } catch (e) {
      return null;
    }
  }

  // This method builds each row in the list
  Widget _buildInflowRow(DocumentSnapshot inflowData, int index) {
    Map<String, dynamic>? data = inflowData.data()
        as Map<String, dynamic>?; // Extract data from DocumentSnapshot

    // Check if the 'date' field exists before using it
    Timestamp? timestamp = data?['date'] as Timestamp?;
    DateTime? date = timestamp?.toDate();
    String formattedDate = date != null
        ? DateFormat('yyyy-MM-dd').format(date)
        : 'N/A'; // Format date

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
              flex: 25, // Give the expansion tile more space
              child: ExpansionTile(
                title: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        data != null && data.containsKey('authorized_by')
                            ? data['authorized_by'] ?? 'N/A'
                            : 'N/A',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        data != null && data.containsKey('representative_name')
                            ? data['representative_name'] ?? 'N/A'
                            : 'N/A',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        data != null && data.containsKey('company_name')
                            ? data['company_name'] ?? 'N/A'
                            : 'N/A',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child:
                          Text(formattedDate, style: TextStyle(fontSize: 14)),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        data != null && data.containsKey('overall_total')
                            ? data['overall_total']?.toString() ?? 'N/A'
                            : 'N/A',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        data != null && data.containsKey('payment_method')
                            ? data['payment_method'] ?? 'N/A'
                            : 'N/A',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
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
                  'Price: ${soldData['price']}, Weight: ${soldData['weight']}, Total: ${soldData['item_total'].toStringAsFixed(2)}'),
            );
          },
        );
      },
    );
  }

  Widget title(String text, int flex) {
    return Expanded(
      flex: flex,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey.shade200, // Same background color
          border: const Border(
            bottom: BorderSide(color: Colors.grey), // Same bottom border style
          ),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            text,
            style: GoogleFonts.roboto(
              textStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14, // Adjust font size as needed
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _printInflowData() async {
    final pdf = pw.Document();

    // Parse filter values
    final searchText = _searchController.text.toLowerCase();
    final startDate = _parseDate(_startDateController.text);
    final endDate = _parseDate(_endDateController.text);

    // Fetch inflow data
    final inflowSnapshot = await _firestore.collection('inflow').get();
    List<Map<String, dynamic>> inflowDataList = [];
    double totalOverall = 0.0;

    // Filter and process inflow documents
    for (var inflowDoc in inflowSnapshot.docs) {
      final inflowData = inflowDoc.data() as Map<String, dynamic>;
      final authorizedBy =
          inflowData['authorized_by']?.toString().toLowerCase() ?? '';
      final customerName =
          inflowData['representative_name']?.toString().toLowerCase() ?? '';
      final companyName =
          inflowData['company_name']?.toString().toLowerCase() ?? '';
      final date = (inflowData['date'] as Timestamp?)?.toDate();

      // Apply filters
      final matchesSearch = authorizedBy.contains(searchText) ||
          customerName.contains(searchText) ||
          companyName.contains(searchText);
      final matchesDateRange = date != null &&
          (startDate == null || date.isAfter(startDate)) &&
          (endDate == null || date.isBefore(endDate));

      if (matchesSearch && matchesDateRange) {
        // Fetch sold items for this inflow
        final soldSnapshot = await _firestore
            .collection('inflow')
            .doc(inflowDoc.id)
            .collection('sold')
            .get();

        final soldItems =
            soldSnapshot.docs.map((soldDoc) => soldDoc.data()).toList();

        inflowDataList.add({
          'data': inflowData,
          'date': date ?? DateTime.now(),
          'soldItems': soldItems, // Include sold items
          'id': inflowDoc.id,
        });
        totalOverall += inflowData['overall_total']?.toDouble() ?? 0.0;
      }
    }

    // Sort inflows by date
    inflowDataList.sort(
      (a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime),
    );

    // Build the PDF content
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          List<pw.Widget> pdfWidgets = [
            pw.Text(
              'Inflow Report',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.green800,
              ),
            ),
            pw.SizedBox(height: 20),
          ];

          // Main table for inflows
          pdfWidgets.add(
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.black),
              columnWidths: {
                0: pw.FlexColumnWidth(3),
                1: pw.FlexColumnWidth(3),
                2: pw.FlexColumnWidth(3),
                3: pw.FlexColumnWidth(3),
                4: pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColors.green100),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text('Authorized By',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text('Customer Name',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text('Company Name',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text('Date',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text('Total',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                  ],
                ),
                ...inflowDataList.map((inflowMap) {
                  final inflowData = inflowMap['data'] as Map<String, dynamic>;
                  final date = inflowMap['date'] as DateTime;

                  return pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(inflowData['authorized_by'] ?? 'N/A'),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child:
                            pw.Text(inflowData['representative_name'] ?? 'N/A'),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(inflowData['company_name'] ?? 'N/A'),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(DateFormat('MM/dd/yyyy').format(date)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                            'PHP ${inflowData['overall_total']?.toDouble().toStringAsFixed(2) ?? '0.00'}'),
                      ),
                    ],
                  );
                }),
              ],
            ),
          );

          // Breakdown of items for each inflow
          for (var inflowMap in inflowDataList) {
            final inflowData = inflowMap['data'] as Map<String, dynamic>;
            final date = inflowMap['date'] as DateTime;
            final soldItems =
                inflowMap['soldItems'] as List<Map<String, dynamic>>;

            // Add breakdown table
            pdfWidgets.add(pw.SizedBox(height: 10));
            pdfWidgets.add(
              pw.Text(
                'Breakdown for ${inflowData['representative_name']} (${DateFormat('MM/dd/yyyy').format(date)})',
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 14,
                    color: PdfColors.green800),
              ),
            );
            pdfWidgets.add(
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.black),
                columnWidths: {
                  0: pw.FlexColumnWidth(3),
                  1: pw.FlexColumnWidth(2),
                  2: pw.FlexColumnWidth(2),
                  3: pw.FlexColumnWidth(2),
                },
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.green100),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Item',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Price',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Weight',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Total',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  ...soldItems.map((soldData) {
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(soldData['type'] ?? 'N/A'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                              'PHP ${soldData['price']?.toDouble().toStringAsFixed(2) ?? '0.00'}'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                              '${soldData['weight']?.toDouble().toStringAsFixed(2) ?? '0.00'} kg'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                              'PHP ${soldData['item_total']?.toDouble().toStringAsFixed(2) ?? '0.00'}'),
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),
            );
          }

          // Add total overall
          pdfWidgets.add(
            pw.SizedBox(height: 20),
          );
          pdfWidgets.add(
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'Total Overall: PHP ${totalOverall.toStringAsFixed(2)}',
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 16,
                    color: PdfColors.blueGrey900),
              ),
            ),
          );

          return pdfWidgets;
        },
      ),
    );

    // Convert to PDF and download
    final pdfBytes = await pdf.save();
    final blob = html.Blob([pdfBytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..target = 'blank'
      ..download = 'Inflow_Report.pdf'
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  Widget _buildDatePickerField(String label, TextEditingController controller) {
    return Expanded(
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              setState(() {
                controller.clear();
              });
            },
          ),
        ),
        readOnly: true,
        onTap: () async {
          DateTime? pickedDate = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(2020),
            lastDate: DateTime(2030),
          );
          if (pickedDate != null) {
            setState(() {
              controller.text = DateFormat('MM/dd/yyyy').format(pickedDate);
            });
          }
        },
      ),
    );
  }
}
