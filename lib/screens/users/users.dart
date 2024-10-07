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
  }

  // Fetch user data from Firestore and put it in _usersList
  Future<void> _fetchUsers() async {
    final snapshot = await FirebaseFirestore.instance.collection('users').get();
    List<Map<String, dynamic>> userList = snapshot.docs.map((doc) {
      return {
        'id': doc.id,
        'name': doc['name'],
        'category': doc['category'],
        'contact': doc['contact'],
        'address': doc['address'],
        'email': doc['email'],
        'uid': doc['uid'],
        'status': doc['status'] ??
            'unbooked', // Default to 'unbooked' if status is empty or null
      };
    }).toList();

    setState(() {
      _usersList = userList;
      _filteredUsers = userList; // Initialize filtered list with all users
    });
  }

  // Function to handle search changes
  void _onSearchChanged() {
    String searchTerm = _searchController.text.toLowerCase();
    setState(() {
      _filteredUsers = _usersList.where((user) {
        return user['name'].toLowerCase().contains(searchTerm) ||
            user['category'].toLowerCase().contains(searchTerm) ||
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
                          hintText: 'Search by employee name, id, or position',
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
                            title('Category', 1),
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
                                user['category'],
                                user['contact'],
                                user['address'],
                                user['uid'],
                                user['status'],
                                user,
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
        return Color.fromARGB(255, 150, 141, 61);
    }
  }

  Widget _buildCustomCheckboxTile(
    String uid,
    String name,
    String category,
    String contact,
    String address,
    String userId,
    String status,
    Map<String, dynamic> user,
  ) {
    String displayStatus = status.isEmpty ? 'unbooked' : status;

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
              flex: 2,
              child: Text(name, style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 1, child: Text(category)),
          Expanded(flex: 1, child: Text(contact)),
          Expanded(flex: 2, child: Text(address)),
          Expanded(flex: 1, child: Text(userId)),
          Expanded(
            flex: 1,
            child: Container(
              height: 22.5,
              width: 30,
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
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
}
