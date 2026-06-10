import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'habit_list.dart';
import 'progress.dart';
import '../main.dart';
import '../quote_service.dart';
import '../db_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  final String userName;
  const HomePage({required this.userName, super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String quote = '';
  String author = '';
  bool isQuoteLoading = true;
  double habitFinished = 0;
  double totalHabits = 0;
  double completionRate = 0;

  @override
  void initState() {
    super.initState();
    _loadQuote();
    _loadTodayProgress();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showVibrationTip();
    });
  }

  Future<void> _showVibrationTip() async {
    final prefs = await SharedPreferences.getInstance();
    bool tipShown = prefs.getBool('vibrationTipShown') ?? false;
    if (!tipShown) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Tip: Enable system vibration (vibrate on tap) in your phone settings to feel vibration when completing a habit!",
          ),
          duration: Duration(seconds: 10),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(12),
        ),
      );
      await prefs.setBool('vibrationTipShown', true);
    }
  }

  Future<void> _loadQuote() async {
    setState(() {
      isQuoteLoading = true;
    });
    final q = await QuoteService().fetchQuote();
    setState(() {
      quote = q['quote']!;
      author = q['author']!;
      isQuoteLoading = false;
    });
  }

  Future<void> _loadTodayProgress() async {
    final db = DBHelper();
    final habits = await db.getHabits();
    DateTime today = DateTime.now();
    List<Map<String, dynamic>> activeHabits = habits.where((habit) {
      String freq = habit['frequency'] ?? 'Everyday';
      if (freq == 'Everyday') return true;
      if (freq == 'Days') {
        String daysStr = habit['selectedDays'] ?? '';
        List<String> days = daysStr.split(',').map((e) => e.trim()).toList();
        String weekday = DateFormat('EEE').format(today);
        return days.contains(weekday);
      }
      if (freq == 'Date') {
        int? dayOfMonth = habit['dayOfMonth'];
        return dayOfMonth == today.day;
      }
      return false;
    }).toList();
    totalHabits = activeHabits.length.toDouble();
    String todayStr =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
    final habitLogs = await db.getHabitLogsByDate(todayStr);
    habitFinished = habitLogs
        .where((log) => log['isCompleted'] == 1)
        .length
        .toDouble();
    completionRate = totalHabits == 0 ? 0 : habitFinished / totalHabits;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('EEEE (d MMMM yyyy)').format(now);
    return Scaffold(
      appBar: myAppBar('EduTrack'),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: const AssetImage('assets/images/bg.png'),
                repeat: ImageRepeat.repeat,
                fit: BoxFit.none,
                colorFilter: ColorFilter.mode(
                  const Color.fromARGB(255, 129, 129, 109).withOpacity(0.48),
                  BlendMode.dstATop,
                ),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Card(
                    color: const Color.fromARGB(255, 2, 11, 63),
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 20,
                      ),
                      child: Text(
                        'Hi ${widget.userName}, hope you \nhave a good day today !',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 206, 206, 193),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Column(
                    children: [
                      const Text(
                        'Today:',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 2, 11, 63),
                        ),
                      ),
                      Text(
                        formattedDate,
                        style: const TextStyle(
                          fontSize: 20,
                          color: Color.fromARGB(255, 2, 11, 63),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 1),
                  SizedBox(
                    height: 250,
                    width: 250,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: completionRate,
                        color: const Color.fromARGB(255, 2, 11, 63),
                        backgroundColor: const Color.fromARGB(
                          255,
                          206,
                          206,
                          193,
                        ),
                        strokeWidth: 160,
                      ),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    "Progress Done: ${(completionRate * 100).toInt()}%",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 2, 11, 63),
                    ),
                  ),
                  const SizedBox(height: 10),
                  QuoteWidget(
                    quote: quote,
                    author: author,
                    isLoading: isQuoteLoading,
                    onReload: _loadQuote,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: const Color.fromARGB(255, 236, 234, 234),
        unselectedItemColor: Colors.white,
        backgroundColor: const Color.fromARGB(255, 2, 11, 63),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Habits'),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Progress',
          ),
        ],
        onTap: (index) {
          if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => HabitList(userName: widget.userName),
              ),
            );
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => Progress(userName: widget.userName),
              ),
            );
          }
        },
      ),
    );
  }
}

class QuoteWidget extends StatelessWidget {
  final String quote;
  final String author;
  final bool isLoading;
  final VoidCallback onReload;

  const QuoteWidget({
    super.key,
    required this.quote,
    required this.author,
    required this.isLoading,
    required this.onReload,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Card(
        color: const Color.fromARGB(255, 2, 11, 63),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: isLoading
              ? const Column(
                  children: [
                    CircularProgressIndicator(
                      color: Color.fromARGB(255, 206, 206, 193),
                    ),
                    SizedBox(height: 8),
                  ],
                )
              : Column(
                  children: [
                    Text(
                      '"$quote"',
                      style: const TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        color: Color.fromARGB(255, 206, 206, 193),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '- $author',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 206, 206, 193),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.refresh,
                            size: 18,
                            color: Color.fromARGB(255, 206, 206, 193),
                          ),
                          onPressed: onReload,
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
