import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trashure_thesis/sidebar.dart';

class Users extends StatefulWidget {
  const Users({super.key});

  @override
  State<Users> createState() => _UsersState();
}

class _UsersState extends State<Users> {
  List<Map<String, dynamic>> _filteredUsers = []; // Store filtered data
  Map<String, bool> _selectedOptions = {}; // Checkbox states
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged); // Listen to search changes
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  // Function to handle search changes
  void _onSearchChanged() {
    setState(() {}); // Trigger rebuild to apply filtering
  }

  void _showUserInformation(Map<String, dynamic> user) {
    Navigator.pushNamed(
      context,
      '/userinformation',
      arguments: user,
    );
  }

  // Function to get color based on status
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'done':
        return const Color.fromARGB(255, 89, 167, 230);
      case 'booked':
        return const Color.fromARGB(255, 89, 169, 92);
      case 'unbooked':
      default:
        return Color(0xFFF5D322);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Sidebar(),
      body: Builder(
        builder: (context) => Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: Padding(
            padding: const EdgeInsets.only(top: 20, left: 40, right: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.menu, color: Colors.green, size: 25),
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                    ),
                    Text(
                      'Users',
                      style: GoogleFonts.poppins(
                        textStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                // Search Bar Row
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
                              'Search by name, category, contact, address, area, or status',
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                // Users List Container
                Container(
                  height: MediaQuery.of(context).size.height * .8,
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(border: Border.all()),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(child: Text('No users found.'));
                      }

                      // Map Firestore data to local users list
                      List<Map<String, dynamic>> usersList =
                          snapshot.data!.docs.map((doc) {
                        Map<String, dynamic> data =
                            doc.data() as Map<String, dynamic>;
                        return {
                          'id': doc.id,
                          'firstName': data['firstName'] ?? 'No First Name',
                          'lastName': data['lastName'] ?? 'No Last Name',
                          'category': data['category'] ?? 'Unknown',
                          'contact': data['contact'] ?? 'No Contact',
                          'address': data['address'] ?? 'No Address',
                          'area': data['area'] ?? 'No Area',
                          'email': data['email'] ?? 'No Email',
                          'balance': data['balance'] ?? 0.0,
                          'profileImage': data['profileImage'] ?? '',
                          'landmark': data['landmark'] ?? 'No Landmark',
                          'location': data['location'] ?? GeoPoint(0, 0),
                          'status': data['status'] ?? 'unbooked',
                        };
                      }).toList();

                      // Filter users for search
                      String searchTerm = _searchController.text.toLowerCase();
                      _filteredUsers = usersList.where((user) {
                        String fullName =
                            '${user['firstName']} ${user['lastName']}'
                                .toLowerCase();
                        return fullName.contains(searchTerm) ||
                            user['category']
                                .toLowerCase()
                                .contains(searchTerm) ||
                            user['contact']
                                .toLowerCase()
                                .contains(searchTerm) ||
                            user['address']
                                .toLowerCase()
                                .contains(searchTerm) ||
                            user['area']
                                .toLowerCase()
                                .contains(searchTerm) || // Area search
                            user['status'].toLowerCase().contains(
                                searchTerm); // Include status in search
                      }).toList();

                      return Column(
                        children: [
                          // Table Headers
                          Row(
                            children: [
                              title('Name', 3),
                              title('Category', 2),
                              title('Area', 2), // Add Area column
                              title('Contact', 2),
                              title('Address', 3),
                              title('Status', 2),
                              title('Details', 1),
                            ],
                          ),
                          // Users List
                          Expanded(
                            child: ListView.builder(
                              itemCount: _filteredUsers.length,
                              itemBuilder: (context, index) {
                                final user = _filteredUsers[index];
                                final uid = user['id'];

                                // Initialize checkbox state if not present
                                _selectedOptions[uid] =
                                    _selectedOptions[uid] ?? false;

                                return _buildCustomCheckboxTile(
                                  uid,
                                  '${user['firstName']} ${user['lastName']}',
                                  user['category'],
                                  user['contact'],
                                  user['address'],
                                  user['area'], // Add area data
                                  user['status'], // Include status
                                  user,
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Title widget for table headers
  Widget title(String text, int flex) {
    return Expanded(
      flex: flex,
      child: Container(
        height: 30,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(),
          ),
        ),
        child: Center(
          child: Text(
            text,
            style: GoogleFonts.roboto(
              textStyle: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Custom Checkbox List Tile for each user
  Widget _buildCustomCheckboxTile(
    String uid,
    String name,
    String category,
    String contact,
    String address,
    String area, // Added area
    String status, // Added status here
    Map<String, dynamic> user,
  ) {
    return CheckboxListTile(
      value: _selectedOptions[uid],
      activeColor: Colors.green,
      onChanged: (bool? value) {
        setState(() {
          _selectedOptions[uid] = value!;
        });
      },
      title: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              name,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(category),
          ),
          Expanded(
            flex: 2,
            child: Text(area), // Display area
          ),
          Expanded(
            flex: 2,
            child: Text(contact),
          ),
          Expanded(
            flex: 3,
            child: Text(address),
          ),
          Expanded(
            flex: 2,
            child: Container(
              height: 22.5,
              width: 50,
              decoration: BoxDecoration(
                color: _getStatusColor(status), // Use the status color
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  status,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              width: 50,
              child: IconButton(
                icon: Icon(Icons.info_outline),
                onPressed: () {
                  _showUserInformation(user);
                },
              ),
            ),
          ),
        ],
      ),
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
}
