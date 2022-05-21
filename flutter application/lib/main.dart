import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import './globals.dart';
import './classes_route.dart';

Future<List<Map<String, dynamic>>> fetchRaces() async {
  final response = await http.get(Uri.parse('$apiUrl/list_races'));

  if (response.statusCode == 200) {
    // If the server did return a 200 OK response,
    // then parse the JSON.
    return List<Map<String, dynamic>>.from(jsonDecode(response.body));
  } else {
    // If the server did not return a 200 OK response,
    // then throw an exception.
    throw Exception('Failed to load classes');
  }
}

void main() {
  runApp(const MaterialApp(
    title: 'Ori Live Results',
    home: MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<List<Map<String, dynamic>>> futureRaces;

  @override
  void initState() {
    super.initState();
    futureRaces = fetchRaces();
  }

  @override
  Widget build(BuildContext context) {
    final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
        GlobalKey<RefreshIndicatorState>();
    return Scaffold(
      drawerScrimColor: Color.fromARGB(255, 0, 0, 0),
      backgroundColor: Color.fromARGB(255, 0, 0, 0),
      appBar: AppBar(
        title: const Text('Gare',
            style:
                TextStyle(color: Color.fromARGB(255, 0, 0, 0), fontSize: 30)),
        elevation: 10,
        centerTitle: true,
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
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: futureRaces,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                var classes = snapshot.data!;
                return ListView.builder(
                  itemCount: classes.length,
                  itemBuilder: ((context, index) => ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ClassesRoute(classes[index]["ID"]),
                            ),
                          );
                        },
                        child: Text(classes[index]["Nome"],
                            style: TextStyle(
                                fontSize: 20,
                                color: Color.fromARGB(255, 63, 36, 0))),
                        style: ElevatedButton.styleFrom(
                          primary: Color.fromARGB(248, 204, 122, 0),
                          side: BorderSide(
                              width: 2, color: Color.fromARGB(255, 63, 36, 0)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 50, vertical: 8),
                        ),

                        /* style: ElevatedButton.styleFrom(          /per cambiare stile tasti
                        primary: Color.fromARGB(255, 12, 1, 14),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 50, vertical: 20),
                        textStyle: const TextStyle(
                            fontSize: 30, fontWeight: FontWeight.bold))*/
                      )),
                );
              } else if (snapshot.hasError) {
                return Text('${snapshot.error}');
              }
              // By default, show a loading spinner.
              return const CircularProgressIndicator();
            },
          ),
        ),
      ),
      /*floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Show refresh indicator programmatically on button tap.
          _refreshIndicatorKey.currentState?.show();
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (BuildContext context) => super.widget));
        },
        icon: const Icon(Icons.refresh, color: ,),
        label: Text(''),
        backgroundColor: Color.fromARGB(255, 202, 138, 0),
      ),*/
    );
  }
}
