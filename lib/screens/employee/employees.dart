import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:trashure_thesis/sidebar.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Employees extends StatefulWidget {
  const Employees({super.key});

  @override
  State<Employees> createState() => _EmployeesState();
}

class _EmployeesState extends State<Employees> {
  Map<String, bool> _selectedOptions = {};
  Map<String, bool> _attendanceStatus = {};
  List<Map<String, dynamic>> _employeesList = [];
  List<Map<String, dynamic>> _filteredEmployees = [];
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchEmployees();
    _searchController.addListener(_onSearchChanged);
  }

  void _fetchEmployees() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('employees')
        .where('status', isEqualTo: 'active')
        .get();

    List<Map<String, dynamic>> tempEmployeesList = snapshot.docs.map((doc) {
      return {
        'id': doc.id,
        'name': doc['name'],
        'position': doc['position'],
        'exp_time_in': doc['exp_time_in'],
        'exp_time_out': doc['exp_time_out'],
        'address': doc['address'],
        'birth_date': doc['birth_date'],
        'contact_number': doc['contact_number'],
        'email_address': doc['email_address'],
        'salary_per_day': double.parse(doc['salary_per_day']),
      };
    }).toList();

    Map<String, bool> tempAttendanceStatus = {};
    Map<String, bool> tempSelectedOptions = {};

    for (var employee in tempEmployeesList) {
      String employeeId = employee['id'];
      tempSelectedOptions[employeeId] = false;
      bool isClockedIn = await _checkIfClockedIn(employeeId);
      tempAttendanceStatus[employeeId] = isClockedIn;
    }

    setState(() {
      _employeesList = tempEmployeesList;
      _filteredEmployees = _employeesList;
      _attendanceStatus = tempAttendanceStatus;
      _selectedOptions = tempSelectedOptions;
    });
  }

  Future<bool> _checkIfClockedIn(String employeeId) async {
    try {
      DocumentReference employeeDocRef =
          FirebaseFirestore.instance.collection('employees').doc(employeeId);
      QuerySnapshot dtrSnapshot = await employeeDocRef
          .collection('daily_time_record')
          .where('time_out', isNull: true)
          .get();
      return dtrSnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking attendance status for $employeeId: $e');
      return false;
    }
  }

  void _onSearchChanged() {
    String searchTerm = _searchController.text.toLowerCase();
    setState(() {
      _filteredEmployees = _employeesList.where((employee) {
        return employee['name'].toLowerCase().contains(searchTerm) ||
            employee['position'].toLowerCase().contains(searchTerm) ||
            employee['id'].toLowerCase().contains(searchTerm);
      }).toList();
    });
  }

  Future<void> _timeIn(String employeeId) async {
    try {
      await FirebaseFirestore.instance
          .collection('employees')
          .doc(employeeId)
          .collection('daily_time_record')
          .add({
        'date': DateTime.now(),
        'time_in': FieldValue.serverTimestamp(),
        'time_out': null,
      });
    } catch (e) {
      print('Error during Time In: $e');
    }
  }

  Future<void> _timeOut(
      String employeeId, String employeeName, double salaryPerDay) async {
    try {
      QuerySnapshot dtrSnapshot = await FirebaseFirestore.instance
          .collection('employees')
          .doc(employeeId)
          .collection('daily_time_record')
          .where('time_out', isNull: true)
          .get();

      if (dtrSnapshot.docs.isNotEmpty) {
        DocumentReference dtrDocRef = dtrSnapshot.docs.first.reference;
        await dtrDocRef.update({
          'time_out': FieldValue.serverTimestamp(),
        });

        // Calculate pay after setting time_out
        _calculateAndShowDailyPay(employeeId, employeeName, salaryPerDay);
      }
    } catch (e) {
      print('Error during Time Out: $e');
    }
  }

  Future<void> _calculateAndShowDailyPay(
      String employeeId, String employeeName, double salaryPerDay) async {
    try {
      DateTime now = DateTime.now();
      DateTime startOfDay = DateTime(now.year, now.month, now.day, 0, 0, 0);
      DateTime endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      QuerySnapshot attendanceSnapshot = await FirebaseFirestore.instance
          .collection('employees')
          .doc(employeeId)
          .collection('daily_time_record')
          .where('time_in',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('time_in', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();

      if (attendanceSnapshot.docs.isEmpty) {
        _showPayModal(
            context, employeeId, employeeName, 0.0, salaryPerDay, 0.0);
        return;
      }

      double totalHoursWorked = 0.0;

      // Iterate through each time-in and time-out pair to calculate total hours worked
      for (var attendanceDoc in attendanceSnapshot.docs) {
        Timestamp timeInTimestamp = attendanceDoc['time_in'];
        Timestamp? timeOutTimestamp = attendanceDoc['time_out'];

        if (timeOutTimestamp != null) {
          DateTime timeIn = timeInTimestamp.toDate();
          DateTime timeOut = timeOutTimestamp.toDate();
          double hoursWorked = timeOut.difference(timeIn).inMinutes / 60.0;
          totalHoursWorked += hoursWorked;
        }
      }

      // Calculate total pay based on total hours worked
      double totalPay = 0.0;
      if (totalHoursWorked >= 8) {
        double regularPay = salaryPerDay;
        double overtimeHours = totalHoursWorked - 8;
        double overtimeRate = (salaryPerDay / 8) * 1.05;
        totalPay = regularPay + (overtimeHours * overtimeRate);
      } else {
        totalPay = (salaryPerDay / 8) * totalHoursWorked;
      }

      _showPayModal(context, employeeId, employeeName, totalHoursWorked,
          salaryPerDay, totalPay);
    } catch (e) {
      print('Error calculating daily pay for $employeeId: $e');
    }
  }

  void _showPayModal(
      BuildContext context,
      String employeeId,
      String employeeName,
      double hoursWorked,
      double salaryPerDay,
      double totalPay) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Daily Pay Calculation for $employeeName'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Hours Worked: ${hoursWorked.toStringAsFixed(2)}'),
              Text(
                  'Daily Salary Rate: ${NumberFormat.currency(symbol: "\$").format(salaryPerDay)}'),
              Text(
                  'Total Pay: ${NumberFormat.currency(symbol: "\$").format(totalPay)}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Close'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _recordPayment(employeeId, employeeName, totalPay);
                Navigator.pop(context); // Close the modal after payment
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Payment recorded for $employeeName')),
                );
              },
              child: Text('Pay'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _recordPayment(
      String employeeId, String employeeName, double totalPay) async {
    try {
      await FirebaseFirestore.instance.collection('outflow').add({
        'category': 'employee wage',
        'date': Timestamp.fromDate(DateTime.now()),
        'employee': employeeName,
        'employeeid': employeeId,
        'price': totalPay,
      });
      print('Payment recorded successfully in outflow.');
    } catch (e) {
      print('Error recording payment: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
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
                        Scaffold.of(context).openDrawer(); // Opens the drawer
                      },
                    );
                  },
                ),
                Text(
                  'Employees',
                  style: GoogleFonts.poppins(
                    textStyle: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  height: 30,
                  width: 430,
                  decoration: BoxDecoration(
                    border: Border.all(),
                    borderRadius: BorderRadius.circular(17.5),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search by employee name, id, or position',
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      _onSearchChanged();
                    },
                  ),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: () {
                    _addEmployee();
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
                        'Add Employee',
                        style: GoogleFonts.roboto(
                            textStyle: const TextStyle(
                                fontWeight: FontWeight.w300,
                                color: Colors.white)),
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
            Container(
              height: MediaQuery.of(context).size.height * 0.82,
              decoration: BoxDecoration(border: Border.all()),
              child: Column(
                children: [
                  Container(
                    child: Row(
                      children: [
                        title('Employee ID', 3),
                        title('Name', 3),
                        title('Position', 3),
                        title('Exp. Time In', 3),
                        title('Exp. Time Out', 3),
                        title('Attendance', 3),
                        title('Details', 2),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _filteredEmployees.length,
                      itemBuilder: (context, index) {
                        var employee = _filteredEmployees[index];
                        var employeeId = employee['id'];
                        var name = employee['name'];
                        var position = employee['position'];
                        var expTimeIn = employee['exp_time_in'];
                        var expTimeOut = employee['exp_time_out'];
                        double salaryPerDay = employee['salary_per_day'];

                        return CheckboxListTile(
                          value: _selectedOptions[employeeId],
                          activeColor: Colors.green,
                          onChanged: (bool? value) {
                            setState(() {
                              _selectedOptions[employeeId] = value!;
                            });
                          },
                          title: Row(
                            children: [
                              _buildText(employeeId, 2),
                              _buildTitleText(name, 2),
                              _buildText(position, 2),
                              _buildText(expTimeIn, 2),
                              _buildText(expTimeOut, 2),
                              Expanded(
                                flex: 2,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    if (_attendanceStatus[employeeId] == null ||
                                        !_attendanceStatus[employeeId]!) {
                                      await _timeIn(employeeId);
                                      setState(() {
                                        _attendanceStatus[employeeId] = true;
                                      });
                                    } else {
                                      await _timeOut(
                                          employeeId, name, salaryPerDay);
                                      setState(() {
                                        _attendanceStatus[employeeId] = false;
                                      });
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        _attendanceStatus[employeeId] == true
                                            ? Colors.red
                                            : Colors.blue,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(15)),
                                  ),
                                  child: Text(
                                    _attendanceStatus[employeeId] == true
                                        ? 'Time Out'
                                        : 'Time In',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                              const SizedBox(
                                  width:
                                      8), // Add some spacing between the buttons
                              ElevatedButton(
                                onPressed: () async {
                                  await _calculateAndShowDailyPay(
                                      employeeId, name, salaryPerDay);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15)),
                                ),
                                child: const Text(
                                  'Pay',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: IconButton(
                                  icon: const Icon(Icons.info_outline),
                                  onPressed: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/employeeprofile',
                                      arguments: employee,
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
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

  Widget title(String text, int flex) {
    return Expanded(
      flex: flex,
      child: Container(
        height: 20,
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide()),
        ),
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
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildTitleText(String text, int flex) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _addEmployee() {
    TextEditingController nameController = TextEditingController();
    TextEditingController contactController = TextEditingController();
    TextEditingController addressController = TextEditingController();
    TextEditingController emailController = TextEditingController();
    TextEditingController positionController = TextEditingController();
    TextEditingController salaryController = TextEditingController();
    TextEditingController birthDateController = TextEditingController();
    TextEditingController expTimeInController = TextEditingController();
    TextEditingController expTimeOutController = TextEditingController();
    TextEditingController passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Employee'),
          content: SingleChildScrollView(
            child: Container(
              height: 600,
              width: MediaQuery.of(context).size.width * 0.4,
              child: Column(
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  TextField(
                    controller: contactController,
                    decoration:
                        const InputDecoration(labelText: 'Contact Number'),
                  ),
                  TextField(
                    controller: addressController,
                    decoration: const InputDecoration(labelText: 'Address'),
                  ),
                  TextField(
                    controller: emailController,
                    decoration:
                        const InputDecoration(labelText: 'Email Address'),
                  ),
                  TextField(
                    controller: passwordController,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                  ),
                  TextField(
                    controller: positionController,
                    decoration: const InputDecoration(labelText: 'Position'),
                  ),
                  TextField(
                    controller: salaryController,
                    decoration:
                        const InputDecoration(labelText: 'Salary Per Day'),
                  ),
                  TextField(
                    controller: birthDateController,
                    decoration: const InputDecoration(labelText: 'Birth Date'),
                  ),
                  TextField(
                    controller: expTimeInController,
                    decoration: const InputDecoration(
                        labelText: 'Expected Time In (Optional)'),
                  ),
                  TextField(
                    controller: expTimeOutController,
                    decoration: const InputDecoration(
                        labelText: 'Expected Time Out (Optional)'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty ||
                    contactController.text.isEmpty ||
                    addressController.text.isEmpty ||
                    emailController.text.isEmpty ||
                    passwordController.text.isEmpty ||
                    positionController.text.isEmpty ||
                    salaryController.text.isEmpty ||
                    birthDateController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Please fill in all required fields')));
                  return;
                }

                try {
                  UserCredential userCredential = await FirebaseAuth.instance
                      .createUserWithEmailAndPassword(
                    email: emailController.text,
                    password: passwordController.text,
                  );
                  String userUid = userCredential.user!.uid;

                  await FirebaseFirestore.instance.collection('employees').add({
                    'uid': userUid,
                    'name': nameController.text,
                    'contact_number': contactController.text,
                    'address': addressController.text,
                    'email_address': emailController.text,
                    'position': positionController.text,
                    'salary_per_day': salaryController.text,
                    'password': passwordController.text,
                    'birth_date': birthDateController.text,
                    'exp_time_in': expTimeInController.text.isNotEmpty
                        ? expTimeInController.text
                        : "",
                    'exp_time_out': expTimeOutController.text.isNotEmpty
                        ? expTimeOutController.text
                        : "",
                    'status': 'active',
                  });

                  Navigator.of(context).pop();
                  _fetchEmployees();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to add employee: $e')),
                  );
                }
              },
              child: const Text('Add Employee'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF4F)),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}
