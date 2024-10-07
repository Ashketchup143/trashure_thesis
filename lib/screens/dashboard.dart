import 'package:flutter/material.dart';
import 'package:trashure_thesis/sidebar.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  Map<String, bool> _selectedOptions = {
    '1': false,
    '2': false,
    '3': false,
    '4': false,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Sidebar(), // Add the Sidebar (Drawer) here
      body: Builder(
        builder: (context) => Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: Column(
            children: [
              // Add hamburger button here
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.menu, color: Colors.green, size: 25),
                      onPressed: () {
                        Scaffold.of(context).openDrawer(); // Opens the drawer
                      },
                    ),
                    SizedBox(width: 10), // Space between icon and title
                    Text(
                      'Dashboard',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildCustomCheckboxTile('1', 'John Doe', '123 Main St',
                          '2024-09-01', '50kg', 'Recyclable', 'Complete'),
                      _buildCustomCheckboxTile('2', 'Jane Smith', '456 Elm St',
                          '2024-09-05', '30kg', 'Organic', 'Pending'),
                      _buildCustomCheckboxTile('3', 'Alice Brown', '789 Oak St',
                          '2024-09-10', '20kg', 'Plastic', 'In Progress'),
                      _buildCustomCheckboxTile('4', 'Alice Brown', '789 Oak St',
                          '2024-09-10', '20kg', 'Plastic', 'In Progress'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomCheckboxTile(
    String option,
    String name,
    String address,
    String dateBooked,
    String totalWeight,
    String typeStatus,
    String details,
  ) {
    return CheckboxListTile(
      value: _selectedOptions[option],
      activeColor: Colors.green,
      onChanged: (bool? value) {
        setState(() {
          _selectedOptions[option] = value!;
        });
      },
      title: Row(
        children: [
          Expanded(
              flex: 2,
              child: Text(name,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
          Expanded(flex: 3, child: Text('Address: $address')),
          Expanded(flex: 2, child: Text('Date: $dateBooked')),
          Expanded(flex: 2, child: Text('Weight: $totalWeight')),
          Expanded(flex: 2, child: Text('Type: $typeStatus')),
          Expanded(flex: 2, child: Text('Details: $details')),
        ],
      ),
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
}

    // Custom Checkbox Tile for multiple selections
    // Widget _buildCustomCheckboxTile(String option) {
    //   return CheckboxListTile(
    //     value: _selectedOptions[option],
    //     activeColor: Colors.green, // Turns green when checked
    //     // Background color when checked
    //     onChanged: (bool? value) {
    //       setState(() {
    //         _selectedOptions[option] = value!;
    //       });
    //     },
    //     controlAffinity: ListTileControlAffinity.leading, // Checkbox on the left
    //   );
  
