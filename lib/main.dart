import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:trashure_thesis/screens/booking/booking.dart';
import 'package:trashure_thesis/screens/dashboard.dart';
import 'package:trashure_thesis/screens/driver/driver.dart';
import 'package:trashure_thesis/screens/driver/driverbookingdetails.dart';
import 'package:trashure_thesis/screens/driver/drivertransaction.dart';
import 'package:trashure_thesis/screens/driver/drivertransactiondetails.dart';
import 'package:trashure_thesis/screens/employee/employeeprofile.dart';
import 'package:trashure_thesis/screens/employee/employees.dart';
import 'package:trashure_thesis/screens/employee/payroll.dart';
import 'package:trashure_thesis/screens/finance/finance.dart';
import 'package:trashure_thesis/screens/finance/inflow.dart';
import 'package:trashure_thesis/screens/finance/outflow.dart';
import 'package:trashure_thesis/screens/inventory/inventory.dart';
import 'package:trashure_thesis/screens/login.dart';
import 'package:trashure_thesis/screens/users/userbusiness.dart';
import 'package:trashure_thesis/screens/users/userhouse.dart';
import 'package:trashure_thesis/screens/users/userinformation.dart';
import 'package:trashure_thesis/screens/users/users.dart';
import 'package:trashure_thesis/screens/products.dart';
import 'package:trashure_thesis/screens/vehicle/vehicle.dart';
import 'package:trashure_thesis/screens/vehicle/vehicleinformation.dart';
import 'package:trashure_thesis/user_model.dart';
import 'firebase_options.dart';
import 'package:flutter/foundation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: kIsWeb ? firebaseConfig : null,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => UserModel(), // Provide UserModel globally
      child: MaterialApp(
        title: 'TRASHURE',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        initialRoute: '/login', // Set initial route to the login screen
        debugShowCheckedModeBanner: false,
        routes: {
          '/': (context) => Booking(),
          '/login': (context) => Login(),
          '/dashboard': (context) => Dashboard(),
          '/users': (context) => Users(),
          '/bookings': (context) => Booking(),
          '/vehicle': (context) => Vehicle(),
          '/employee': (context) => Employees(),
          '/inventory': (context) => Inventory(),
          '/finance': (context) => Finance(),

          '/userhouse': (context) => UserHouse(),
          '/userbusiness': (context) => UserBusiness(),
          '/employeeprofile': (context) => EmployeeProfileScreen(),
          '/vehicleinformation': (context) => VehicleInformation(),
          '/userinformation': (context) => UserInformation(),
          // '/map': (context) => Maps(),
          '/finance': (context) => Finance(),
          '/inflow': (context) => Inflow(),
          '/outflow': (context) => Outflow(),
          '/settings': (context) => Products(),
          // '/schedule': (context) => Schedule(),
          '/driver': (context) => Driver(),
          '/driverbookingdetails': (context) => DriverBookingDetails(),
          '/payroll': (context) => PayrollScreen(),
          '/drivertransactions': (context) => DriverTransactions(),
          '/drivertransactiondetails': (context) => DriverTransactionDetails()
        },
      ),
    );
  }
}
