import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import './globals.dart';
import './starting_grid.dart';

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

Color getColor(String date) {
  if (DateTime.now().difference(DateTime.parse(date)).inMinutes > 4)
    return Color.fromARGB(255, 255, 255, 255);
  else
    return Color.fromARGB(255, 53, 227, 5);
}

Color getColorStarted(String time){
  if(time != "0")
    return Color.fromARGB(255, 255, 255, 255); 
  else
    return Color.fromARGB(255, 255, 1, 1);
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
      drawerScrimColor: Color.fromARGB(255, 0, 0, 0),
      backgroundColor: Color.fromARGB(255, 0, 0, 0),
      appBar: AppBar(
        leading: BackButton(color: Colors.black),
        title: const Text('Risultati',style:
                TextStyle(color: Color.fromARGB(255, 0, 0, 0), fontSize: 30)),
        elevation: 10,
        centerTitle: true,
        backgroundColor: Color.fromARGB(255, 202, 138, 0),),
      body: GestureDetector(
        onPanUpdate: (details) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  StartingGridRoute(widget.raceid, widget.category),
            ),
          );
        },
        child: RefreshIndicator(
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
                  return ListView.builder(
                      itemCount: result.length,
                      // ignore: prefer_interpolation_to_compose_strings
                                            itemBuilder: ((context, index) => RichText(  text: TextSpan(
                                    children: <TextSpan>[
                                      TextSpan(
                                        text: " POSIZIONE: " + result[index]["position"]+ "\n",
                                        style: TextStyle(color: Colors.white.withOpacity(0.6)),
                                      ),
                                      TextSpan(
                                        text: " ID: " + result[index]["id"]+ "\n",
                                        style: TextStyle(color: Colors.white.withOpacity(0.7)),
                                      ),
                                      TextSpan(
                                        text: " ATLETA: " +  result[index]["personName"] + " "+   result[index]["personSurname"]  + "\n",
                                        style: TextStyle(color: Colors.white.withOpacity(0.8)),
                                      ),
                                      TextSpan(
                                        text: " ARRIVO: " +   DateTime.parse( result[index]["finishTime"] ).toLocal().toString().substring(0, DateTime.parse( result[index]["finishTime"] ).toLocal().toString().length - 4) +"\n",
                                        style: TextStyle(color: getColor(result[index]["finishTime"])),
                                      ),
                                      TextSpan(
                                        text: " TEMPO: " +  result[index]["raceTime"]  + " s " + "\n",
                                        style: TextStyle(color: getColorStarted(result[index]["raceTime"])),
                                      ),
                                    ],
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