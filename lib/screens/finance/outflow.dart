import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:trashure_thesis/sidebar.dart';

class Outflow extends StatefulWidget {
  const Outflow({super.key});

  @override
  State<Outflow> createState() => _OutflowState();
}

class _OutflowState extends State<Outflow> {
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
                          'Outflow',
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
                            // controller: _searchController,
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
                            // _showAddVehicleDialog(
                            //     context); // Call add vehicle function
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
                            // _assignDriverToVehicles();
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
}
