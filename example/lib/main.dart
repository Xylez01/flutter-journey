import 'package:flutter/material.dart';
import 'package:journey/journey.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'migrations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final sharedPreferences = await SharedPreferences.getInstance();

  runApp(JourneyExampleApp(
    sharedPreferences: sharedPreferences,
  ));
}

class JourneyExampleApp extends StatelessWidget {
  const JourneyExampleApp({
    required this.sharedPreferences,
    Key? key,
  }) : super(key: key);

  final SharedPreferences sharedPreferences;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Journey example app',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        body: JourneyHomepage(
          sharedPreferences: sharedPreferences,
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class JourneyHomepage extends StatefulWidget {
  const JourneyHomepage({
    required this.sharedPreferences,
    Key? key,
  }) : super(key: key);

  final SharedPreferences sharedPreferences;

  @override
  State<JourneyHomepage> createState() => _JourneyHomepageState();
}

class _JourneyHomepageState extends State<JourneyHomepage> {
  late Journey _journey;

  @override
  Widget build(BuildContext context) {
    final backgroundImage =
        widget.sharedPreferences.getString("background_image") ??
            "background-purple.jpg";

    final migrations = {
      "Migrate to new style": MigrateToNewBackgroundImage(
        sharedPreferences: widget.sharedPreferences,
      ),
      "Migrate to new name": MigrateToNewStyle(
        sharedPreferences: widget.sharedPreferences,
      ),
    };

    _journey = Journey(
      migrations: migrations.values.toList(),
    );

    return Stack(
      children: [
        SizedBox.expand(
          child: Image(
            image: AssetImage("images/$backgroundImage"),
            fit: BoxFit.cover,
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              widget.sharedPreferences.getString("app_name") ?? "Journey",
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: <Shadow>[
                  Shadow(
                    offset: Offset(2.0, 2.0),
                    blurRadius: 3.0,
                    color: Colors.black,
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: ElevatedButton(
                      child: const Text("Migrate"),
                      onPressed: () async {
                        await _journey.migrate();
                        setState(() {});
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: ElevatedButton(
                      child: const Text("Rollback"),
                      onPressed: () async {
                        await _journey.rollback();
                        setState(() {});
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
      ],
    );
  }
}
