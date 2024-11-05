import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:trashure_thesis/sidebar.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:trashure_thesis/user_model.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:html' as html; // Import for web-based download and display

class Outflow extends StatefulWidget {
  const Outflow({super.key});

  @override
  State<Outflow> createState() => _OutflowState();
}

class _OutflowState extends State<Outflow> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  double _totalPrice = 0.0; // Variable to hold the total price

  @override
  Widget build(BuildContext context) {
    final userName = Provider.of<UserModel>(context, listen: false).userName;
    return Scaffold(
      drawer: const Sidebar(),
      body: Padding(
        padding: const EdgeInsets.only(top: 20, left: 40, right: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 5),
            Row(
              children: [
                Builder(
                  builder: (BuildContext context) {
                    return IconButton(
                      icon:
                          const Icon(Icons.menu, color: Colors.green, size: 25),
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                    );
                  },
                ),
                Text(
                  'Outflow',
                  style: GoogleFonts.poppins(
                    textStyle: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _printOutflowData(),
                  icon: const Icon(Icons.print),
                  label: const Text("Print"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Container(
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
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: () {
                    _showAddOutflowDialog(context, userName);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF4F),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: 8),
                      Text(
                        'Add Outflow',
                        style: GoogleFonts.roboto(
                          textStyle: const TextStyle(
                              fontWeight: FontWeight.w300, color: Colors.white),
                        ),
                      ),
                      const Icon(
                        Icons.add,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildDatePickerField('Start Date', _startDateController),
                const SizedBox(width: 10),
                _buildDatePickerField('End Date', _endDateController),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(border: Border.all()),
              child: Column(
                children: [
                  Row(
                    children: [
                      title('Category', 2),
                      title('Date', 2),
                      title('Price', 2),
                      title('Weight', 2),
                      title('Employee', 2),
                      title('Status', 2),
                      title('Vehicle', 2),
                    ],
                  ),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _firestore
                          .collection("outflow")
                          .orderBy("date", descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final outflowList = snapshot.data!.docs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final category = data['category'] ?? '';
                          final status = data['status'] ?? '';
                          final employee = data['employee'] ?? '';
                          final vehicle = data['vehicle'] ?? '';
                          final date = (data['date'] as Timestamp?)?.toDate();

                          final searchText =
                              _searchController.text.toLowerCase();
                          final matchesSearch =
                              category.toLowerCase().contains(searchText) ||
                                  status.toLowerCase().contains(searchText) ||
                                  employee.toLowerCase().contains(searchText) ||
                                  vehicle.toLowerCase().contains(searchText);

                          DateTime? startDate =
                              _parseDate(_startDateController.text);
                          DateTime? endDate =
                              _parseDate(_endDateController.text);
                          final matchesDateRange = date != null &&
                              (startDate == null || date.isAfter(startDate)) &&
                              (endDate == null || date.isBefore(endDate));

                          return matchesSearch && matchesDateRange;
                        }).toList();

                        // Calculate total price here without using setState
                        final totalPrice = outflowList.fold(0.0, (sum, doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return sum + (data['price']?.toDouble() ?? 0.0);
                        });

                        return Column(
                          children: [
                            Expanded(
                              child: ListView.builder(
                                itemCount: outflowList.length,
                                itemBuilder: (context, index) {
                                  final outflowData = outflowList[index].data()
                                      as Map<String, dynamic>;
                                  String category =
                                      outflowData['category'] ?? '';
                                  Timestamp? timestamp = outflowData['date'];
                                  String formattedDate = timestamp != null
                                      ? DateFormat('MM/dd/yyyy, hh:mm a')
                                          .format(timestamp.toDate())
                                      : '';
                                  double price =
                                      outflowData['price']?.toDouble() ?? 0.0;
                                  double weight =
                                      outflowData['weight']?.toDouble() ?? 0.0;
                                  String employee =
                                      outflowData['employee'] ?? '';
                                  String status = outflowData['status'] ?? '';
                                  String vehicle = outflowData['vehicle'] ?? '';

                                  return Container(
                                    decoration: const BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        _buildText(category, 2),
                                        _buildText(formattedDate, 2),
                                        _buildText(
                                            '₱${price.toStringAsFixed(2)}', 2),
                                        _buildText(
                                            '${weight.toStringAsFixed(2)} kg',
                                            2),
                                        _buildText(employee, 2),
                                        _buildText(status, 2),
                                        _buildText(vehicle, 2),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8.0),
                              alignment: Alignment.centerRight,
                              child: Text(
                                'Total Price: ₱${totalPrice.toStringAsFixed(2)}',
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
          ],
        ),
      ),
    );
  }

  // Calculate total price
  double _calculateTotalPrice(List<QueryDocumentSnapshot> outflowList) {
    double total = 0.0;
    for (var doc in outflowList) {
      final data = doc.data() as Map<String, dynamic>;
      total += data['price']?.toDouble() ?? 0.0;
    }
    return total;
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

  DateTime? _parseDate(String date) {
    try {
      return DateFormat('MM/dd/yyyy').parseStrict(date);
    } catch (e) {
      return null;
    }
  }

  void _showAddOutflowDialog(BuildContext context, String? userName) {
    final TextEditingController _priceController = TextEditingController();
    final TextEditingController _detailsController = TextEditingController();
    String? selectedCategory;
    String? selectedVehicle;
    Timestamp? selectedDate;
    final List<String> categories = ['Fuel', 'Vehicle Maintenance', 'Etc.'];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Outflow'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      value: selectedCategory,
                      items: categories.map((category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          selectedCategory = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Select Date',
                        border: OutlineInputBorder(),
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
                            selectedDate = Timestamp.fromDate(pickedDate);
                          });
                        }
                      },
                      controller: TextEditingController(
                        text: selectedDate != null
                            ? DateFormat('MM/dd/yyyy')
                                .format(selectedDate!.toDate())
                            : '',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Price',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    if (selectedCategory == 'Fuel' ||
                        selectedCategory == 'Vehicle Maintenance')
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('vehicles')
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const CircularProgressIndicator();
                          }
                          var vehicles = snapshot.data?.docs ?? [];
                          return DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Select Vehicle',
                              border: OutlineInputBorder(),
                            ),
                            value: selectedVehicle,
                            items: vehicles.map((doc) {
                              var vehicleData =
                                  doc.data() as Map<String, dynamic>;
                              String vehicleLabel =
                                  "${vehicleData['brand']} ${vehicleData['model']}";
                              return DropdownMenuItem<String>(
                                value: doc.id,
                                child: Text(vehicleLabel),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              setState(() {
                                selectedVehicle = newValue;
                              });
                            },
                          );
                        },
                      )
                    else if (selectedCategory == 'Etc.')
                      TextFormField(
                        controller: _detailsController,
                        decoration: const InputDecoration(
                          labelText: 'Expense Details',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    const SizedBox(height: 16),
                    TextFormField(
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Employee',
                        border: OutlineInputBorder(),
                      ),
                      controller: TextEditingController(
                        text: userName ?? 'Admin',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    double price =
                        double.tryParse(_priceController.text) ?? 0.0;
                    if (selectedDate == null ||
                        selectedCategory == null ||
                        price <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Please fill out all required fields.')),
                      );
                      return;
                    }
                    Map<String, dynamic> outflowData = {
                      'category': selectedCategory,
                      'date': selectedDate,
                      'price': price,
                      'employee': userName ?? 'Admin',
                      'status': 'Pending',
                    };
                    if ((selectedCategory == 'Fuel' ||
                            selectedCategory == 'Vehicle Maintenance') &&
                        selectedVehicle != null) {
                      outflowData['vehicle'] = selectedVehicle;
                    } else if (selectedCategory == 'Etc.') {
                      outflowData['details'] = _detailsController.text;
                    }
                    await _firestore.collection('outflow').add(outflowData);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Outflow added successfully!')),
                    );
                    Navigator.of(context).pop();
                  },
                  child: const Text('Add'),
                ),
              ],
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
        height: 20,
        decoration: const BoxDecoration(border: Border(bottom: BorderSide())),
        child: Center(
          child: Text(
            text,
            style: GoogleFonts.roboto(
                textStyle: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  Widget _buildText(String text, int flex) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          text,
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  void _printOutflowData() async {
    final pdf = pw.Document();

    // Parse the filter values
    final searchText = _searchController.text.toLowerCase();
    final startDate = _parseDate(_startDateController.text);
    final endDate = _parseDate(_endDateController.text);

    // Fetch and filter outflow data from Firestore
    final outflowSnapshot = await _firestore.collection('outflow').get();
    List<Map<String, dynamic>> outflowDataList = [];
    double totalOverall = 0.0;

    // Collect outflow documents with applied filters
    for (var outflowDoc in outflowSnapshot.docs) {
      final outflowData = outflowDoc.data() as Map<String, dynamic>;
      final category = outflowData['category']?.toString().toLowerCase() ?? '';
      final employee = outflowData['employee']?.toString().toLowerCase() ?? '';
      final vehicle = outflowData['vehicle']?.toString().toLowerCase() ?? '';
      final date = (outflowData['date'] as Timestamp?)?.toDate();

      // Apply search and date range filters
      final matchesSearch = category.contains(searchText) ||
          employee.contains(searchText) ||
          vehicle.contains(searchText);

      final matchesDateRange = date != null &&
          (startDate == null || date.isAfter(startDate)) &&
          (endDate == null || date.isBefore(endDate));

      if (matchesSearch && matchesDateRange) {
        outflowDataList.add({
          'data': outflowData,
          'date': date ?? DateTime.now(), // Use current date if date is null
          'id': outflowDoc.id,
        });
        totalOverall += outflowData['price']?.toDouble() ?? 0.0;
      }
    }

    // Sort outflow documents by date in descending order
    outflowDataList.sort(
        (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

    // Build PDF content with sorted outflow documents
    List<pw.TableRow> outflowRows = [
      pw.TableRow(
        children: [
          pw.Text('Category',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text('Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text('Price', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text('Weight',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text('Employee',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text('Status',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text('Vehicle',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ],
      ),
    ];

    for (var outflowMap in outflowDataList) {
      final outflowData = outflowMap['data'] as Map<String, dynamic>;
      final date = outflowMap['date'] as DateTime;

      outflowRows.add(
        pw.TableRow(
          children: [
            pw.Text(outflowData['category'] ?? 'N/A'),
            pw.Text(DateFormat('MM/dd/yyyy, hh:mm a').format(date)),
            pw.Text(
                'PHP ${outflowData['price']?.toStringAsFixed(2) ?? '0.00'}'),
            pw.Text(
                '${outflowData['weight']?.toStringAsFixed(2) ?? '0.00'} kg'),
            pw.Text(outflowData['employee'] ?? 'N/A'),
            pw.Text(outflowData['status'] ?? 'N/A'),
            pw.Text(outflowData['vehicle'] ?? 'N/A'),
          ],
        ),
      );
    }

    // Add a footer with the total price outside the table
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Text(
            'Outflow Report',
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 20),
          pw.Table(children: outflowRows, border: pw.TableBorder.all()),
          pw.SizedBox(height: 20),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Total Price: PHP ${totalOverall.toStringAsFixed(2)}',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    // Convert PDF to Uint8List
    final pdfBytes = await pdf.save();

    // Create a Blob and open in a new tab
    final blob = html.Blob([pdfBytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.window.open(url, '_blank');
    html.Url.revokeObjectUrl(url); // Clean up the object URL
  }

  Future<Map<String, dynamic>> _fetchOutflowDataForPrint({
    DateTime? startDate,
    DateTime? endDate,
    String searchText = '',
  }) async {
    final snapshot = await _firestore.collection("outflow").get();

    final List<List<String>> outflowData = [];
    double totalPrice = 0.0;

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;

      final date = (data['date'] as Timestamp?)?.toDate();
      final category = data['category']?.toString().toLowerCase() ?? '';
      final status = data['status']?.toString().toLowerCase() ?? '';
      final employee = data['employee']?.toString().toLowerCase() ?? '';
      final vehicle = data['vehicle']?.toString().toLowerCase() ?? '';

      // Apply search filter
      final matchesSearch = category.contains(searchText) ||
          status.contains(searchText) ||
          employee.contains(searchText) ||
          vehicle.contains(searchText);

      // Apply date range filter
      final matchesDateRange = date != null &&
          (startDate == null || date.isAfter(startDate)) &&
          (endDate == null || date.isBefore(endDate));

      if (matchesSearch && matchesDateRange) {
        final price = data['price']?.toDouble() ?? 0.0;
        totalPrice += price; // Accumulate total price

        outflowData.add([
          data['category'] ?? '',
          date != null ? DateFormat('MM/dd/yyyy, hh:mm a').format(date) : '',
          'PHP ${price.toStringAsFixed(2)}',
          '${data['weight']?.toStringAsFixed(2) ?? '0.00'} kg',
          data['employee'] ?? '',
          data['status'] ?? '',
          data['vehicle'] ?? '',
        ]);
      }
    }

    return {
      'data': outflowData,
      'totalPrice': totalPrice,
    };
  }
}
