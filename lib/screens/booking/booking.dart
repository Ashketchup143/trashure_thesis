import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trashure_thesis/screens/booking/bookingdetails.dart';
import 'package:trashure_thesis/screens/map.dart';
import 'package:intl/intl.dart';
import 'package:trashure_thesis/sidebar.dart';

class Booking extends StatefulWidget {
  const Booking({super.key});

  @override
  State<Booking> createState() => _BookingState();
}

class _BookingState extends State<Booking> {
  final _formKey = GlobalKey<FormState>();
  DateTime selectedDate = DateTime.now();
  TextEditingController dateController = TextEditingController();
  TextEditingController searchController = TextEditingController();
  String searchQuery = "";
  TextEditingController startTimeController = TextEditingController();
  TextEditingController endTimeController = TextEditingController();
  TimeOfDay? selectedStartTime;
  TimeOfDay? selectedEndTime;
  List<Map<String, dynamic>> locations = [];

  String? selectedDriver;
  String? selectedVehicle;
  Map<String, bool> _selectedOptions = {};

  List<DocumentSnapshot> filteredBookings = [];

  @override
  void initState() {
    super.initState();
    dateController.text =
        "${selectedDate.year}-${selectedDate.month}-${selectedDate.day}";
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMMM d, yyyy (EEEE)').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const Sidebar(),
      body: Builder(
        builder: (context) => Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: Padding(
            padding: const EdgeInsets.only(top: 20, left: 40, right: 40),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.menu,
                            color: Colors.green, size: 30),
                        onPressed: () {
                          Scaffold.of(context).openDrawer();
                        },
                      ),
                      Text(
                        'Booking',
                        textAlign: TextAlign.left,
                        style: GoogleFonts.poppins(
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
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
                          controller: searchController,
                          decoration: const InputDecoration(
                            hintText:
                                'Search by ID, Date, Location, Driver, Vehicle, Status',
                            border: InputBorder.none,
                            prefixIcon: Icon(Icons.search),
                          ),
                          onChanged: (value) {
                            setState(() {
                              searchQuery = value.toLowerCase();
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 20),
                      _buildButton('Add Schedule', const Color(0xFF4CAF4F),
                          _showAddScheduleModal),
                      const SizedBox(width: 20),
                      _buildButton('Assign Driver/Vehicle',
                          const Color(0xFF0062FF), _showAssignDriverModal),
                      const SizedBox(width: 20),
                      _buildButton(
                          'Locations',
                          const Color.fromARGB(255, 191, 27, 233),
                          () => _showLocationsModal(context)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    height: MediaQuery.of(context).size.height * .8,
                    width: MediaQuery.of(context).size.width,
                    decoration: BoxDecoration(border: Border.all()),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            title('Schedule ID', 2),
                            title('Date', 4),
                            title('Location', 2),
                            title('Driver', 2),
                            title('Vehicle', 2),
                            title('OA. Price', 1),
                            title('OA. Weight', 1),
                            title('Status', 1),
                            title('Details', 1),
                          ],
                        ),
                        Expanded(
                          child: StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('bookings')
                                .orderBy('date', descending: false)
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }

                              var bookings = snapshot.data!.docs;

                              var filteredBookings = bookings.where((doc) {
                                var data = doc.data() as Map<String, dynamic>;
                                if (data['status'] == 'collected' ||
                                    data['status'] == 'completed') {
                                  return false;
                                }
                                return _matchesSearchQuery(data, doc.id);
                              }).toList();

                              return ListView(
                                children: filteredBookings.map((doc) {
                                  var bookingData =
                                      doc.data() as Map<String, dynamic>;
                                  var scheduleId = doc.id;
                                  return _buildCustomCheckboxTile(
                                      scheduleId, bookingData);
                                }).toList(),
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
          ),
        ),
      ),
    );
  }

