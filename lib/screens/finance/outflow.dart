import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:trashure_thesis/sidebar.dart';

class Outflow extends StatefulWidget {
  const Outflow({super.key});

  @override
  State<Outflow> createState() => _OutflowState();
}

class _OutflowState extends State<Outflow> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
                                  'Search by category, name, status, or other fields',
                              border: InputBorder.none,
                              prefixIcon: Icon(Icons.search),
                            ),
                          ),
                        ),
                        SizedBox(width: 20),
                        ElevatedButton(
                          onPressed: () {
                            // _showAddOutflowDialog(context); // Call add outflow function
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
                                'Add Outflow',
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
                    Expanded(
                      child: Container(
                        height: MediaQuery.of(context).size.height * .825,
                        decoration: BoxDecoration(border: Border.all()),
                        child: Column(
                          children: [
                            Container(
                              child: Row(
                                children: [
                                  title('Document ID', 2),
                                  title('Category', 2),
                                  title('Details', 2),
                                  title('Employee', 2),
                                  title('Total Amount', 1),
                                  title('Status', 1),
                                ],
                              ),
                            ),
                            Expanded(
                              child: StreamBuilder<QuerySnapshot>(
                                stream: _firestore
                                    .collection('outflow')
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) {
                                    return Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }

                                  final outflowList = snapshot.data!.docs;

                                  return ListView.builder(
                                    itemCount: outflowList.length,
                                    itemBuilder: (context, index) {
                                      final outflowData = outflowList[index];
                                      return Container(
                                        decoration: BoxDecoration(
                                          border: Border(
                                            bottom: BorderSide(),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              flex: 2,
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Text(outflowData.id),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Text(
                                                    outflowData['category']),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Text(
                                                    outflowData['details']),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Text(
                                                    outflowData['employee']),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 1,
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Text(
                                                    outflowData['total_amount']
                                                        .toString()),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 1,
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child:
                                                    Text(outflowData['status']),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
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
