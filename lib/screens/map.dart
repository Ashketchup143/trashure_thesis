import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:trashure_thesis/user_model.dart';
import 'package:geolocator/geolocator.dart';

class Maps extends StatefulWidget {
  final String bookingId;

  const Maps({super.key, required this.bookingId});

  @override
  State<Maps> createState() => _MapsState();
}

class _MapsState extends State<Maps> {
  List<Marker> _markers = <Marker>[];
  String? hoveredUserId;
  Marker? _driverMarker;
  LatLng initialCenter = const LatLng(7.0800, 125.6200); // Default fallback
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
    _checkLocationService();
    _fetchUserLocations();
    _listenToDriverLocation();
    _updateDriverLocation();
  }

  // Function to fetch user locations from Firestore
  Future<void> _fetchUserLocations() async {
    var usersSnapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .doc(widget.bookingId)
        .collection('users')
        .get();

    List<Marker> markers = [];

    for (var userDoc in usersSnapshot.docs) {
      var userData = userDoc.data() as Map<String, dynamic>;
      GeoPoint? location = userData['location'];
      String firstName = userData['firstName'] ?? 'Unknown';
      String lastName = userData['lastName'] ?? 'Unknown';
      String userId = userDoc.id;

      // Only add markers for users who have a valid location
      if (location != null) {
        markers.add(
          Marker(
            point: LatLng(location.latitude, location.longitude),
            builder: (ctx) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    hoveredUserId = userId;
                  });
                },
                child:
                    const Icon(Icons.location_on, color: Colors.red, size: 40),
              );
            },
            anchorPos: AnchorPos.align(AnchorAlign.top),
            key: Key(userId),
          ),
        );

        print(
            'Driver location: Latitude: ${location.latitude}, Longitude: ${location.longitude}');
      }
    }

    // Update the markers and animate the map to the first marker's location
    if (markers.isNotEmpty) {
      setState(() {
        _markers = markers;
      });
      _mapController.move(
          markers.first.point, 15.0); // Move map to the first user's location
    }
  }

  // Function to listen to the driver's GPS location
  void _listenToDriverLocation() {
    final userRole = Provider.of<UserModel>(context, listen: false).userRole;
    final userId = Provider.of<UserModel>(context, listen: false).userId;

    // Only track the driver's location if the user role is 'driver'
    if (userRole == 'driver' || userRole == 'contractual driver') {
      FirebaseFirestore.instance
          .collection('employees')
          .doc(userId)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists) {
          var data = snapshot.data() as Map<String, dynamic>;
          GeoPoint? location = data['location'];

          if (location != null) {
            LatLng driverLatLng = LatLng(location.latitude, location.longitude);

            // Update the driver marker with a blue car icon
            setState(() {
              _driverMarker = Marker(
                point: driverLatLng,
                builder: (ctx) => const Icon(
                  Icons.directions_car,
                  color: Colors.blue, // Blue color for the driver marker
                  size: 40,
                ),
                anchorPos: AnchorPos.align(AnchorAlign.top),
              );

              // // Optionally, move the map to the driver's current location
              // _mapController.move(driverLatLng, 15.0);
            });
          }
        }
      });
    }
  }

  Future<void> _checkLocationService() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      print("Location services are disabled.");
      // Optionally, show a dialog to notify the user
      _showEnableLocationDialog();
    } else {
      print("Location services are enabled.");
    }
  }

  Future<void> _requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }
  }

  // Function to display the popup in the top left
  Widget _getPopupForMarker() {
    if (hoveredUserId == null) return const SizedBox();

    final userDoc = FirebaseFirestore.instance
        .collection('bookings')
        .doc(widget.bookingId)
        .collection('users')
        .doc(hoveredUserId!);

    return FutureBuilder<DocumentSnapshot>(
      future: userDoc.get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox();
        }

        var userData = snapshot.data?.data() as Map<String, dynamic>;
        String firstName = userData['firstName'] ?? 'Unknown';
        String lastName = userData['lastName'] ?? '';
        String userId = snapshot.data?.id ?? 'Unknown';
        String address = userData['address'] ?? 'Unknown Address';

        return Positioned(
          top: 30,
          left: 30,
          child: Container(
            padding: const EdgeInsets.all(8),
            width: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.green),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$firstName $lastName',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('ID: $userId'),
                const SizedBox(height: 4),
                Text('Address: $address'),
              ],
            ),
          ),
        );
      },
    );
  }

  void _updateDriverLocation() {
    final userRole = Provider.of<UserModel>(context, listen: false).userRole;
    final userId = Provider.of<UserModel>(context, listen: false).userId;

    if (userRole == 'driver' || userRole == 'contractual driver') {
      Geolocator.getPositionStream().listen((Position position) async {
        print(
            "GPS Position Stream: Latitude: ${position.latitude}, Longitude: ${position.longitude}");
        GeoPoint newLocation = GeoPoint(position.latitude, position.longitude);

        DocumentReference driverDoc =
            FirebaseFirestore.instance.collection('employees').doc(userId);

        var docSnapshot = await driverDoc.get();
        print("Driver document snapshot: ${docSnapshot.data()}");

        if (!docSnapshot.exists ||
            (docSnapshot.data() as Map<String, dynamic>?)?['location'] ==
                null) {
          print("Setting new driver location in Firestore.");
          await driverDoc
              .set({'location': newLocation}, SetOptions(merge: true));
        } else {
          print("Updating existing driver location in Firestore.");
          await driverDoc.update({'location': newLocation});
        }

        // Update the map marker without changing the map center
        print("Updating driver marker on the map.");
        setState(() {
          _driverMarker = Marker(
            point: LatLng(position.latitude, position.longitude),
            builder: (ctx) => const Icon(
              Icons.directions_car,
              color: Colors.blue,
              size: 40,
            ),
            anchorPos: AnchorPos.align(AnchorAlign.top),
          );
        });

        // _mapController.move(
        //     LatLng(position.latitude, position.longitude), 15.0);
      });
    }
  }

  void _showEnableLocationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Location Services Disabled"),
          content: Text("Please enable location services to continue."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine the initial center of the map based on the first user's location
    LatLng initialCenter = _markers.isNotEmpty
        ? _markers.first.point
        : const LatLng(7.0800, 125.6200); // Fallback if no markers are found

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'User Locations Map',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green[700],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green, width: 4),
                borderRadius: BorderRadius.circular(25),
              ),
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      center: initialCenter, // Use the updated initial center
                      zoom: 13.0,
                      maxZoom: 18.0,
                      minZoom: 5.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                        subdomains: ['a', 'b', 'c'],
                      ),
                      MarkerLayer(
                        markers: [
                          ..._markers,
                          if (_driverMarker != null)
                            _driverMarker!, // Include the driver marker
                        ],
                      ),
                    ],
                  )),
            ),
          ),
          if (hoveredUserId != null)
            _getPopupForMarker(), // Display popup in top-left corner
        ],
      ),
    );
  }
}
