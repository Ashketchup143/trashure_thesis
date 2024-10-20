import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PayrollScreen extends StatefulWidget {
  @override
  _PayrollScreenState createState() => _PayrollScreenState();
}

class _PayrollScreenState extends State<PayrollScreen> {
  List<Map<String, dynamic>> _payrollDataWithHours = [];
  List<Map<String, dynamic>> _payrollDataWithoutHours = [];
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

  // Helper function to get the last day of the month
  DateTime _lastDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }

  // Fetch payroll data for the selected period
  void _fetchPayrollData() async {
    if (_selectedStartDate == null || _selectedEndDate == null) {
      print('Selected start or end date is null');
      return;
    }

    QuerySnapshot employeeSnapshot =
        await FirebaseFirestore.instance.collection('employees').get();
    print('Fetched ${employeeSnapshot.docs.length} employees');

    List<Map<String, dynamic>> tempPayrollDataWithHours = [];
    List<Map<String, dynamic>> tempPayrollDataWithoutHours = [];
    double tempTotalAmount = 0.0;

    for (var doc in employeeSnapshot.docs) {
      String employeeId = doc.id;
      String employeeName = doc['name'];
      double salaryPerHour = double.parse(doc['salary_per_hour']);

      print('Processing payroll for employee: $employeeName');

      // Fetch attendance records for the selected period
      QuerySnapshot attendanceSnapshot = await FirebaseFirestore.instance
          .collection('employees')
          .doc(employeeId)
          .collection('daily_time_record')
          .where('time_in', isGreaterThanOrEqualTo: _selectedStartDate)
          .where('time_in', isLessThanOrEqualTo: _selectedEndDate)
          .get();

      print(
          'Fetched ${attendanceSnapshot.docs.length} attendance records for $employeeName');

      double totalHours = 0.0;

      // Iterate through the attendance records
      for (var attendanceDoc in attendanceSnapshot.docs) {
        Timestamp? timeInTimestamp = attendanceDoc['time_in'];
        Timestamp? timeOutTimestamp = attendanceDoc['time_out'];

        // Ensure both time_in and time_out are present
        if (timeInTimestamp != null && timeOutTimestamp != null) {
          DateTime timeIn = timeInTimestamp.toDate();
          DateTime timeOut = timeOutTimestamp.toDate();

          // Set 5 PM on the time_in day
          DateTime fivePM =
              DateTime(timeIn.year, timeIn.month, timeIn.day, 17, 0);

          if (timeIn.day != timeOut.day) {
            // If time_out is on a different day than time_in, cap the time_out to 5 PM of time_in day
            timeOut = fivePM;
            print('Capped time_out to 5 PM for employee $employeeName');
          }

          // Calculate the number of hours worked for this record, including partial hours
          double hoursWorked = timeOut.difference(timeIn).inMinutes / 60.0;
          totalHours += hoursWorked;
          print('Worked $hoursWorked hours for this record');
        } else {
          print(
              'Skipping record for employee $employeeName because time_out is missing');
        }
      }

      double totalPay = totalHours * salaryPerHour;
      tempTotalAmount += totalPay;

      // Separate employees with and without recorded hours
      if (totalHours > 0) {
        // Employees with recorded hours
        tempPayrollDataWithHours.add({
          'name': employeeName,
          'total_hours': totalHours,
          'salary_per_hour': salaryPerHour,
          'total_pay': totalPay,
        });
      } else {
        // Employees with 0 hours
        tempPayrollDataWithoutHours.add({
          'name': employeeName,
          'total_hours': 0.0,
          'salary_per_hour': salaryPerHour,
          'total_pay': 0.0,
        });
      }
    }

    setState(() {
      _payrollDataWithHours = tempPayrollDataWithHours;
      _payrollDataWithoutHours = tempPayrollDataWithoutHours;
      _totalAmount = tempTotalAmount;
    });

    print('Total payroll to be paid: $tempTotalAmount');
  }

  // Open a dialog in the center of the screen to allow date range selection
  void _openPeriodSelector(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Select Payroll Period"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () async {
                  // Open DateRangePicker to select period
                  final DateTimeRange? picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    initialDateRange:
                        _selectedStartDate != null && _selectedEndDate != null
                            ? DateTimeRange(
                                start: _selectedStartDate!,
                                end: _selectedEndDate!)
                            : DateTimeRange(
                                start: DateTime.now().day <= 15
                                    ? DateTime(DateTime.now().year,
                                        DateTime.now().month, 1)
                                    : DateTime(DateTime.now().year,
                                        DateTime.now().month, 16),
                                end: DateTime.now().day <= 15
                                    ? DateTime(DateTime.now().year,
                                        DateTime.now().month, 15)
                                    : _lastDayOfMonth(DateTime.now()),
                              ),
                  );

                  // If the user selected a range, update the selected period
                  if (picked != null) {
                    setState(() {
                      _selectedStartDate = picked.start;
                      _selectedEndDate = picked.end;
                      _fetchPayrollData(); // Fetch payroll data for the new period
                    });
                    Navigator.pop(context); // Close the dialog
                  }
                },
                child: Text("Choose Date Range"),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(
                      context); // Close the dialog without making changes
                },
                child: Text("Cancel"),
              ),
            ],
          ),
        );
      },
    );
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
                  onPressed: () =>
                      _openPeriodSelector(context), // Open modal dialog
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
                  rows: [
                    ..._payrollDataWithHours.map(
                      (data) => DataRow(cells: [
                        DataCell(Text(data['name'])),
                        DataCell(Text(data['total_hours'].toStringAsFixed(2))),
                        DataCell(Text(
                            currencyFormatter.format(data['salary_per_hour']))),
                        DataCell(
                            Text(currencyFormatter.format(data['total_pay']))),
                      ]),
                    ),
                    // Employees with no recorded hours
                    ..._payrollDataWithoutHours.map(
                      (data) => DataRow(cells: [
                        DataCell(Text(data['name'])),
                        DataCell(Text('0.00')),
                        DataCell(Text(
                            currencyFormatter.format(data['salary_per_hour']))),
                        DataCell(Text(currencyFormatter.format(0.0))),
                      ]),
                    ),
                  ],
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
