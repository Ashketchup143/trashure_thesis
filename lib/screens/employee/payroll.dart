import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PayrollScreen extends StatefulWidget {
  @override
  _PayrollScreenState createState() => _PayrollScreenState();
}

class _PayrollScreenState extends State<PayrollScreen> {
  List<Map<String, dynamic>> _payrollData = [];
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  double _totalAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _initializePayrollPeriod(); // Initialize the payroll period
    _fetchPayrollData(); // Fetch payroll data
  }

  // Initializes the payroll period (1st to 15th or 16th to last day of the month)
  void _initializePayrollPeriod() {
    DateTime now = DateTime.now();
    if (now.day <= 15) {
      _selectedStartDate = DateTime(now.year, now.month, 1);
      _selectedEndDate = DateTime(now.year, now.month, 15);
    } else {
      _selectedStartDate = DateTime(now.year, now.month, 16);
      _selectedEndDate =
          DateTime(now.year, now.month + 1, 0); // Last day of the month
    }
  }

  // Fetch payroll data for the selected period
  void _fetchPayrollData() async {
    if (_selectedStartDate == null || _selectedEndDate == null) return;

    QuerySnapshot employeeSnapshot =
        await FirebaseFirestore.instance.collection('employees').get();

    List<Map<String, dynamic>> tempPayrollData = [];
    double tempTotalAmount = 0.0;

    for (var doc in employeeSnapshot.docs) {
      String employeeId = doc.id;
      String employeeName = doc['name'];
      double salaryPerHour = double.parse(doc['salary_per_hour']);

      // Fetch attendance records for the selected period
      QuerySnapshot attendanceSnapshot = await FirebaseFirestore.instance
          .collection('employees')
          .doc(employeeId)
          .collection('daily_time_record')
          .where('time_in', isGreaterThanOrEqualTo: _selectedStartDate)
          .where('time_in', isLessThanOrEqualTo: _selectedEndDate)
          .get();

      double totalHours = 0.0;

      for (var attendanceDoc in attendanceSnapshot.docs) {
        Timestamp timeInTimestamp = attendanceDoc['time_in'];
        Timestamp timeOutTimestamp = attendanceDoc['time_out'];

        if (timeInTimestamp != null && timeOutTimestamp != null) {
          DateTime timeIn = timeInTimestamp.toDate();
          DateTime timeOut = timeOutTimestamp.toDate();
          double hoursWorked = timeOut.difference(timeIn).inMinutes / 60.0;
          totalHours += hoursWorked;
        }
      }

      double totalPay = totalHours * salaryPerHour;
      tempTotalAmount += totalPay;

      tempPayrollData.add({
        'name': employeeName,
        'total_hours': totalHours,
        'salary_per_hour': salaryPerHour,
        'total_pay': totalPay,
      });
    }

    setState(() {
      _payrollData = tempPayrollData;
      _totalAmount = tempTotalAmount;
    });
  }

  // Allow the user to select a custom payroll period
  void _selectPayrollPeriod() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedStartDate != null && _selectedEndDate != null
          ? DateTimeRange(start: _selectedStartDate!, end: _selectedEndDate!)
          : DateTimeRange(start: DateTime.now(), end: DateTime.now()),
    );
    if (picked != null) {
      setState(() {
        _selectedStartDate = picked.start;
        _selectedEndDate = picked.end;
        _fetchPayrollData();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(symbol: '\$');

    return Scaffold(
      appBar: AppBar(
        title: Text('Payroll'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Payroll Period Selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedStartDate != null && _selectedEndDate != null
                      ? 'Payroll Period: ${DateFormat('MMM dd').format(_selectedStartDate!)} - ${DateFormat('MMM dd').format(_selectedEndDate!)}'
                      : 'Select Payroll Period',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ElevatedButton(
                  onPressed:
                      _selectPayrollPeriod, // Method to change the payroll period
                  child: Text('Change Period'),
                ),
              ],
            ),
            SizedBox(height: 20),
            // Data Table to display payroll data
            Expanded(
              child: SingleChildScrollView(
                child: DataTable(
                  columns: [
                    DataColumn(label: Text('Employee Name')),
                    DataColumn(label: Text('Total Hours')),
                    DataColumn(label: Text('Salary/Hour')),
                    DataColumn(label: Text('Total Pay')),
                  ],
                  rows: _payrollData
                      .map(
                        (data) => DataRow(cells: [
                          DataCell(Text(data['name'])),
                          DataCell(
                              Text(data['total_hours'].toStringAsFixed(2))),
                          DataCell(Text(currencyFormatter
                              .format(data['salary_per_hour']))),
                          DataCell(Text(
                              currencyFormatter.format(data['total_pay']))),
                        ]),
                      )
                      .toList(),
                ),
              ),
            ),
            SizedBox(height: 20),
            // Total Amount Display
            Text(
              'Total Amount to be Paid: ${currencyFormatter.format(_totalAmount)}',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
