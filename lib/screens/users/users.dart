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
  List<Map<String, dynamic>> _usersList = []; // Store user data locally
  List<Map<String, dynamic>> _filteredUsers = []; // Store filtered data
  Map<String, bool> _selectedOptions = {}; // Checkbox states
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _searchController.addListener(_onSearchChanged); // Listen to search changes
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  // Fetch user data from Firestore and put it in _usersList
  Future<void> _fetchUsers() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('users').get();
      List<Map<String, dynamic>> userList = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        return {
          'id': doc.id,
          'firstName': data['firstName'] ?? 'No First Name', // Default if null
          'lastName': data['lastName'] ?? 'No Last Name', // Default if null
          'category': data['category'] ?? 'Unknown', // Default if null
          'contact': data['contact'] ?? 'No Contact', // Default if null
          'address': data['address'] ?? 'No Address', // Default if null
          'email': data['email'] ?? 'No Email', // Default if null
          'balance': data['balance'] ?? 0.0, // Default if null
          'profileImage': data['profileImage'] ?? '', // Default profile image
          'landmark': data['landmark'] ?? 'No Landmark', // Default if null
          'location': data['location'] ?? GeoPoint(0, 0), // Default GeoPoint
        };
      }).toList();

      setState(() {
        _usersList = userList;
        _filteredUsers = userList; // Initialize filtered list with all users
      });
    } catch (e) {
      print('Error fetching users: $e');
      // Optionally, show an error message to the user
    }
  }

  // Function to handle search changes
  void _onSearchChanged() {
    String searchTerm = _searchController.text.toLowerCase();
    setState(() {
      _filteredUsers = _usersList.where((user) {
        String fullName =
            '${user['firstName']} ${user['lastName']}'.toLowerCase();
        return fullName.contains(searchTerm) ||
            user['category'].toLowerCase().contains(searchTerm) ||
            user['contact'].toLowerCase().contains(searchTerm) ||
            user['address'].toLowerCase().contains(searchTerm) ||
            user['status'].toLowerCase().contains(searchTerm);
      }).toList();
    });
  }

  void _showUserInformation(Map<String, dynamic> user) {
    Navigator.pushNamed(
      context,
      '/userinformation',
      arguments: user,
    );
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
                              'Search by name, category, contact, address, or status',
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                // Users List Container
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(border: Border.all()),
                    child: Column(
                      children: [
                        // Table Headers
                        Row(
                          children: [
                            title('Name', 3),
                            title('Category', 2),
                            title('Contact', 2),
                            title('Address', 3),
                            title('Status', 2),
                            title('Details', 1),
                          ],
                        ),
                        // Users List
                        Expanded(
                          child: _filteredUsers.isNotEmpty
                              ? ListView.builder(
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
                                      // user['status'],
                                      user,
                                    );
                                  },
                                )
                              : Center(child: Text('No users found.')),
                        ),
                      ],
                    ),
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
    // String status,
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
            child: Text(contact),
          ),
          Expanded(
            flex: 3,
            child: Text(address),
          ),
          Expanded(
            flex: 2,
            child: Text('unbooked'),
          ),
          Expanded(
            flex: 1,
            child: IconButton(
              icon: Icon(Icons.info_outline),
              onPressed: () {
                _showUserInformation(user);
              },
            ),
          ),
        ],
      ),
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
}


// Color _getStatusColor(String status) {
//   switch (status.toLowerCase()) {
//     case 'booked':
//       return Color.fromARGB(255, 66, 167, 250);
//     case 'completed':
//       return Color.fromARGB(255, 76, 181, 80);
//     case 'in progress':
//       return Colors.grey;
//     case 'delayed':
//       return Color.fromARGB(255, 249, 81, 70);
//     case 'unbooked':
//       return Color(0xFFF5D322);
//     default:
//       return Color.fromARGB(255, 150, 141, 61);
//   }
// }
