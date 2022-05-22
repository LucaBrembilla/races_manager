import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import './globals.dart';
import './results.dart';
import './starting_grid.dart';

Future<List<String>> fetchClasses(String raceid) async {
  final response = await http.get(Uri.parse('$apiUrl/listclasses?id=$raceid'));

  if (response.statusCode == 200) {
    // If the server did return a 200 OK response,
    // then parse the JSON.
    return List<String>.from(jsonDecode(response.body));
  } else {
    // If the server did not return a 200 OK response,
    // then throw an exception.
    throw Exception('Failed to load classes');
  }
}

class ClassesRoute extends StatefulWidget {
  final String raceid;
  const ClassesRoute(this.raceid, {Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _ClassesRouteState createState() => _ClassesRouteState();
}

class _ClassesRouteState extends State<ClassesRoute> {
  late Future<List<String>> futureClasses;

  @override
  void initState() {
    super.initState();
    futureClasses = fetchClasses(widget.raceid);
  }

  @override
  Widget build(BuildContext context) {
    final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
        GlobalKey<RefreshIndicatorState>();
    return Scaffold(
      drawerScrimColor: Color.fromARGB(255, 0, 0, 0),
      backgroundColor: Color.fromARGB(255, 0, 0, 0),
      appBar: AppBar(
        leading: BackButton(color: Colors.black),
        title: const Text('Categorie',
            style:
                TextStyle(color: Color.fromARGB(255, 0, 0, 0), fontSize: 30)),
        elevation: 10,
        backgroundColor: Color.fromARGB(255, 202, 138, 0),
      ),
      body: RefreshIndicator(
        color: Color.fromARGB(255, 0, 0, 0),
        backgroundColor: Color.fromARGB(255, 202, 138, 0),
        onRefresh: () async {
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (BuildContext context) => super.widget));
        },
        child: Center(
          child: FutureBuilder<List<String>>(
            future: futureClasses,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                List<String> classes = snapshot.data!;
                return ListView.builder(
                    itemCount: classes.length,
                    itemBuilder: ((context, index) => ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => StartingGridRoute(
                                    widget.raceid, classes[index]),
                              ),
                            );
                          },
                          child: Text(classes[index],
                              style: TextStyle(
                                  fontSize: 20,
                                  color: Color.fromARGB(255, 63, 36, 0))),
                          style: ElevatedButton.styleFrom(
                            primary: Color.fromARGB(248, 204, 122, 0),
                            side: BorderSide(
                                width: 2,
                                color: Color.fromARGB(255, 63, 36, 0)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 50, vertical: 8),
                          ),
                        )));
              } else if (snapshot.hasError) {
                return Text('${snapshot.error}');
              }

              // By default, show a loading spinner.
              return const CircularProgressIndicator(
                color: Color.fromARGB(248, 204, 122, 0),
              );
            },
          ),
        ),
      ),
      /* floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Show refresh indicator programmatically on button tap.
          _refreshIndicatorKey.currentState?.show();
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (BuildContext context) => super.widget));
        },
        icon: const Icon(Icons.refresh),
        label: const Text('Refresh'),
      ),*/
    );
  }
}