import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class VehicleInformation extends StatefulWidget {
  @override
  _VehicleInformationState createState() => _VehicleInformationState();
}

class _VehicleInformationState extends State<VehicleInformation> {
  Map<String, dynamic>? vehicleData;
  Map<String, dynamic>? originalData;
  String assignedDriver = 'N/A'; // To hold the latest assigned driver
  bool isEditing = false;
  Map<String, TextEditingController> controllers = {};
  List<Map<String, dynamic>> bookings = []; // List to hold booking data

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    vehicleData =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (vehicleData != null) {
      _fetchAssignedDriver(vehicleData!['id']);
      _initializeControllers(vehicleData!);
      originalData = Map.from(vehicleData!); // Copy original data
      _fetchBookingsForVehicle(
          vehicleData!['id']); // Fetch bookings for the vehicle
    }
  }

  // Fetch the latest assigned driver
  Future<void> _fetchAssignedDriver(String vehicleId) async {
    QuerySnapshot driverSnapshot = await FirebaseFirestore.instance
        .collection('vehicles')
        .doc(vehicleId)
        .collection('drivers')
        .orderBy('time', descending: true)
        .limit(1)
        .get();

    if (driverSnapshot.docs.isNotEmpty) {
      var driverDoc = driverSnapshot.docs.first;
      Map<String, dynamic> driverData =
          driverDoc.data() as Map<String, dynamic>;

      setState(() {
        assignedDriver = driverData['assigned_driver'] ?? 'N/A';
      });
    }
  }

  // Fetch all bookings associated with the vehicle
  Future<void> _fetchBookingsForVehicle(String vehicleId) async {
    QuerySnapshot bookingsSnapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where('vehicleId', isEqualTo: vehicleId)
        .get();

    List<Map<String, dynamic>> fetchedBookings = bookingsSnapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();

    setState(() {
      bookings = fetchedBookings;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (vehicleData == null) {
      return Scaffold(
        appBar: AppBar(
          iconTheme: IconThemeData(color: Colors.white),
          title: Text('Vehicle Information'),
        ),
        body: Center(
          child: Text('No vehicle data available'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Colors.green,
        title: Text(
          'Vehicle Information',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isEditing ? Icons.save : Icons.edit,
              color: Colors.white,
            ),
            onPressed: () {
              if (isEditing) {
                _updateVehicleData(); // Save changes
              } else {
                setState(() {
                  isEditing = true; // Switch to edit mode
                });
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildVehicleDetail('Vehicle ID', vehicleData!['id']),
                        buildVehicleDetail('Assigned Driver', assignedDriver),
                        buildEditableVehicleDetail('Brand', 'brand'),
                        buildEditableVehicleDetail('Color', 'color'),
                        buildEditableVehicleDetail('Fuel Type', 'fuel_type'),
                        buildEditableVehicleDetail(
                            'License Plate Number', 'license_plate_number'),
                        buildEditableVehicleDetail('Model', 'model'),
                        buildEditableVehicleDetail(
                            'Vehicle Type', 'vehicle_type'),
                      ],
                    ),
                  ),
                  SizedBox(width: 16.0), // Space between the two columns
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildEditableVehicleDetail(
                            'Weight Limit', 'weight_limit',
                            isNumber: true),
                        buildEditableVehicleDetail(
                            'Last Service Date', 'last_service_date'),
                        buildEditableVehicleDetail('Next Scheduled Maintenance',
                            'next_scheduled_maintenance'),
                        buildEditableVehicleDetail(
                            'Purchase Date', 'purchase_date'),
                        buildEditableVehicleDetail('Registration Expire Date',
                            'registration_expire_date'),
                        buildEditableVehicleDetail(
                            'Registration Number', 'registration_number'),
                        buildEditableVehicleDetail(
                            'Year of Manufacture', 'year_of_manufacture'),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              // Container to display bookings related to this vehicle
              bookings.isNotEmpty
                  ? Container(
                      padding: EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        border: Border.all(),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Related Bookings',
                            style: GoogleFonts.roboto(
                              textStyle: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          SizedBox(height: 10),
                          ...bookings.map((booking) {
                            return ListTile(
                              title: Text(
                                  'Date: ${_formatDate(booking['date']?.toDate() ?? DateTime(1970))}'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Status: ${booking['status'] ?? 'N/A'}'),
                                  Text(
                                      'Driver: ${booking['driver'] ?? 'No Driver Assigned'}'),
                                  Text(
                                      'Vehicle: ${booking['vehicle'] ?? 'No Vehicle Assigned'}'),
                                  Text(
                                      'Overall Price: ₱${booking['overall_price'] ?? 0}'),
                                  Text(
                                      'Overall Weight: ${booking['overall_weight'] ?? 0} kg'),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    )
                  : Center(
                      child: Padding(
                      padding: const EdgeInsets.only(top: 50),
                      child: Text('No bookings related to this vehicle'),
                    )),
            ],
          ),
        ),
      ),
    );
  }

  // Helper to format date
  String _formatDate(DateTime date) {
    return DateFormat('MMMM d, yyyy').format(date);
  }

  // Build editable fields
  Widget buildEditableVehicleDetail(String label, String fieldKey,
      {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.roboto(
              textStyle: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: isEditing
                ? TextFormField(
                    controller: controllers[fieldKey],
                    keyboardType: isNumber ? TextInputType.number : null,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  )
                : Text(
                    controllers[fieldKey]!.text,
                    style: GoogleFonts.roboto(),
                  ),
          ),
        ],
      ),
    );
  }

  // Build static fields
  Widget buildVehicleDetail(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.roboto(
              textStyle: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: GoogleFonts.roboto(),
            ),
          ),
        ],
      ),
    );
  }

  void _showDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Check if the data has changed before updating Firestore
  bool _hasDataChanged() {
    return controllers['brand']!.text != originalData!['brand'] ||
        controllers['color']!.text != originalData!['color'] ||
        controllers['fuel_type']!.text != originalData!['fuel_type'] ||
        controllers['license_plate_number']!.text !=
            originalData!['license_plate_number'] ||
        controllers['model']!.text != originalData!['model'] ||
        controllers['vehicle_type']!.text != originalData!['vehicle_type'] ||
        controllers['weight_limit']!.text !=
            originalData!['weight_limit'].toString() ||
        controllers['last_service_date']!.text !=
            originalData!['last_service_date'] ||
        controllers['next_scheduled_maintenance']!.text !=
            originalData!['next_scheduled_maintenance'] ||
        controllers['purchase_date']!.text != originalData!['purchase_date'] ||
        controllers['registration_expire_date']!.text !=
            originalData!['registration_expire_date'] ||
        controllers['registration_number']!.text !=
            originalData!['registration_number'] ||
        controllers['year_of_manufacture']!.text !=
            originalData!['year_of_manufacture'];
  }

  // Update vehicle data in Firestore only if there are changes
  Future<void> _updateVehicleData() async {
    if (vehicleData == null || !_hasDataChanged()) {
      _showDialog('No changes', 'No information has been changed.');
      // If there are no changes, don't update Firestore
      setState(() {
        isEditing = false; // Exit edit mode
      });
      return;
    }

    String vehicleId = vehicleData!['id'];

    Map<String, dynamic> updatedData = {
      'brand': controllers['brand']!.text,
      'color': controllers['color']!.text,
      'fuel_type': controllers['fuel_type']!.text,
      'license_plate_number': controllers['license_plate_number']!.text,
      'model': controllers['model']!.text,
      'vehicle_type': controllers['vehicle_type']!.text,
      'weight_limit': double.tryParse(controllers['weight_limit']!.text) ?? 0.0,
      'last_service_date': controllers['last_service_date']!.text,
      'next_scheduled_maintenance':
          controllers['next_scheduled_maintenance']!.text,
      'purchase_date': controllers['purchase_date']!.text,
      'registration_expire_date': controllers['registration_expire_date']!.text,
      'registration_number': controllers['registration_number']!.text,
      'year_of_manufacture': controllers['year_of_manufacture']!.text,
    };

    await FirebaseFirestore.instance
        .collection('vehicles')
        .doc(vehicleId)
        .update(updatedData);

    setState(() {
      isEditing = false; // Exit edit mode after saving
      originalData = Map.from(updatedData); // Update originalData after saving
    });
  }

  // Initialize TextEditingControllers for each field, using default values for null
  void _initializeControllers(Map<String, dynamic> data) {
    controllers['brand'] = TextEditingController(text: data['brand'] ?? '');
    controllers['color'] = TextEditingController(text: data['color'] ?? '');
    controllers['fuel_type'] =
        TextEditingController(text: data['fuel_type'] ?? '');
    controllers['license_plate_number'] =
        TextEditingController(text: data['license_plate_number'] ?? '');
    controllers['model'] = TextEditingController(text: data['model'] ?? '');
    controllers['vehicle_type'] =
        TextEditingController(text: data['vehicle_type'] ?? '');
    controllers['weight_limit'] = TextEditingController(
        text: data['weight_limit']?.toString() ?? ''); // Ensure it's a string
    controllers['last_service_date'] =
        TextEditingController(text: data['last_service_date'] ?? '');
    controllers['next_scheduled_maintenance'] =
        TextEditingController(text: data['next_scheduled_maintenance'] ?? '');
    controllers['purchase_date'] =
        TextEditingController(text: data['purchase_date'] ?? '');
    controllers['registration_expire_date'] =
        TextEditingController(text: data['registration_expire_date'] ?? '');
    controllers['registration_number'] =
        TextEditingController(text: data['registration_number'] ?? '');
    controllers['year_of_manufacture'] =
        TextEditingController(text: data['year_of_manufacture'] ?? '');
  }
}
