import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:trashure_thesis/sidebar.dart';
import 'package:google_fonts/google_fonts.dart';

class Finance extends StatefulWidget {
  const Finance({super.key});

  @override
  State<Finance> createState() => _FinanceState();
}

class _FinanceState extends State<Finance> {
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
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 5,
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.menu,
                                  color: Colors.green, size: 25),
                              onPressed: () {
                                Scaffold.of(context)
                                    .openDrawer(); // Opens the drawer
                              },
                            ),
                            Text(
                              'Finance',
                              textAlign: TextAlign.left,
                              style: GoogleFonts.poppins(
                                  textStyle: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20)),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Container(
                              height: 30,
                              decoration: BoxDecoration(
                                  border: Border.all(),
                                  // top: BorderSide(),
                                  // bottom: BorderSide(),
                                  // left: BorderSide()),
                                  borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(17.5),
                                      bottomLeft: Radius.circular(17.5))),
                              child: IconButton(
                                iconSize: 17,
                                color: Color.fromARGB(255, 74, 73, 73),
                                icon: Icon(Icons.search),
                                onPressed: () {
                                  // Handle button press
                                },
                                tooltip: 'Home',
                              ),
                            ),
                            Container(
                              height: 30,
                              width: 400,
                              decoration: BoxDecoration(
                                  border: Border.all(),
                                  // top: BorderSide(),
                                  // bottom: BorderSide(),
                                  // left: BorderSide()),

                                  borderRadius: BorderRadius.only(
                                      topRight: Radius.circular(17.5),
                                      bottomRight: Radius.circular(17.5))),
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: 'Search',
                                  border: InputBorder
                                      .none, // Removes the default TextField border
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 20,
                            ),
                            ElevatedButton(
                              onPressed: () {
                                // Handle button press
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF4CAF4F),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30)),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8), // Button padding
                                textStyle:
                                    TextStyle(fontSize: 16), // Text style
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize
                                    .min, // Keep the button size minimal
                                children: [
                                  SizedBox(
                                      width: 8), // Space between icon and text
                                  Text(
                                    'Schedule Pick Up',
                                    style: GoogleFonts.roboto(
                                        textStyle: TextStyle(
                                            fontWeight: FontWeight.w300)),
                                  ), // The text
                                  Icon(Icons.add), // The icon
                                ],
                              ),
                            )
                          ],
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        Container(
                          height: MediaQuery.of(context).size.height * .825,
                          width: MediaQuery.of(context).size.width,
                          decoration: BoxDecoration(border: Border.all()),
                          child: Column(
                            children: [
                              Container(
                                child: Row(
                                  children: [
                                    title('Name', 2),
                                    title('Address', 2),
                                    title('Date Booked', 1),
                                    title('Est. Total Weight', 1),
                                    title('Type', 1),
                                    title('Status', 1),
                                    title('Details', 1),
                                  ],
                                ),
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ))),
    );
  }

  Widget title(String text, int fl) {
    return Expanded(
        flex: fl,
        child: Container(
          height: 20,
          decoration: BoxDecoration(
              border: Border(
            bottom: BorderSide(),
          )),
          child: Center(
            child: Text(
              text,
              style: GoogleFonts.roboto(
                  textStyle: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ));
  }
}
