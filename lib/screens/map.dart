import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

class Maps extends StatefulWidget {
  final String bookingId; // Accept bookingId as a parameter

  const Maps({super.key, required this.bookingId});

  @override
  State<Maps> createState() => _MapsState();
}

class _MapsState extends State<Maps> {
  List<Marker> _markers = <Marker>[];

  @override
  void initState() {
    super.initState();
    _fetchUserLocations(); // Fetch user locations when the map is loaded
  }

  // Function to fetch user locations from Firestore
  Future<void> _fetchUserLocations() async {
    // Reference the subcollection 'users' of the specific booking
    var usersSnapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .doc(widget.bookingId)
        .collection('users')
        .get();

    // Iterate through the users and add their locations as markers
    List<Marker> markers = usersSnapshot.docs.map((userDoc) {
      var userData = userDoc.data() as Map<String, dynamic>;
      GeoPoint? location = userData['location']; // Fetch the GeoPoint
      if (location != null) {
        return Marker(
          point: LatLng(location.latitude, location.longitude),
          builder: (ctx) =>
              const Icon(Icons.location_on, color: Colors.red, size: 40),
        );
      }
      return Marker(
        point: LatLng(0, 0), // Default point in case location is null
        builder: (ctx) =>
            const Icon(Icons.location_on, color: Colors.grey, size: 40),
      );
    }).toList();

    setState(() {
      _markers = markers; // Update the markers on the map
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Locations Map'),
        backgroundColor: Colors.green[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(
              border: Border.all(color: Colors.green, width: 4),
              borderRadius: BorderRadius.circular(25)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25), // Apply radius here
            child: FlutterMap(
              options: MapOptions(
                center: _markers.isNotEmpty
                    ? _markers.first.point
                    : LatLng(7.0800, 125.6200), // Center on the first marker
                zoom: 15.0, // Set appropriate zoom level
                maxZoom: 18.0, // Optional max zoom
                minZoom: 5.0, // Optional min zoom
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: ['a', 'b', 'c'],
                ),
                MarkerLayer(markers: _markers), // Display the markers
              ],
            ),
          ),
        ),
      ),
    );
  }
}
