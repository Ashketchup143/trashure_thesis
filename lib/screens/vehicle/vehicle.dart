import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:trashure_thesis/sidebar.dart';

//if you want to restructure the date format
//String formattedDate = DateFormat('MM/dd/yyyy').format(assignedTime);

class Vehicle extends StatefulWidget {
  const Vehicle({super.key});

  @override
  State<Vehicle> createState() => _VehicleState();
}

class _VehicleState extends State<Vehicle> {
  Map<String, bool> _selectedOptions = {};
  List<Map<String, dynamic>> vehicles = [];
  List<Map<String, dynamic>> filteredVehicles = [];
  TextEditingController _searchController = TextEditingController();
  Map<String, String> _driverCache = {}; // Cache for driver names

  @override
  void initState() {
    super.initState();
    _fetchDriverData(); // Fetch driver data when the widget is initialized
    fetchVehicles();
    _searchController.addListener(_onSearchChanged);
  }

  // Fetch the latest driver for each vehicle and cache it
  void _fetchDriverData() async {
    QuerySnapshot vehicleSnapshot =
        await FirebaseFirestore.instance.collection('vehicles').get();

    for (var vehicleDoc in vehicleSnapshot.docs) {
      String vehicleId = vehicleDoc.id;

      // Fetch latest driver from subcollection for each vehicle
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
        String assignedDriver = driverData['assigned_driver'] ?? 'N/A';

        // Cache the driver data
        setState(() {
          _driverCache[vehicleId] = assignedDriver;
        });
      } else {
        // If no driver is assigned, cache 'N/A'
        setState(() {
          _driverCache[vehicleId] = 'N/A';
        });
      }
    }
  }

  Future<void> fetchVehicles() async {
    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('vehicles').get();
    setState(() {
      vehicles = snapshot.docs.map((doc) {
        Map<String, dynamic> vehicleData = doc.data() as Map<String, dynamic>;
        vehicleData['id'] = doc.id; // Include document ID
        return vehicleData;
      }).toList();
      filteredVehicles = vehicles;

      // Initialize _selectedOptions for each vehicle if not already initialized
      for (var vehicle in vehicles) {
        String vehicleId = vehicle['id']; // Use document ID here
        if (!_selectedOptions.containsKey(vehicleId)) {
          _selectedOptions[vehicleId] = false;
        }
      }
    });
  }

  void _onSearchChanged() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      filteredVehicles = vehicles.where((vehicle) {
        String vehicleId = vehicle['id'];
        String assignedDriver =
            _driverCache[vehicleId] ?? 'N/A'; // Get the driver name from cache

        return vehicleId
                .toLowerCase()
                .contains(query) || // Search by Vehicle ID
            assignedDriver
                .toLowerCase()
                .contains(query) || // Search by assigned driver
            vehicle['brand'].toString().toLowerCase().contains(query) ||
            vehicle['color'].toString().toLowerCase().contains(query) ||
            vehicle['fuel_type'].toString().toLowerCase().contains(query) ||
            vehicle['model'].toString().toLowerCase().contains(query) ||
            vehicle['vehicle_type'].toString().toLowerCase().contains(query) ||
            vehicle['weight_limit'].toString().toLowerCase().contains(query) ||
            vehicle['license_plate_number']
                .toString()
                .toLowerCase()
                .contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Sidebar(),
      body: Builder(
        builder: (context) => Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 20, left: 40, right: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 5),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.menu, color: Colors.green, size: 25),
                          onPressed: () {
                            Scaffold.of(context)
                                .openDrawer(); // Opens the drawer
                          },
                        ),
                        Text(
                          'Vehicles',
                          style: GoogleFonts.poppins(
                            textStyle: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 20),
                          ),
                        ),
                      ],
                    ),
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
                            decoration: InputDecoration(
                              hintText:
                                  'Search by vehicle ID, assigned_driver, brand, color, fuel_type, model, vehicle_type, weight_limit, and license_plate_number',
                              border: InputBorder.none,
                              prefixIcon: Icon(Icons.search),
                            ),
                          ),
                        ),
                        SizedBox(width: 20),
                        ElevatedButton(
                          onPressed: () {
                            _showAddVehicleDialog(
                                context); // Call add vehicle function
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF4CAF4F),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30)),
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            textStyle: TextStyle(fontSize: 16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(width: 8),
                              Text(
                                'Add Vehicle',
                                style: GoogleFonts.roboto(
                                    textStyle: TextStyle(
                                        fontWeight: FontWeight.w300,
                                        color: Colors.white)),
                              ),
                              Icon(
                                Icons.add,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 20),
                        ElevatedButton(
                          onPressed: () {
                            _assignDriverToVehicles();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF0062FF),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30)),
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            textStyle: TextStyle(fontSize: 16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(width: 8),
                              Text(
                                'Assign Driver',
                                style: GoogleFonts.roboto(
                                    textStyle: TextStyle(
                                        fontWeight: FontWeight.w300,
                                        color: Colors.white)),
                              ),
                              Icon(
                                Icons.add,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Container(
                      height: MediaQuery.of(context).size.height * .825,
                      decoration: BoxDecoration(border: Border.all()),
                      child: Column(
                        children: [
                          Container(
                            child: Row(
                              children: [
                                Container(
                                    height: 20,
                                    width: 20,
                                    decoration: BoxDecoration(
                                        border: Border(bottom: BorderSide()))),
                                title('Vehicle ID', 1),
                                title('Brand', 2),
                                title('Vehicle Type', 1),
                                title('Model', 1),
                                title('Plate Number', 1),
                                title('Assigned Driver', 2),
                                title('Weight Limit', 1),
                                title('Details', 1),
                              ],
                            ),
                          ),
                          Expanded(
                            child: ListView(
                              children: filteredVehicles.map((vehicle) {
                                return _buildCustomCheckboxTile(
                                  vehicle,
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )),
      ),
    );
  }

  Widget title(String text, int fl) {
    return Expanded(
      flex: fl,
      child: Container(
        height: 20,
        decoration: BoxDecoration(border: Border(bottom: BorderSide())),
        child: Center(
          child: Text(
            text,
            style: GoogleFonts.roboto(
                textStyle: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  // Build the custom checkbox tile
  Widget _buildCustomCheckboxTile(Map<String, dynamic> vehicle) {
    String vehicleId = vehicle['id'] ?? 'N/A';
    String assignedDriver = _driverCache[vehicleId] ?? 'N/A';

    return CheckboxListTile(
      value: _selectedOptions[vehicleId],
      activeColor: Colors.green,
      onChanged: (bool? value) {
        setState(() {
          _selectedOptions[vehicleId] = value ?? false;
        });
      },
      title: Row(
        children: [
          Expanded(
              flex: 2,
              child: Text(vehicleId,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
          Expanded(
              flex: 1,
              child: Text(
                vehicle['brand'] ?? 'N/A',
                style: TextStyle(fontSize: 16),
              )),
          Expanded(
              flex: 1,
              child: Text(
                vehicle['vehicle_type'] ?? 'N/A',
                style: TextStyle(fontSize: 16),
              )),
          Expanded(
              flex: 1,
              child: Text(vehicle['model'] ?? 'N/A',
                  style: TextStyle(fontSize: 16))),
          Expanded(
              flex: 1,
              child: Text(vehicle['license_plate_number'] ?? 'N/A',
                  style: TextStyle(fontSize: 16))),
          Expanded(
              flex: 2,
              child: Text(assignedDriver, style: TextStyle(fontSize: 16))),
          Expanded(
              flex: 1,
              child: Text(vehicle['weight_limit'].toString() ?? 'N/A',
                  style: TextStyle(fontSize: 16))),
          Expanded(
            flex: 1,
            child: IconButton(
              icon: Icon(Icons.info_outline),
              onPressed: () {
                // Navigate to '/vehicleinformation' with the vehicle data
                Navigator.pushNamed(
                  context,
                  '/vehicleinformation',
                  arguments: vehicle,
                );
              },
            ),
          ),
        ],
      ),
      controlAffinity: ListTileControlAffinity.leading,
      dense: true,
      selectedTileColor: Colors.grey[200],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchDrivers() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('employees')
        .where('position', isEqualTo: 'Driver')
        .get();

    return snapshot.docs.map((doc) {
      Map<String, dynamic> driverData = doc.data() as Map<String, dynamic>;
      driverData['id'] = doc.id; // Include document ID
      driverData['name'] =
          driverData['name'] ?? 'N/A'; // Ensure driver's name is included
      return driverData;
    }).toList();
  }

  void _assignDriverToVehicles() async {
    List<String> selectedVehicleIds = [];

    // Collect all selected vehicles
    for (var entry in _selectedOptions.entries) {
      if (entry.value == true) {
        selectedVehicleIds.add(entry.key);
      }
    }

    if (selectedVehicleIds.isEmpty) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content:
                Text('Please select at least one vehicle to assign a driver.'),
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
      return;
    }

    // Show dialog to pick a driver and retrieve driver ID and name
    Map<String, String>? selectedDriver = await _showDriverSelectionDialog();

    // Check if selectedDriver is not null
    if (selectedDriver != null &&
        selectedDriver.containsKey('name') &&
        selectedDriver.containsKey('id')) {
      // Assign the driver to each selected vehicle
      for (String vehicleId in selectedVehicleIds) {
        await FirebaseFirestore.instance
            .collection('vehicles')
            .doc(vehicleId)
            .collection('drivers')
            .add({
          'assigned_driver': selectedDriver['name'], // Store driver name
          'driverid': selectedDriver['id'], // Store driver ID
          'time': FieldValue.serverTimestamp(),
        });

        // Safely update _driverCache in setState
        setState(() {
          _driverCache[vehicleId] =
              selectedDriver['name'] ?? 'Unknown'; // Ensure 'name' is not null
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Driver assigned to all selected vehicles successfully!')),
      );
    } else {
      // Handle case where driver selection fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Driver selection failed! Please try again.')),
      );
    }
  }

  Future<Map<String, String>?> _showDriverSelectionDialog() async {
    List<Map<String, dynamic>> drivers = [];

    // Fetch drivers from the 'employees' collection where the position is 'Driver'
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('employees')
        .where('position', isEqualTo: 'Driver')
        .get();

    drivers = snapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
        .toList();

    return await showDialog<Map<String, String>>(
      context: context,
      builder: (BuildContext dialogContext) {
        String? selectedDriverId;
        String? selectedDriverName;

        return StatefulBuilder(
          builder: (BuildContext context, setState) {
            return AlertDialog(
              title: Text('Select a Driver'),
              content: DropdownButtonFormField<String>(
                value: selectedDriverId,
                hint: Text('Select Driver'),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedDriverId = newValue;
                    selectedDriverName = drivers.firstWhere(
                        (driver) => driver['id'] == newValue)['name'];
                  });
                },
                items: drivers.map<DropdownMenuItem<String>>((driver) {
                  return DropdownMenuItem<String>(
                    value: driver['id'], // Use driver ID as the value
                    child: Text(driver['name']), // Display driver name
                  );
                }).toList(),
                decoration: InputDecoration(labelText: 'Driver'),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(); // Close dialog on cancel
                  },
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    if (selectedDriverId != null &&
                        selectedDriverName != null) {
                      // Close the dialog and return the selected driver's ID and name
                      Navigator.of(dialogContext).pop({
                        'id': selectedDriverId!,
                        'name': selectedDriverName!,
                      });
                    } else {
                      // Optional: Handle case when no driver is selected
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please select a driver.')),
                      );
                    }
                  },
                  child: Text('Assign'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddVehicleDialog(BuildContext context) async {
    final _formKey = GlobalKey<FormState>();

    // Controllers for text fields
    TextEditingController brandController = TextEditingController();
    TextEditingController colorController = TextEditingController();
    TextEditingController fuelTypeController = TextEditingController();
    TextEditingController licensePlateController = TextEditingController();
    TextEditingController modelController = TextEditingController();
    TextEditingController vehicleTypeController = TextEditingController();
    TextEditingController weightLimitController = TextEditingController();

    // Optional fields
    TextEditingController lastServiceDateController = TextEditingController();
    TextEditingController nextScheduledMaintenanceController =
        TextEditingController();
    TextEditingController purchaseDateController = TextEditingController();
    TextEditingController registrationExpireDateController =
        TextEditingController();
    TextEditingController registrationNumberController =
        TextEditingController();
    TextEditingController yearOfManufactureController = TextEditingController();

    // Fetch drivers list for dropdown
    List<Map<String, dynamic>> drivers = await _fetchDrivers();
    String? selectedDriverId; // Store the selected driver's ID

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Vehicle'),
          content: Form(
            key: _formKey,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.55,
              width: MediaQuery.of(context).size.width * 0.4,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    buildTextFormField('Brand', brandController, true),
                    buildTextFormField('Color', colorController, true),
                    buildTextFormField('Fuel Type', fuelTypeController, true),
                    buildTextFormField(
                        'License Plate Number', licensePlateController, true),
                    buildTextFormField('Model', modelController, true),
                    buildTextFormField(
                        'Vehicle Type', vehicleTypeController, true),
                    buildTextFormField(
                        'Weight Limit', weightLimitController, true,
                        isNumeric: true),

                    // Dropdown for assigned driver (optional)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: DropdownButtonFormField<String>(
                        value: selectedDriverId,
                        hint: Text('Select Assigned Driver (optional)'),
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedDriverId = newValue;
                          });
                        },
                        items: drivers.map<DropdownMenuItem<String>>((driver) {
                          return DropdownMenuItem<String>(
                            value: driver['id'], // Use driver ID as value
                            child: Text(driver['name'] ??
                                'N/A'), // Display driver's name
                          );
                        }).toList(),
                        decoration: InputDecoration(
                          labelText: 'Assigned Driver (optional)',
                        ),
                        isExpanded: true,
                        validator: (value) {
                          // No validation since it's optional
                          return null;
                        },
                      ),
                    ),

                    // Optional fields
                    buildTextFormField('Last Service Date (optional)',
                        lastServiceDateController, false),
                    buildTextFormField('Next Scheduled Maintenance (optional)',
                        nextScheduledMaintenanceController, false),
                    buildTextFormField('Purchase Date (optional)',
                        purchaseDateController, false),
                    buildTextFormField('Registration Expire Date (optional)',
                        registrationExpireDateController, false),
                    buildTextFormField('Registration Number (optional)',
                        registrationNumberController, false),
                    buildTextFormField('Year of Manufacture (optional)',
                        yearOfManufactureController, false),
                  ],
                ),
              ),
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  Map<String, dynamic> vehicleData = {
                    'assigned_driver': selectedDriverId != null
                        ? drivers.firstWhere((driver) =>
                            driver['id'] == selectedDriverId)['name']
                        : '',
                    'brand': brandController.text,
                    'color': colorController.text,
                    'fuel_type': fuelTypeController.text,
                    'license_plate_number': licensePlateController.text,
                    'model': modelController.text,
                    'vehicle_type': vehicleTypeController.text,
                    'weight_limit': double.parse(weightLimitController.text),

                    // Optional fields
                    'last_service_date':
                        lastServiceDateController.text.isNotEmpty
                            ? lastServiceDateController.text
                            : "",
                    'next_scheduled_maintenance':
                        nextScheduledMaintenanceController.text.isNotEmpty
                            ? nextScheduledMaintenanceController.text
                            : "",
                    'purchase_date': purchaseDateController.text.isNotEmpty
                        ? purchaseDateController.text
                        : "",
                    'registration_expire_date':
                        registrationExpireDateController.text.isNotEmpty
                            ? registrationExpireDateController.text
                            : "",
                    'registration_number':
                        registrationNumberController.text.isNotEmpty
                            ? registrationNumberController.text
                            : "",
                    'year_of_manufacture':
                        yearOfManufactureController.text.isNotEmpty
                            ? yearOfManufactureController.text
                            : "",
                  };

                  // Add to Firestore
                  await FirebaseFirestore.instance
                      .collection('vehicles')
                      .add(vehicleData);

                  // Refresh the list of vehicles
                  fetchVehicles();

                  // Close the dialog
                  Navigator.of(context).pop();
                }
              },
              child: Text('Add Vehicle'),
            ),
          ],
        );
      },
    );
  }

  Widget buildTextFormField(
      String labelText, TextEditingController controller, bool isRequired,
      {bool isNumeric = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
        validator: (value) {
          if (isRequired && (value == null || value.isEmpty)) {
            return 'Please enter $labelText';
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: labelText,
        ),
      ),
    );
  }
}
