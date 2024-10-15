import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

class Maps extends StatefulWidget {
  final String bookingId;

  const Maps({super.key, required this.bookingId});

  @override
  State<Maps> createState() => _MapsState();
}

class _MapsState extends State<Maps> {
  List<Marker> _markers = <Marker>[];
  String? hoveredUserId;

  @override
  void initState() {
    super.initState();
    _fetchUserLocations();
  }

  // Function to fetch user locations from Firestore
  Future<void> _fetchUserLocations() async {
    var usersSnapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .doc(widget.bookingId)
        .collection('users')
        .get();

    List<Marker> markers = usersSnapshot.docs.map((userDoc) {
      var userData = userDoc.data() as Map<String, dynamic>;
      GeoPoint? location = userData['location'];
      String firstName = userData['firstName'] ?? 'Unknown';
      String lastName = userData['lastName'] ?? 'Unknown';
      String userId = userDoc.id;

      if (location != null) {
        return Marker(
          point: LatLng(location.latitude, location.longitude),
          builder: (ctx) {
            return GestureDetector(
              onTap: () {
                setState(() {
                  hoveredUserId = userId;
                });
              },
              child: const Icon(Icons.location_on, color: Colors.red, size: 40),
            );
          },
          anchorPos: AnchorPos.align(AnchorAlign.top),
          key: Key(userId),
        );
      }
      return Marker(
        point: LatLng(0, 0),
        builder: (ctx) =>
            const Icon(Icons.location_on, color: Colors.grey, size: 40),
        anchorPos: AnchorPos.align(AnchorAlign.top),
        key: Key(userId),
      );
    }).toList();

    setState(() {
      _markers = markers;
    });
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
          top: 30, // Distance from the top of the screen
          left: 30, // Distance from the left of the screen
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
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
                borderRadius: BorderRadius.circular(25),
                child: FlutterMap(
                  options: MapOptions(
                    center: _markers.isNotEmpty
                        ? _markers.first.point
                        : LatLng(7.0800, 125.6200),
                    zoom: 15.0,
                    maxZoom: 18.0,
                    minZoom: 5.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: ['a', 'b', 'c'],
                    ),
                    MarkerLayer(markers: _markers),
                  ],
                ),
              ),
            ),
          ),
          if (hoveredUserId != null)
            _getPopupForMarker(), // Display popup in top-left corner
        ],
      ),
    );
  }
}
