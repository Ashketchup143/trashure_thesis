import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:trashure_thesis/screens/finance/outflow_details.dart';
import 'package:trashure_thesis/sidebar.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:html' as html;

class Finance extends StatefulWidget {
  const Finance({super.key});

  @override
  State<Finance> createState() => _FinanceState();
}

class _FinanceState extends State<Finance> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _inflowSearchController = TextEditingController();
  final TextEditingController _outflowSearchController =
      TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  double _totalInflow = 0.0;
  double _totalOutflow = 0.0;
  void initState() {
    super.initState();
    _updateTotals(); // Calculate the initial totals when the screen loads
  }

// Method to update the totals for inflow and outflow
  void _updateTotals() {
    final startDate = _parseDate(_startDateController.text);
    final endDate = _parseDate(_endDateController.text);

    // Listen to inflow data stream with date filtering
    _firestore.collection('inflow').snapshots().listen((snapshot) {
      double totalInflow = 0.0;
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final date = (data['date'] as Timestamp?)?.toDate();

        // Apply date filters
        final matchesDate = date != null &&
            (startDate == null || date.isAfter(startDate)) &&
            (endDate == null || date.isBefore(endDate));

        if (matchesDate) {
          totalInflow += data['overall_total']?.toDouble() ?? 0.0;
        }
      }
      setState(() {
        _totalInflow = totalInflow;
      });
    });

    // Listen to outflow data stream with date filtering
    _firestore.collection('outflow').snapshots().listen((snapshot) {
      double totalOutflow = 0.0;
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final date = (data['date'] as Timestamp?)?.toDate();

        // Apply date filters
        final matchesDate = date != null &&
            (startDate == null || date.isAfter(startDate)) &&
            (endDate == null || date.isBefore(endDate));

        if (matchesDate) {
          totalOutflow += data['price']?.toDouble() ?? 0.0;
        }
      }
      setState(() {
        _totalOutflow = totalOutflow;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const Sidebar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Sidebar IconButton and Finance Overview Text
            Row(
              children: [
                Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(Icons.menu, color: Colors.green, size: 25),
                    onPressed: () {
                      Scaffold.of(context).openDrawer();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Finance Overview',
                  style: GoogleFonts.poppins(
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _printFinanceReport,
                  icon: const Icon(
                    Icons.print,
                    color: Colors.white,
                  ),
                  label: const Text(
                    "Print Report",
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                    child: _buildDatePickerField(
                        'Start Date', _startDateController)),
                const SizedBox(width: 10),
                Expanded(
                    child:
                        _buildDatePickerField('End Date', _endDateController)),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(child: _buildInflowSection()),
            const SizedBox(height: 20),
            Expanded(child: _buildOutflowSection()),
            const SizedBox(height: 20),
            _buildSummarySection(),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePickerField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            setState(() {
              controller.clear();
              _updateTotals(); // Update totals when date is cleared
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
            _updateTotals(); // Update totals when date is selected
          });
        }
      },
    );
  }

  Widget _buildInflowSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _inflowSearchController,
          decoration: const InputDecoration(
            labelText: 'Search Inflow',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => setState(() {}),
        ),
        const SizedBox(height: 10),
        Expanded(child: _buildInflowTable()),
      ],
    );
  }

  Widget _buildOutflowSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _outflowSearchController,
          decoration: const InputDecoration(
            labelText: 'Search Outflow by category, employee, or vehicle',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => setState(() {}),
        ),
        const SizedBox(height: 10),
        Expanded(child: _buildOutflowTable()),
      ],
    );
  }

  Widget _buildOutflowTable() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('outflow')
          .orderBy('date', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        var outflowDocs = snapshot.data!.docs;
        _totalOutflow = 0.0;

        // Apply filters based on search text and date range
        final searchText = _outflowSearchController.text.toLowerCase();
        final startDate = _parseDate(_startDateController.text);
        final endDate = _parseDate(_endDateController.text);

        outflowDocs = outflowDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final category = data['category']?.toLowerCase() ?? '';
          final employee = data['employee']?.toLowerCase() ?? '';
          final vehicle = data['vehicle']?.toLowerCase() ?? '';
          final date = (data['date'] as Timestamp?)?.toDate();

          final matchesSearch = category.contains(searchText) ||
              employee.contains(searchText) ||
              vehicle.contains(searchText);
          final matchesDate = date != null &&
              (startDate == null || date.isAfter(startDate)) &&
              (endDate == null || date.isBefore(endDate));

          return matchesSearch && matchesDate;
        }).toList();

        // Calculate total outflow
        _totalOutflow = outflowDocs.fold(0.0, (sum, doc) {
          return sum + (doc['price']?.toDouble() ?? 0.0);
        });

        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Column(
            children: [
              // Column Titles
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  border: const Border(bottom: BorderSide(color: Colors.grey)),
                ),
                child: Row(
                  children: const [
                    Expanded(
                        child: Text('Category',
                            style: TextStyle(fontWeight: FontWeight.bold))),
                    Expanded(
                        child: Text('Date',
                            style: TextStyle(fontWeight: FontWeight.bold))),
                    Expanded(
                        child: Text('Price',
                            style: TextStyle(fontWeight: FontWeight.bold))),
                    Expanded(
                        child: Text('Employee',
                            style: TextStyle(fontWeight: FontWeight.bold))),
                    Expanded(
                        child: Text('Vehicle',
                            style: TextStyle(fontWeight: FontWeight.bold))),
                    SizedBox(width: 50), // Space for the Info IconButton
                  ],
                ),
              ),
              // Outflow Data Rows
              Expanded(
                child: ListView.builder(
                  itemCount: outflowDocs.length,
                  itemBuilder: (context, index) {
                    final outflowData =
                        outflowDocs[index].data() as Map<String, dynamic>;
                    final formattedDate = DateFormat('MM/dd/yyyy').format(
                      (outflowData['date'] as Timestamp?)?.toDate() ??
                          DateTime.now(),
                    );

                    return Container(
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.grey)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                              child: Text(outflowData['category'] ?? 'N/A')),
                          Expanded(child: Text(formattedDate)),
                          Expanded(
                            child: Text(
                                'PHP ${outflowData['price']?.toDouble().toStringAsFixed(2) ?? '0.00'}'),
                          ),
                          Expanded(
                              child: Text(outflowData['employee'] ?? 'N/A')),
                          Expanded(
                              child: Text(outflowData['vehicle'] ?? 'N/A')),
                          IconButton(
                            icon: const Icon(
                              Icons.info_outline,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => OutflowDetails(
                                    outflowData: {
                                      ...outflowData,
                                      'id': outflowDocs[index]
                                          .id, // Include the document ID
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInflowTable() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('inflow')
          .orderBy('date', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        var inflowDocs = snapshot.data!.docs;
        _totalInflow = 0.0;

        final searchText = _inflowSearchController.text.toLowerCase();
        final startDate = _parseDate(_startDateController.text);
        final endDate = _parseDate(_endDateController.text);

        inflowDocs = inflowDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final representativeName =
              data['representative_name']?.toLowerCase() ?? '';
          final companyName = data['company_name']?.toLowerCase() ?? '';
          final authorizedBy = data['authorized_by']?.toLowerCase() ?? '';
          final date = (data['date'] as Timestamp?)?.toDate();

          final matchesSearch = representativeName.contains(searchText) ||
              companyName.contains(searchText) ||
              authorizedBy.contains(searchText);
          final matchesDate = date != null &&
              (startDate == null || date.isAfter(startDate)) &&
              (endDate == null || date.isBefore(endDate));

          return matchesSearch && matchesDate;
        }).toList();

        _totalInflow = inflowDocs.fold(0.0, (sum, doc) {
          return sum + (doc['overall_total']?.toDouble() ?? 0.0);
        });

        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Column(
            children: [
              // Column Titles
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  border: const Border(bottom: BorderSide(color: Colors.grey)),
                ),
                child: Row(
                  children: const [
                    Expanded(
                        child: Text('Customer Name',
                            style: TextStyle(fontWeight: FontWeight.bold))),
                    Expanded(
                        child: Text('Company Name',
                            style: TextStyle(fontWeight: FontWeight.bold))),
                    Expanded(
                        child: Text('Authorized By',
                            style: TextStyle(fontWeight: FontWeight.bold))),
                    Expanded(
                        child: Text('Payment Method',
                            style: TextStyle(fontWeight: FontWeight.bold))),
                    Expanded(
                        child: Text('Date',
                            style: TextStyle(fontWeight: FontWeight.bold))),
                    Expanded(
                        child: Text('Overall Total',
                            style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
              // Inflow Data Rows
              Expanded(
                child: ListView.builder(
                  itemCount: inflowDocs.length,
                  itemBuilder: (context, index) {
                    final data =
                        inflowDocs[index].data() as Map<String, dynamic>;
                    final date = (data['date'] as Timestamp?)?.toDate();
                    final formattedDate =
                        DateFormat('MM/dd/yyyy').format(date ?? DateTime.now());

                    return ExpansionTile(
                      title: Row(
                        children: [
                          Expanded(
                              child:
                                  Text(data['representative_name'] ?? 'N/A')),
                          Expanded(child: Text(data['company_name'] ?? 'N/A')),
                          Expanded(child: Text(data['authorized_by'] ?? 'N/A')),
                          Expanded(
                              child: Text(data['payment_method'] ?? 'N/A')),
                          Expanded(child: Text(formattedDate)),
                          Expanded(
                              child: Text(
                                  'PHP ${data['overall_total']?.toStringAsFixed(2) ?? '0.00'}')),
                        ],
                      ),
                      children: [_buildSoldItemsList(inflowDocs[index].id)],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSoldItemsList(String inflowId) {
    return FutureBuilder<QuerySnapshot>(
      future: _firestore
          .collection('inflow')
          .doc(inflowId)
          .collection('sold')
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();

        return Column(
          children: snapshot.data!.docs.map((soldDoc) {
            final soldData = soldDoc.data() as Map<String, dynamic>;
            return ListTile(
              title: Text('Item: ${soldData['type']}'),
              subtitle: Text(
                'Price: PHP ${soldData['price']} - Weight: ${soldData['weight']} kg - Total: PHP ${soldData['item_total'].toStringAsFixed(2)}',
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildSummarySection() {
    final profit = _totalInflow - _totalOutflow;
    return Column(
      children: [
        Text('Total Inflow: PHP ${_totalInflow.toStringAsFixed(2)}'),
        Text('Total Outflow: PHP ${_totalOutflow.toStringAsFixed(2)}'),
        Text('Profit: PHP ${profit.toStringAsFixed(2)}'),
      ],
    );
  }

  DateTime? _parseDate(String date) {
    try {
      return DateFormat('MM/dd/yyyy').parseStrict(date);
    } catch (e) {
      return null;
    }
  }

  void _printFinanceReport() async {
    final pdf = pw.Document();

    // Fetch the data for printing
    final inflowData = await _inflowDataForPrint();
    final outflowData = await _outflowDataForPrint();

    // Calculate the totals
    final totalInflow = inflowData.fold(
        0.0, (sum, item) => sum + (item['overall_total'] ?? 0.0));
    final totalOutflow =
        outflowData.fold(0.0, (sum, item) => sum + (item['price'] ?? 0.0));
    final profit = totalInflow - totalOutflow;

    // Add a title page
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Text(
            'Finance Overview Report',
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 20),
          // Summary Section
          pw.Text(
            'Summary',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.Text('Total Inflow: PHP ${totalInflow.toStringAsFixed(2)}'),
          pw.Text('Total Outflow: PHP ${totalOutflow.toStringAsFixed(2)}'),
          pw.Text('Profit: PHP ${profit.toStringAsFixed(2)}'),
          pw.SizedBox(height: 20),
          pw.Divider(),
          // Inflow Table
          pw.Text(
            'Inflow Report',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          _buildInflowTableForPrint(inflowData),
          pw.SizedBox(height: 20),
          pw.Divider(),
          // Outflow Table
          pw.Text(
            'Outflow Report',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          _buildOutflowTableForPrint(outflowData),
        ],
      ),
    );

    // Convert PDF to Uint8List and open in a new tab
    final pdfBytes = await pdf.save();
    final blob = html.Blob([pdfBytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.window.open(url, '_blank');
    html.Url.revokeObjectUrl(url);
  }

  pw.Widget _buildInflowTableForPrint(List<Map<String, dynamic>> inflowData) {
    return pw.Table(
      border: pw.TableBorder.all(),
      children: [
        // Header Row
        pw.TableRow(
          children: [
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
              child: pw.Text('Authorized By',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text('Payment Method',
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
        // Data Rows
        ...inflowData.map((item) {
          return pw.TableRow(
            children: [
              pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(item['representative_name'] ?? 'N/A')),
              pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(item['company_name'] ?? 'N/A')),
              pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(item['authorized_by'] ?? 'N/A')),
              pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(item['payment_method'] ?? 'N/A')),
              pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child:
                      pw.Text(DateFormat('MM/dd/yyyy').format(item['date']))),
              pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(
                      'PHP ${item['overall_total']?.toStringAsFixed(2) ?? '0.00'}')),
            ],
          );
        }).toList(),
      ],
    );
  }

  pw.Widget _buildOutflowTableForPrint(List<Map<String, dynamic>> outflowData) {
    return pw.Table(
      border: pw.TableBorder.all(),
      children: [
        // Header Row
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text('Category',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text('Date',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text('Price',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text('Employee',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text('Vehicle',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
          ],
        ),
        // Data Rows
        ...outflowData.map((item) {
          return pw.TableRow(
            children: [
              pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(item['category'] ?? 'N/A')),
              pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child:
                      pw.Text(DateFormat('MM/dd/yyyy').format(item['date']))),
              pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(
                      'PHP ${item['price']?.toStringAsFixed(2) ?? '0.00'}')),
              pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(item['employee'] ?? 'N/A')),
              pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(item['vehicle'] ?? 'N/A')),
            ],
          );
        }).toList(),
      ],
    );
  }

  Future<List<Map<String, dynamic>>> _inflowDataForPrint() async {
    final searchText = _inflowSearchController.text.toLowerCase();
    final startDate = _parseDate(_startDateController.text);
    final endDate = _parseDate(_endDateController.text);

    final snapshot = await _firestore.collection('inflow').get();
    List<Map<String, dynamic>> inflowDataList = [];

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final representativeName =
          data['representative_name']?.toLowerCase() ?? '';
      final companyName = data['company_name']?.toLowerCase() ?? '';
      final authorizedBy = data['authorized_by']?.toLowerCase() ?? '';
      final date = (data['date'] as Timestamp?)?.toDate();

      final matchesSearch = representativeName.contains(searchText) ||
          companyName.contains(searchText) ||
          authorizedBy.contains(searchText);
      final matchesDate = date != null &&
          (startDate == null || date.isAfter(startDate)) &&
          (endDate == null || date.isBefore(endDate));

      if (matchesSearch && matchesDate) {
        inflowDataList.add({
          'representative_name': data['representative_name'] ?? 'N/A',
          'company_name': data['company_name'] ?? 'N/A',
          'authorized_by': data['authorized_by'] ?? 'N/A',
          'payment_method': data['payment_method'] ?? 'N/A',
          'date': date ?? DateTime.now(),
          'overall_total': data['overall_total']?.toDouble() ?? 0.0,
        });
      }
    }
    // Sort by date in descending order
    inflowDataList.sort(
        (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

    return inflowDataList;
  }

  Future<List<Map<String, dynamic>>> _outflowDataForPrint() async {
    final searchText = _outflowSearchController.text.toLowerCase();
    final startDate = _parseDate(_startDateController.text);
    final endDate = _parseDate(_endDateController.text);

    final snapshot = await _firestore.collection('outflow').get();
    List<Map<String, dynamic>> outflowDataList = [];

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final category = data['category']?.toLowerCase() ?? '';
      final employee = data['employee']?.toLowerCase() ?? '';
      final vehicle = data['vehicle']?.toLowerCase() ?? '';
      final date = (data['date'] as Timestamp?)?.toDate();

      final matchesSearch = category.contains(searchText) ||
          employee.contains(searchText) ||
          vehicle.contains(searchText);
      final matchesDate = date != null &&
          (startDate == null || date.isAfter(startDate)) &&
          (endDate == null || date.isBefore(endDate));

      if (matchesSearch && matchesDate) {
        outflowDataList.add({
          'category': data['category'] ?? 'N/A',
          'date': date ?? DateTime.now(),
          'price': data['price']?.toDouble() ?? 0.0,
          'employee': data['employee'] ?? 'N/A',
          'vehicle': data['vehicle'] ?? 'N/A',
        });
      }
    }

    // Sort by date in descending order
    outflowDataList.sort(
        (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

    return outflowDataList;
  }
}
