import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:trashure_thesis/sidebar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserHouse extends StatefulWidget {
  const UserHouse({super.key});

  @override
  State<UserHouse> createState() => _UserHouseState();
}

class _UserHouseState extends State<UserHouse> {
  List<Map<String, dynamic>> _usersList = []; // Store user data locally
  List<Map<String, dynamic>> _filteredUsers = []; // Store filtered data
  Map<String, bool> _selectedOptions = {}; // Checkbox states
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  // Fetch user data from Firestore and filter by 'household' category
  Future<void> _fetchUsers() async {
    final snapshot = await FirebaseFirestore.instance.collection('users').get();
    List<Map<String, dynamic>> userList = snapshot.docs.map((doc) {
      return {
        'id': doc.id,
        'name': doc['name'],
        'category': doc['category'],
        'contact': doc['contact'],
        'address': doc['address'],
        'uid': doc['uid'],
        'status': doc['status'] ?? 'unbooked' // Default to 'unbooked'
      };
    }).toList();

    // Filter by 'household' category
    List<Map<String, dynamic>> filteredList =
        userList.where((user) => user['category'] == 'household').toList();

    setState(() {
      _usersList = filteredList;
      _filteredUsers =
          filteredList; // Initialize filtered list with 'household' users
    });
  }

  // Function to handle search changes
  void _onSearchChanged() {
    String searchTerm = _searchController.text.toLowerCase();
    setState(() {
      _filteredUsers = _usersList.where((user) {
        return user['name'].toLowerCase().contains(searchTerm) ||
            user['contact'].toLowerCase().contains(searchTerm) ||
            user['address'].toLowerCase().contains(searchTerm) ||
            user['uid'].toLowerCase().contains(searchTerm) ||
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
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.menu, color: Colors.green, size: 25),
                      onPressed: () {
                        Scaffold.of(context).openDrawer(); // Opens the drawer
                      },
                    ),
                    Text(
                      'Household Users',
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
                // Search Bar
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
                          hintText: 'Search by name, contact, address, or UID',
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (value) {
                          _onSearchChanged();
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(border: Border.all()),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            title('Name', 2),
                            title('Contact', 1),
                            title('Address', 2),
                            title('UID', 1),
                            title('Status', 1),
                            title('Details', 1),
                          ],
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _filteredUsers.length,
                            itemBuilder: (context, index) {
                              final user = _filteredUsers[index];
                              final uid = user['uid'];

                              // Initialize checkbox state if not present
                              _selectedOptions[uid] =
                                  _selectedOptions[uid] ?? false;

                              return _buildCustomCheckboxTile(
                                uid,
                                user['name'],
                                user['contact'],
                                user['address'],
                                user['uid'],
                                user['status'],
                                user, // Use status from the list
                              );
                            },
                          ),
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

  // Adjusted title widget
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

  // Function to determine status color based on status string
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'booked':
        return Color.fromARGB(255, 66, 167, 250);
      case 'completed':
        return Color.fromARGB(255, 76, 181, 80);
      case 'in progress':
        return Colors.grey;
      case 'delayed':
        return Color.fromARGB(255, 249, 81, 70);
      case 'unbooked':
        return Color(0xFFF5D322);
      default:
        return Color.fromARGB(255, 150, 141, 61); // Default color if no match
    }
  }

  // CheckboxListTile to display user details with status and icon for details
  Widget _buildCustomCheckboxTile(
    String uid,
    String name,
    String contact,
    String address,
    String userId,
    String status,
    Map<String, dynamic> user,
  ) {
    // Ensure the status is never empty or null
    String displayStatus = status.isEmpty ? 'unbooked' : status;

    return CheckboxListTile(
      value: _selectedOptions[uid],
      activeColor: Colors.green, // Turns green when checked
      onChanged: (bool? value) {
        setState(() {
          _selectedOptions[uid] = value!;
        });
      },
      title: Row(
        children: [
          Expanded(
              flex: 2,
              child: Text(name, style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 1, child: Text(contact)),
          Expanded(flex: 2, child: Text(address)),
          Expanded(flex: 1, child: Text(userId)),
          Expanded(
            flex: 1,
            child: Container(
              height: 22.5,
              width: 50,
              decoration: BoxDecoration(
                color: _getStatusColor(displayStatus),
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
                  displayStatus,
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
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
      controlAffinity: ListTileControlAffinity.leading, // Checkbox on the left
    );
  }
}
