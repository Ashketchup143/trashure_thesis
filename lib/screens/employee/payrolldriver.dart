import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DriverPayrollScreen extends StatefulWidget {
  const DriverPayrollScreen({Key? key}) : super(key: key);

  @override
  _DriverPayrollScreenState createState() => _DriverPayrollScreenState();
}

class _DriverPayrollScreenState extends State<DriverPayrollScreen> {
  String selectedDriverType = "all"; // Dropdown filter state
  DateTime? fromDate;
  DateTime? toDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: const Text(
          "Driver Payroll Management",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                const Text(
                  "Filter by:",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: selectedDriverType,
                  onChanged: (value) {
                    setState(() {
                      selectedDriverType = value!;
                    });
                  },
                  items: const [
                    DropdownMenuItem(value: "all", child: Text("All")),
                    DropdownMenuItem(value: "driver", child: Text("Drivers")),
                    DropdownMenuItem(
                        value: "contractual driver",
                        child: Text("Contractual Drivers")),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: () => _selectDate(context, isFrom: true),
                  child: Text(fromDate == null
                      ? "From Date"
                      : DateFormat('yyyy-MM-dd').format(fromDate!)),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => _selectDate(context, isFrom: false),
                  child: Text(toDate == null
                      ? "To Date"
                      : DateFormat('yyyy-MM-dd').format(toDate!)),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance.collection('employees').where(
                  'position',
                  whereIn: ['driver', 'contractual driver']).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var employees = snapshot.data?.docs ?? [];

                // Apply filtering based on selectedDriverType
                if (selectedDriverType != "all") {
                  employees = employees.where((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    return data['position'] == selectedDriverType;
                  }).toList();
                }

                // Check if each employee has a payslip subcollection
                return FutureBuilder(
                  future: Future.wait(
                    employees.map((doc) async {
                      var payslipSnapshot = await FirebaseFirestore.instance
                          .collection('employees')
                          .doc(doc.id)
                          .collection('payslip')
                          .get();
                      return payslipSnapshot.docs.isNotEmpty ? doc : null;
                    }),
                  ),
                  builder: (context,
                      AsyncSnapshot<List<DocumentSnapshot?>> futureSnapshot) {
                    if (!futureSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    // Filter out employees without payslip subcollection
                    var filteredEmployees = futureSnapshot.data
                            ?.where((doc) => doc != null)
                            .toList() ??
                        [];

                    if (filteredEmployees.isEmpty) {
                      return const Center(
                          child: Text("No drivers with payslips found."));
                    }

                    return ListView.builder(
                      itemCount: filteredEmployees.length,
                      itemBuilder: (context, index) {
                        var employee = filteredEmployees[index]!;
                        var employeeData =
                            employee.data() as Map<String, dynamic>;
                        String employeeName = employeeData['name'] ?? 'Unknown';
                        String employeeId = employee.id;

                        return Card(
                          child: ListTile(
                            title: Text(employeeName),
                            subtitle: Text("ID: $employeeId"),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    _showPayslips(context, employeeId,
                                        "pending", fromDate, toDate);
                                  },
                                  child: const Text(
                                    "Payslips",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue),
                                ),
                                const SizedBox(width: 10),
                                ElevatedButton(
                                  onPressed: () {
                                    _showPayslips(context, employeeId, "paid",
                                        fromDate, toDate);
                                  },
                                  child: const Text(
                                    "Paid",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, {required bool isFrom}) async {
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (selectedDate != null) {
      setState(() {
        if (isFrom) {
          fromDate = selectedDate;
        } else {
          toDate = selectedDate;
        }
      });
    }
  }

  void _showPayslips(BuildContext context, String employeeId, String status,
      DateTime? fromDate, DateTime? toDate) async {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                "${status == 'paid' ? 'Paid' : 'Pending'} Payslips",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              content: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('employees')
                    .doc(employeeId)
                    .collection('payslip')
                    .where('status', isEqualTo: status)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  var payslips = snapshot.data?.docs ?? [];

                  // Filter by date range
                  if (fromDate != null && toDate != null) {
                    payslips = payslips.where((doc) {
                      var data = doc.data() as Map<String, dynamic>;
                      Timestamp? date = data['date'];
                      if (date == null) return false;
                      DateTime docDate = date.toDate();
                      return docDate.isAfter(fromDate) &&
                          docDate.isBefore(toDate!.add(Duration(days: 1)));
                    }).toList();
                  }

                  if (payslips.isEmpty) {
                    return SizedBox(
                      height: 50,
                      child: Center(
                        child: Text(
                          "No ${status == 'paid' ? 'paid' : 'pending'} payslips found.",
                        ),
                      ),
                    );
                  }

                  // Calculate total amount
                  double totalAmount = payslips.fold(0.0, (sum, doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    return sum + (data['price']?.toDouble() ?? 0.0);
                  });

                  return SizedBox(
                    width: MediaQuery.of(context).size.width * 0.8,
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            itemCount: payslips.length,
                            itemBuilder: (context, index) {
                              var payslip = payslips[index];
                              var payslipData =
                                  payslip.data() as Map<String, dynamic>;

                              // Convert Timestamp to DateTime and format it
                              String formattedDate = "Unknown Date";
                              if (payslipData['date'] != null &&
                                  payslipData['date'] is Timestamp) {
                                DateTime date =
                                    (payslipData['date'] as Timestamp).toDate();
                                formattedDate =
                                    DateFormat('MMMM dd, yyyy').format(date);
                              }

                              return Card(
                                child: ListTile(
                                  title: Text(
                                    "Date: $formattedDate",
                                  ),
                                  subtitle: Text(
                                    "Amount: ₱${payslipData['price']?.toStringAsFixed(2) ?? '0.00'}\n"
                                    "Vehicle: ${payslipData['vehicle'] ?? 'Unknown'}",
                                  ),
                                  trailing: status == "pending"
                                      ? IconButton(
                                          icon: const Icon(Icons.check,
                                              color: Colors.green),
                                          onPressed: () async {
                                            await _markAsPaid(employeeId,
                                                payslip.id, payslipData);
                                            setState(() {}); // Refresh dialog
                                          },
                                        )
                                      : null,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Total Amount: ₱${totalAmount.toStringAsFixed(2)}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (status == "pending")
                              ElevatedButton(
                                onPressed: () async {
                                  await _markAllAsPaid(employeeId, payslips);
                                  Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                                child: const Text("Pay All"),
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the modal
                  },
                  child: const Text("Close"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _markAsPaid(String employeeId, String payslipId,
      Map<String, dynamic> payslipData) async {
    try {
      // Fetch the employee's name from Firestore
      String employeeName = 'Unknown';
      var employeeDoc = await FirebaseFirestore.instance
          .collection('employees')
          .doc(employeeId)
          .get();

      if (employeeDoc.exists) {
        var employeeData = employeeDoc.data() as Map<String, dynamic>;
        employeeName = employeeData['name'] ?? 'Unknown';
      }

      // Update payslip status to "paid"
      await FirebaseFirestore.instance
          .collection('employees')
          .doc(employeeId)
          .collection('payslip')
          .doc(payslipId)
          .update({
        'status': 'paid',
        'paid_date': Timestamp.now(),
      });

      // Create outflow for driver share
      await FirebaseFirestore.instance.collection('outflow').add({
        'date': Timestamp.now(),
        'price': payslipData['price']?.toDouble() ?? 0.0,
        'vehicle': payslipData['vehicle'] ?? 'Unknown',
        'vehicleId': payslipData['vehicleId'] ?? 'Unknown',
        'employee': employeeName,
        'employeeId': employeeId,
        'bookingId': payslipData['bookingId'] ?? 'Unknown',
        'category': 'driver share',
      });

      // Show success modal
      _showSuccessModal(context, 'Payslip marked as paid successfully!');
    } catch (e) {
      _showErrorModal(context, 'Error marking payslip as paid: $e');
    }
  }

  Future<void> _markAllAsPaid(
      String employeeId, List<QueryDocumentSnapshot> payslips) async {
    try {
      var batch = FirebaseFirestore.instance.batch();
      double totalPrice = 0.0;
      String employeeName = 'Unknown';

      // Fetch the employee's name from Firestore
      var employeeDoc = await FirebaseFirestore.instance
          .collection('employees')
          .doc(employeeId)
          .get();

      if (employeeDoc.exists) {
        var employeeData = employeeDoc.data() as Map<String, dynamic>;
        employeeName = employeeData['name'] ?? 'Unknown';
      }

      for (var payslip in payslips) {
        var payslipData = payslip.data() as Map<String, dynamic>;

        // Update payslip status to "paid"
        var payslipRef = FirebaseFirestore.instance
            .collection('employees')
            .doc(employeeId)
            .collection('payslip')
            .doc(payslip.id);

        batch.update(payslipRef, {
          'status': 'paid',
          'paid_date': Timestamp.now(),
        });

        // Sum up total price
        totalPrice += payslipData['price']?.toDouble() ?? 0.0;
      }

      // Commit the batch update for all payslips
      await batch.commit();

      // Create a single outflow entry
      await FirebaseFirestore.instance.collection('outflow').add({
        'date': Timestamp.now(),
        'price': totalPrice,
        'employee': employeeName,
        'employeeId': employeeId,
        'category': 'driver share',
      });

      // Show success modal
      _showSuccessModal(
          context, 'All pending payslips marked as paid successfully!');
    } catch (e) {
      _showErrorModal(context, 'Error marking all payslips as paid: $e');
    }
  }

  void _showSuccessModal(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            "Success",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the modal
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void _showErrorModal(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            "Error",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the modal
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }
}
