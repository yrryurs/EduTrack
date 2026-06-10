import 'package:flutter/material.dart';
import 'screens/welcome.dart';

AppBar myAppBar(String title) {
  return AppBar(
    backgroundColor: const Color.fromARGB(255, 2, 11, 63),
    iconTheme: IconThemeData(color: Colors.white),
    centerTitle: true,
    title: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset('assets/images/logo.png', height: 30, color: Colors.white),
        SizedBox(width: 15),
        Text(title, style: TextStyle(color: Colors.white)),
      ],
    ),
  );
}

void main() {
  runApp(EduTrackApp());
}

class EduTrackApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EduTrack',
      theme: ThemeData(
        fontFamily: 'Georgia',
        appBarTheme: AppBarTheme(
          backgroundColor: const Color.fromARGB(255, 2, 11, 63),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: WelcomeScreen(),
    );
  }
}
