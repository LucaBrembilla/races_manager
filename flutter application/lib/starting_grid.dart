// ignore_for_file: prefer_interpolation_to_compose_strings

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import './globals.dart';
import './results.dart';
// ignore: unused_import

Future<List<Map<String, dynamic>>> richiestaDati(
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

class StartingGridRoute extends StatefulWidget {
  final String raceid;
  final String category;
  const StartingGridRoute(this.raceid, this.category, {Key? key})
      : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _StartingGridRoute createState() => _StartingGridRoute();
}

class _StartingGridRoute extends State<StartingGridRoute> {
  late Future<List<Map<String, dynamic>>> futureResults;

  @override
  void initState() {
    super.initState();
    futureResults = richiestaDati(widget.raceid, widget.category);
  }

  @override
  Widget build(BuildContext context) {
    // ignore: no_leading_underscores_for_local_identifiers
    final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
        GlobalKey<RefreshIndicatorState>();
    return Scaffold(
      drawerScrimColor: Color.fromARGB(255, 0, 0, 0),
      backgroundColor: Color.fromARGB(255, 0, 0, 0),
      appBar: AppBar(
        leading: BackButton(color: Colors.black),
        title: const Text('Griglia Di Partenza',
        style: TextStyle(color: Color.fromARGB(255, 0, 0, 0), fontSize: 30)),
        elevation: 10,
        centerTitle: true,
        backgroundColor: Color.fromARGB(255, 202, 138, 0),
     ),
      body: GestureDetector(
        onPanUpdate: (details) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  LeaderboardRoute(widget.raceid, widget.category),
            ),
          );
        },
        child:RefreshIndicator(
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
              future: futureResults,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  List<Map<String, dynamic>> result = snapshot.data!;
                  List<Map<String, dynamic>> listCopy = List.of(result);
                  listCopy.sort((a, b) {
                    return (a['startTime']).compareTo(b['startTime']);
                  });
                  return ListView.builder(
                      itemCount: result.length,
                       itemBuilder: ((context, index) => RichText(  text: TextSpan(
                                    children: <TextSpan>[
                                      TextSpan(
                                        text: " ID: " + listCopy[index]["id"]+ "\n",
                                        style: TextStyle(color: Colors.white.withOpacity(0.6)),
                                      ),
                                      TextSpan(
                                        text: " ATLETA: " +  listCopy[index]["personName"] + " "+  listCopy[index]["personSurname"]  + "\n",
                                        style: TextStyle(color: Colors.white.withOpacity(0.8)),
                                      ),
                                      TextSpan(
                                        text: " PARTENZA: " +  DateTime.parse( listCopy[index]["startTime"] ).toLocal().toString().substring(0, DateTime.parse( result[index]["startTime"] ).toLocal().toString().length - 4) +"\n",
                                        style: TextStyle(color: Colors.white.withOpacity(1.0)),
                                      ),
                                    ],
                                  ),
                          )));
               /*       itemBuilder: ((context, index) => Text(  "ID: " + 
                          listCopy[index]["id"]+ " - ATLETA: " + 
                           listCopy[index]["personName"] + " " + 
                           listCopy[index]["personSurname"] + " - PARTENZA: " + 
                           listCopy[index]["startTime"], 
                           style: TextStyle(
                              color: getColor(result[index]["finishTime"])))));*/
                          
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