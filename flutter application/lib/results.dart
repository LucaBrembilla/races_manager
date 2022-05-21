import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import './globals.dart';
// ignore: unused_import
import './Aggiornamento.dart';

Future<List<Map<String, dynamic>>> richiestaRisultati(
    String raceid, String category) async {
  final response =
      await http.get(Uri.parse('$apiUrl/results?id=$raceid&class=$category'));

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

class LeaderboardRoute extends StatefulWidget {
  final String raceid;
  final String category;
  const LeaderboardRoute(this.raceid, this.category, {Key? key})
      : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _LeaderboardRouteState createState() => _LeaderboardRouteState();
}

class _LeaderboardRouteState extends State<LeaderboardRoute> {
  late Future<List<Map<String, dynamic>>> futureResults;

  @override
  void initState() {
    super.initState();
    futureResults = richiestaRisultati(widget.raceid, widget.category);
  }

  @override
  Widget build(BuildContext context) {
    // ignore: no_leading_underscores_for_local_identifiers
    final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
        GlobalKey<RefreshIndicatorState>();
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 175, 175, 175),
      appBar: AppBar(
        title: const Text('Risultati'),
        elevation: 10,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (BuildContext context) => super.widget));
        },
        child: Center(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: futureResults,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                List<Map<String, dynamic>> result = snapshot.data!;
                return ListView.builder(
                    itemCount: result.length,
                    itemBuilder: ((context, index) => TextField(
                            decoration: InputDecoration(
                          hintText: result[index]["position"] +
                              result[index]["id"] +
                              result[index]["personName"] +
                              result[index]["personSurname"],
                          hintStyle: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 255, 255, 255)),
                          border: OutlineInputBorder(),
                        ))));
              } else if (snapshot.hasError) {
                return Text('${snapshot.error}');
              }

              // By default, show a loading spinner.
              return const CircularProgressIndicator();
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
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
      ),
    );
  }
}
