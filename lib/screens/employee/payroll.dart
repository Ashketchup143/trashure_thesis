import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:trashure_thesis/sidebar.dart';

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

  void _initializePayrollPeriod() {
    DateTime now = DateTime.now();
    if (now.day <= 15) {
      _selectedStartDate = DateTime(now.year, now.month, 1);
      _selectedEndDate = DateTime(now.year, now.month, 15);
    } else {
      _selectedStartDate = DateTime(now.year, now.month, 16);
      _selectedEndDate = DateTime(now.year, now.month + 1, 0);
    }
  }

  DateTime _lastDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }

  void _fetchPayrollData() async {
    if (_selectedStartDate == null || _selectedEndDate == null) {
      print('Selected start or end date is null');
      return;
    }

    QuerySnapshot employeeSnapshot =
        await FirebaseFirestore.instance.collection('employees').get();

    List<Map<String, dynamic>> tempPayrollDataWithHours = [];
    List<Map<String, dynamic>> tempPayrollDataWithoutHours = [];
    double tempTotalAmount = 0.0;

    for (var doc in employeeSnapshot.docs) {
      String employeeId = doc.id;
      String employeeName = doc['name'];
      double salaryPerDay = double.parse(doc['salary_per_day']);

      QuerySnapshot attendanceSnapshot = await FirebaseFirestore.instance
          .collection('employees')
          .doc(employeeId)
          .collection('daily_time_record')
          .where('time_in', isGreaterThanOrEqualTo: _selectedStartDate)
          .where('time_in', isLessThanOrEqualTo: _selectedEndDate)
          .get();

      double totalHours = 0.0;
      double totalPay = 0.0;

      for (var attendanceDoc in attendanceSnapshot.docs) {
        Timestamp? timeInTimestamp = attendanceDoc['time_in'];
        Timestamp? timeOutTimestamp = attendanceDoc['time_out'];

        if (timeInTimestamp != null && timeOutTimestamp != null) {
          DateTime timeIn = timeInTimestamp.toDate();
          DateTime timeOut = timeOutTimestamp.toDate();
          double hoursWorked = timeOut.difference(timeIn).inMinutes / 60.0;

          double dailyPay;
          if (hoursWorked >= 8) {
            double regularPay = salaryPerDay;
            double overtimeHours = hoursWorked - 8;
            double overtimeRate = (salaryPerDay / 8) * 1.05;
            double overtimePay = overtimeHours * overtimeRate;
            dailyPay = regularPay + overtimePay;
          } else {
            dailyPay = (salaryPerDay / 8) * hoursWorked;
          }

          totalHours += hoursWorked;
          totalPay += dailyPay;
        }
      }

      tempTotalAmount += totalPay;

      if (totalHours > 0) {
        tempPayrollDataWithHours.add({
          'name': employeeName,
          'total_hours': totalHours,
          'salary_per_day': salaryPerDay,
          'total_pay': totalPay,
        });
      } else {
        tempPayrollDataWithoutHours.add({
          'name': employeeName,
          'total_hours': 0.0,
          'salary_per_day': salaryPerDay,
          'total_pay': 0.0,
        });
      }
    }

    setState(() {
      _payrollDataWithHours = tempPayrollDataWithHours;
      _payrollDataWithoutHours = tempPayrollDataWithoutHours;
      _totalAmount = tempTotalAmount;
    });
  }

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

                  if (picked != null) {
                    setState(() {
                      _selectedStartDate = picked.start;
                      _selectedEndDate = picked.end;
                      _fetchPayrollData();
                    });
                    Navigator.pop(context);
                  }
                },
                child: Text("Choose Date Range"),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
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
      drawer: Sidebar(),
      appBar: AppBar(
        title: Text('Payroll'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
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
                  onPressed: () => _openPeriodSelector(context),
                  child: Text('Change Period'),
                ),
              ],
            ),
            SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: DataTable(
                  columns: [
                    DataColumn(label: Text('Employee Name')),
                    DataColumn(label: Text('Total Hours')),
                    DataColumn(label: Text('Salary/Day')),
                    DataColumn(label: Text('Total Pay')),
                  ],
                  rows: [
                    ..._payrollDataWithHours.map(
                      (data) => DataRow(cells: [
                        DataCell(Text(data['name'])),
                        DataCell(Text(data['total_hours'].toStringAsFixed(2))),
                        DataCell(Text(
                            currencyFormatter.format(data['salary_per_day']))),
                        DataCell(
                            Text(currencyFormatter.format(data['total_pay']))),
                      ]),
                    ),
                    ..._payrollDataWithoutHours.map(
                      (data) => DataRow(cells: [
                        DataCell(Text(data['name'])),
                        DataCell(Text('0.00')),
                        DataCell(Text(
                            currencyFormatter.format(data['salary_per_day']))),
                        DataCell(Text(currencyFormatter.format(0.0))),
                      ]),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
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
