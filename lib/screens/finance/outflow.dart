import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:trashure_thesis/sidebar.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:trashure_thesis/user_model.dart';

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
              height: MediaQuery.of(context).size.height * 0.6,
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

                        return ListView.builder(
                          itemCount: outflowList.length,
                          itemBuilder: (context, index) {
                            final outflowData = outflowList[index].data()
                                as Map<String, dynamic>;
                            String category = outflowData['category'] ?? '';
                            Timestamp? timestamp = outflowData['date'];
                            String formattedDate = timestamp != null
                                ? DateFormat('MM/dd/yyyy, hh:mm a')
                                    .format(timestamp.toDate())
                                : '';
                            double price =
                                outflowData['price']?.toDouble() ?? 0.0;
                            double weight =
                                outflowData['weight']?.toDouble() ?? 0.0;
                            String employee = outflowData['employee'] ?? '';
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
                                  _buildText('₱${price.toStringAsFixed(2)}', 2),
                                  _buildText(
                                      '${weight.toStringAsFixed(2)} kg', 2),
                                  _buildText(employee, 2),
                                  _buildText(status, 2),
                                  _buildText(vehicle, 2),
                                ],
                              ),
                            );
                          },
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
}