  ElevatedButton _buildButton(
      String label, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        textStyle: const TextStyle(fontSize: 16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.roboto(
              textStyle: const TextStyle(
                fontWeight: FontWeight.w300,
                color: Colors.white,
              ),
            ),
          ),
          const Icon(Icons.add, color: Colors.white),
        ],
      ),
    );
  }

  void _showLocationsModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Locations'),
              ElevatedButton(
                onPressed: () => _showAddDistrictModal(context),
                child: const Text('Add Location'),
              ),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('locations')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var locations = snapshot.data!.docs;

                if (locations.isEmpty) {
                  return const Center(child: Text('No locations available.'));
                }

                return Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Location',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Suggested Days',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Actions',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                    Expanded(
                      child: ListView.builder(
                        itemCount: locations.length,
                        itemBuilder: (context, index) {
                          var location = locations[index];
                          var locationData =
                              location.data() as Map<String, dynamic>;
                          var district =
                              locationData['district'] ?? 'Unknown District';
                          var locationName =
                              locationData['location'] ?? 'Unknown Location';
                          var suggestedDays = List<String>.from(
                              locationData['suggested_days'] ?? []);

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4.0),
                            child: ListTile(
                              title: Text(
                                locationName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('District: $district'),
                                  Wrap(
                                    spacing: 8.0,
                                    children: suggestedDays
                                        .map((day) => Chip(label: Text(day)))
                                        .toList(),
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _confirmDeleteLocation(
                                    context, location.id, district),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _confirmDeleteLocation(
      BuildContext context, String locationId, String district) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content:
              Text('Are you sure you want to delete the location "$district"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _deleteLocation(locationId);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                          Text('Location "$district" deleted successfully.')),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteLocation(String locationId) async {
    await FirebaseFirestore.instance
        .collection('locations')
        .doc(locationId)
        .delete();
  }

  void _showAddDistrictModal(BuildContext context) {
    final TextEditingController _locationController = TextEditingController();
    List<String> _selectedDays = [];
    final List<String> _daysOfWeek = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday'
    ];
    String? selectedDistrict;
    final List<String> districts = ['1', '2', '3'];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Location (District)'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedDistrict,
                    decoration: const InputDecoration(
                      labelText: 'Select District',
                      border: OutlineInputBorder(),
                    ),
                    items: districts.map((district) {
                      return DropdownMenuItem<String>(
                        value: district,
                        child: Text(district),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedDistrict = newValue;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      labelText: 'Location Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Suggested Days',
                      border: OutlineInputBorder(),
                    ),
                    items: _daysOfWeek
                        .map((day) =>
                            DropdownMenuItem(value: day, child: Text(day)))
                        .toList(),
                    onChanged: (String? selectedDay) {
                      if (selectedDay != null &&
                          !_selectedDays.contains(selectedDay)) {
                        setState(() {
                          _selectedDays.add(selectedDay);
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8.0,
                    children: _selectedDays
                        .map((day) => Chip(
                              label: Text(day),
                              onDeleted: () {
                                setState(() {
                                  _selectedDays.remove(day);
                                });
                              },
                            ))
                        .toList(),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedDistrict != null &&
                    _locationController.text.trim().isNotEmpty) {
                  await FirebaseFirestore.instance.collection('locations').add({
                    'district': selectedDistrict,
                    'location': _locationController.text.trim().toUpperCase(),
                    'suggested_days': _selectedDays,
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Location added successfully!')),
                  );
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please complete all fields.')),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showAddScheduleModal() {
    final TextEditingController _locationController = TextEditingController();
    final List<String> districts = [
      'All',
      '1',
      '2',
      '3'
    ]; // Including "All" option
    String? selectedDistrict = 'All';
    List<String> selectedLocations = [];
    String? errorMessage;

    // Fetch locations from Firestore
    FirebaseFirestore.instance.collection('locations').get().then((snapshot) {
      locations = snapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    });

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Filter locations based on selected district
            List<Map<String, dynamic>> filteredLocations =
                selectedDistrict == 'All'
                    ? locations
                    : locations
                        .where((loc) => loc['district'] == selectedDistrict)
                        .toList();

            return AlertDialog(
              title: const Text('Add Schedule'),
              content: SizedBox(
                width: 400, // Set your desired width
                height: 500, // Set your desired height
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: dateController,
                      decoration: const InputDecoration(
                        labelText: "Select Date",
                        border: OutlineInputBorder(),
                      ),
                      readOnly: true,
                      onTap: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (pickedDate != null) {
                          setState(() {
                            selectedDate = pickedDate;
                            dateController.text = _formatDate(pickedDate);
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    // District Dropdown
                    DropdownButtonFormField<String>(
                      value: selectedDistrict,
                      decoration: const InputDecoration(
                        labelText: 'Select District',
                        border: OutlineInputBorder(),
                      ),
                      items: districts.map((district) {
                        return DropdownMenuItem<String>(
                          value: district,
                          child: Text(district == 'All'
                              ? 'All Districts'
                              : 'District $district'),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedDistrict = newValue;
                          selectedLocations
                              .clear(); // Clear selected locations on district change
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    // Button to add all locations
                    const SizedBox(height: 10),
                    // Location Dropdown (allows multiple selections)
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Select Location',
                        border: OutlineInputBorder(),
                      ),
                      items: filteredLocations.map((location) {
                        return DropdownMenuItem<String>(
                          value: location['id'],
                          child: Text(location['location']),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null &&
                            !selectedLocations.contains(newValue)) {
                          setState(() {
                            selectedLocations.add(newValue);
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          selectedLocations = filteredLocations
                              .map<String>(
                                  (location) => location['id'] as String)
                              .toList();
                        });
                      },
                      child: const Text("Add All Locations"),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8.0,
                      children: selectedLocations.map((locationId) {
                        String locationName = filteredLocations.firstWhere(
                            (loc) => loc['id'] == locationId)['location'];
                        return Chip(
                          label: Text(locationName),
                          onDeleted: () {
                            setState(() {
                              selectedLocations.remove(locationId);
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: startTimeController,
                      decoration: const InputDecoration(
                        labelText: "Start Time",
                        border: OutlineInputBorder(),
                      ),
                      readOnly: true,
                      onTap: () async {
                        TimeOfDay? pickedTime = await showTimePicker(
                          context: context,
                          initialTime: const TimeOfDay(hour: 5, minute: 0),
                        );
                        if (pickedTime != null) {
                          setState(() {
                            selectedStartTime = pickedTime;
                            startTimeController.text =
                                pickedTime.format(context);
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: endTimeController,
                      decoration: const InputDecoration(
                        labelText: "End Time",
                        border: OutlineInputBorder(),
                      ),
                      readOnly: true,
                      onTap: () async {
                        TimeOfDay? pickedTime = await showTimePicker(
                          context: context,
                          initialTime: const TimeOfDay(hour: 17, minute: 0),
                        );
                        if (pickedTime != null) {
                          setState(() {
                            selectedEndTime = pickedTime;
                            endTimeController.text = pickedTime.format(context);
                          });
                        }
                      },
                    ),
                    if (errorMessage != null)
                      Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _addSchedules(selectedLocations);
                  },
                  child: const Text('Add'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  List<DropdownMenuItem<String>> _getLocationDropdownItems() {
    List<DropdownMenuItem<String>> items = [];
    String dayOfWeek = DateFormat('EEEE').format(selectedDate);

    List<Map<String, dynamic>> suggestedLocations = locations.where((location) {
      List<String> suggestedDays =
          List<String>.from(location['suggested_days'] ?? []);
      return suggestedDays.contains(dayOfWeek);
    }).toList();

    items.addAll(suggestedLocations.map((location) {
      return DropdownMenuItem<String>(
        value: location['id'],
        child: Text('${location['district']} (Suggested)'),
      );
    }));

    items.addAll(locations
        .where((location) => !suggestedLocations.contains(location))
        .map((location) {
      return DropdownMenuItem<String>(
        value: location['id'],
        child: Text(location['district']),
      );
    }));

    return items;
  }

  Future<void> _addSchedules(List<String> locationIds) async {
    try {
      bool conflictDetected = false;
      String conflictMessage = "";

      // Define date and time format
      final timeFormat = DateFormat('hh:mm a');

      for (var locationId in locationIds) {
        var locationData =
            locations.firstWhere((loc) => loc['id'] == locationId);

        // Fetch schedules for the same location and date
        QuerySnapshot existingSchedules = await FirebaseFirestore.instance
            .collection('bookings')
            .where('locationId', isEqualTo: locationId)
            .where('date', isEqualTo: Timestamp.fromDate(selectedDate))
            .get();

        DateTime newStartTime = timeFormat.parse(startTimeController.text);
        DateTime newEndTime = timeFormat.parse(endTimeController.text);

        // Check for overlapping times
        for (var doc in existingSchedules.docs) {
          var scheduleData = doc.data() as Map<String, dynamic>;
          DateTime existingStartTime =
              timeFormat.parse(scheduleData['start_time']);
          DateTime existingEndTime = timeFormat.parse(scheduleData['end_time']);

          // If the times overlap, set conflictDetected to true and break
          if (!(newEndTime.isBefore(existingStartTime) ||
              newStartTime.isAfter(existingEndTime))) {
            conflictDetected = true;
            conflictMessage =
                "The location ${locationData['location']} has a conflicting schedule on ${_formatDate(selectedDate)} between ${startTimeController.text} and ${endTimeController.text}.";
            break;
          }
        }

        if (conflictDetected) break; // Exit if any conflict is found
      }

      if (conflictDetected) {
        // Show conflict dialog
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Conflict Detected'),
              content: Text(conflictMessage),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      } else {
        // No conflicts, proceed with adding schedules
        for (var locationId in locationIds) {
          var locationData =
              locations.firstWhere((loc) => loc['id'] == locationId);

          await FirebaseFirestore.instance.collection('bookings').add({
            'date': Timestamp.fromDate(selectedDate),
            'start_time': startTimeController.text,
            'end_time': endTimeController.text,
            'status': 'pending',
            'locationId': locationId,
            'location': locationData['location'],
            'district': locationData['district'],
            'driver': null,
            'vehicle': null,
          });
        }

        // Show success message only if schedules are added without conflicts
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Success'),
              content: const Text('Schedule(s) added successfully!'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      // Show an error dialog in case of exceptions
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to add schedule(s): $e'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  void _showAssignDriverModal() {
    double overallWeight = 0.0; // Initialize overallWeight

    // Get the selected booking's overall_weight
    if (_selectedOptions.isNotEmpty) {
      var selectedScheduleId = _selectedOptions.keys.firstWhere(
        (key) => _selectedOptions[key] == true,
        orElse: () => '',
      );

      if (selectedScheduleId.isNotEmpty) {
        FirebaseFirestore.instance
            .collection('bookings')
            .doc(selectedScheduleId)
            .get()
            .then((bookingDoc) {
          if (bookingDoc.exists) {
            var bookingData = bookingDoc.data() as Map<String, dynamic>;
            overallWeight = bookingData['overall_weight']?.toDouble() ?? 0.0;
          }
        });
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Assign Vehicle and Driver'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('vehicles')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const CircularProgressIndicator();
                      }

                      var vehicles = snapshot.data?.docs ?? [];
                      // Filter vehicles based on the weight limit
                      var filteredVehicles = vehicles.where((doc) {
                        var vehicleData = doc.data() as Map<String, dynamic>;
                        double weightLimit =
                            vehicleData['weight_limit']?.toDouble() ?? 0.0;
                        return overallWeight <= weightLimit;
                      }).toList();

                      return DropdownButtonFormField<String>(
                        value: selectedVehicle,
                        decoration: const InputDecoration(
                          labelText: 'Select Vehicle',
                          border: OutlineInputBorder(),
                        ),
                        items: filteredVehicles.map((doc) {
                          var vehicleData = doc.data() as Map<String, dynamic>;
                          String vehicleLabel =
                              "${vehicleData['brand']} ${vehicleData['model']} (${vehicleData['vehicle_type']}) - Limit: ${vehicleData['weight_limit']} kg";
                          return DropdownMenuItem<String>(
                            value: doc.id,
                            child: Text(vehicleLabel),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedVehicle = newValue!;
                            _fetchMostRecentDriverForVehicle(
                                newValue, setState);
                          });
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  if (selectedDriver != null)
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('employees')
                          .doc(selectedDriver)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const CircularProgressIndicator();
                        }
                        var driverData =
                            snapshot.data?.data() as Map<String, dynamic>;
                        return Text(
                          'Assigned Driver: ${driverData['name']}',
                          style: const TextStyle(fontSize: 16),
                        );
                      },
                    )
                  else
                    const Text(
                      'No driver assigned yet.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    if (_selectedOptions.containsValue(true)) {
                      Navigator.of(context).pop();
                      _updateDriverVehicle();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Please select at least one schedule to assign.')),
                      );
                    }
                  },
                  child: const Text('Assign'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _fetchMostRecentDriverForVehicle(
      String vehicleId, void Function(void Function()) setState) async {
    try {
      var driversSnapshot = await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(vehicleId)
          .collection('drivers')
          .orderBy('time', descending: true)
          .limit(1)
          .get();

      if (driversSnapshot.docs.isNotEmpty) {
        var recentDriverData = driversSnapshot.docs.first.data();
        setState(() {
          selectedDriver = recentDriverData['driverid'];
        });
      }
    } catch (e) {
      print('Error fetching most recent driver: $e');
    }
  }

  Future<void> _updateDriverVehicle() async {
    if (selectedVehicle == null) {
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: const Text('Please select a vehicle.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
      return;
    }

    if (selectedDriver == null) {
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: const Text(
                'The selected vehicle has no driver assigned. Please assign a driver first.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
      return;
    }

    bool conflictDetected = false;
    try {
      var selectedSchedules = _selectedOptions.keys
          .where((key) => _selectedOptions[key] == true)
          .toList();

      final timeFormat = DateFormat('hh:mm a');

      for (var scheduleId in selectedSchedules) {
        DocumentSnapshot bookingDoc = await FirebaseFirestore.instance
            .collection('bookings')
            .doc(scheduleId)
            .get();
        var bookingData = bookingDoc.data() as Map<String, dynamic>;

        DateTime bookingDate = bookingData['date'].toDate();
        DateTime bookingStartTime = timeFormat.parse(bookingData['start_time']);
        DateTime bookingEndTime = timeFormat.parse(bookingData['end_time']);

        QuerySnapshot conflictingBookings = await FirebaseFirestore.instance
            .collection('bookings')
            .where('driverId', isEqualTo: selectedDriver)
            .where('date', isEqualTo: Timestamp.fromDate(bookingDate))
            .get();

        for (var conflictDoc in conflictingBookings.docs) {
          var conflictData = conflictDoc.data() as Map<String, dynamic>;
          DateTime conflictStartTime =
              timeFormat.parse(conflictData['start_time']);
          DateTime conflictEndTime = timeFormat.parse(conflictData['end_time']);

          bool timesOverlap = bookingStartTime.isBefore(conflictEndTime) &&
              bookingEndTime.isAfter(conflictStartTime);

          if (timesOverlap) {
            conflictDetected = true;
            break;
          }
        }

        if (conflictDetected) break;
      }

      if (conflictDetected) {
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Conflict Detected'),
              content: const Text(
                  'The selected driver is already assigned to another booking on the same date and overlapping time. Please choose a different driver or time.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      } else {
        for (var scheduleId in selectedSchedules) {
          var vehicleDoc = await FirebaseFirestore.instance
              .collection('vehicles')
              .doc(selectedVehicle)
              .get();
          var vehicleData = vehicleDoc.data() as Map<String, dynamic>;

          var driverDoc = await FirebaseFirestore.instance
              .collection('employees')
              .doc(selectedDriver)
              .get();
          var driverData = driverDoc.data() as Map<String, dynamic>;

          var vehicleName =
              "${vehicleData['brand']} ${vehicleData['model']} ${vehicleData['vehicle_type']}";
          var driverName = driverData['name'];

          await FirebaseFirestore.instance
              .collection('bookings')
              .doc(scheduleId)
              .update({
            'vehicle': vehicleName,
            'vehicleId': selectedVehicle,
            'driver': driverName,
            'driverId': selectedDriver,
          });
        }

        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Success'),
              content: const Text('Driver and vehicle assigned successfully!'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to assign driver and vehicle: $e'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  Expanded title(String title, int flex) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: const BoxDecoration(
          border: Border(
            right: BorderSide(color: Colors.black),
            bottom: BorderSide(color: Colors.black),
          ),
        ),
        child: Center(
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  bool _matchesSearchQuery(Map<String, dynamic> data, String scheduleId) {
    String id = scheduleId.toLowerCase();
    String driver =
        (data['driver']?.toString() ?? 'no driver assigned').toLowerCase();
    String vehicle =
        (data['vehicle']?.toString() ?? 'no vehicle assigned').toLowerCase();
    String status = (data['status']?.toString() ?? '').toLowerCase();
    String date =
        _formatDate(data['date']?.toDate() ?? DateTime(1970)).toLowerCase();
    String location =
        (data['location']?.toString() ?? 'no location assigned').toLowerCase();
    String startTime =
        (data['start_time']?.toString() ?? 'no start time').toLowerCase();
    String endTime =
        (data['end_time']?.toString() ?? 'no end time').toLowerCase();
    String normalizedQuery = searchQuery.toLowerCase();

    return id.contains(normalizedQuery) ||
        driver.contains(normalizedQuery) ||
        vehicle.contains(normalizedQuery) ||
        status.contains(normalizedQuery) ||
        date.contains(normalizedQuery) ||
        startTime.contains(normalizedQuery) ||
        endTime.contains(normalizedQuery) ||
        location.contains(normalizedQuery);
  }

  Widget _buildCustomCheckboxTile(
      String scheduleId, Map<String, dynamic> bookingData) {
    return ListTile(
      leading: Checkbox(
        value: _selectedOptions[scheduleId] ?? false,
        onChanged: (bool? value) {
          // Update only the specific checkbox state
          setState(() {
            _selectedOptions[scheduleId] = value ?? false;
          });
        },
        activeColor: Colors.green,
      ),
      title: Row(
        children: [
          Expanded(
              flex: 2,
              child: Text(scheduleId, style: const TextStyle(fontSize: 14))),
          Expanded(
            flex: 3,
            child: Text(
              bookingData['date'] != null
                  ? "${_formatDate(bookingData['date'].toDate())}, "
                      "${bookingData['start_time'] ?? 'N/A'} - ${bookingData['end_time'] ?? 'N/A'}"
                  : 'No Date',
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Expanded(
              flex: 2,
              child: Center(
                  child: Text(
                      bookingData['location']?.toString() ?? 'No Location',
                      style: const TextStyle(fontSize: 14)))),
          Expanded(
              flex: 2,
              child: Center(
                  child: Text(
                      bookingData['driver']?.toString() ?? 'No Driver Assigned',
                      style: const TextStyle(fontSize: 14)))),
          Expanded(
              flex: 2,
              child: Center(
                  child: Text(
                      bookingData['vehicle']?.toString() ??
                          'No Vehicle Assigned',
                      style: const TextStyle(fontSize: 14)))),
          Expanded(
              flex: 1,
              child: Center(
                  child: Text(
                      bookingData['overall_price'] != null
                          ? '₱${bookingData['overall_price'].toStringAsFixed(2)}'
                          : '₱0',
                      style: GoogleFonts.poppins(fontSize: 14)))),
          Expanded(
              flex: 1,
              child: Center(
                  child: Text(
                      bookingData['overall_weight'] != null
                          ? '${bookingData['overall_weight'].toStringAsFixed(2)} kg'
                          : 'N/A',
                      style: GoogleFonts.poppins(fontSize: 14)))),
          Expanded(
              flex: 1,
              child: Center(
                  child: Text(bookingData['status']?.toString() ?? 'No Status',
                      style: const TextStyle(fontSize: 14)))),
          Expanded(
            flex: 1,
            child: Center(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.map, size: 18),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => Maps(bookingId: scheduleId)),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.info_outline, size: 18),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BookingDetails(
                            bookingId: scheduleId,
                            bookingData: bookingData,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
