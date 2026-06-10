import 'package:flutter/material.dart';
import 'homepage.dart';
import '../db_helper.dart';

class WelcomeScreen extends StatefulWidget {
  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _isExistingUser = false;

  @override
  void initState() {
    super.initState();
    _checkUser();
  }

  void _checkUser() async {
    String? userName = await DBHelper().getUserName();
    if (userName != null) {
      setState(() => _isExistingUser = true);
      Future.delayed(Duration(seconds: 3), () {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomePage(userName: userName)),
        );
      });
    }
  }

  void _saveNameAndContinue() async {
    String name = _nameController.text.trim();
    if (name.isNotEmpty) {
      await DBHelper().insertUser(name);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomePage(userName: name)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Color textColor = const Color.fromARGB(255, 206, 206, 193);
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 2, 11, 63),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/logo.png',
                height: 90,
                color: textColor,
              ),
              SizedBox(height: 20),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  children: [
                    TextSpan(
                      text: "Welcome to EduTrack !",
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    TextSpan(
                      text:
                          "\n\nOrganize your student's \nlife better with EduTrack",
                    ),
                  ],
                ),
              ),
              if (!_isExistingUser) ...[
                SizedBox(height: 30),
                TextField(
                  controller: _nameController,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    labelText: 'Enter your nickname',
                    labelStyle: TextStyle(color: textColor),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: textColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: textColor),
                    ),
                  ),
                ),
                SizedBox(height: 30),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 206, 206, 193),
                  ),
                  child: Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 15,
                      color: const Color.fromARGB(255, 2, 11, 63),
                    ),
                  ),
                  onPressed: _saveNameAndContinue,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
