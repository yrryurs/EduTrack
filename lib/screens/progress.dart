import 'package:flutter/material.dart';
import '../db_helper.dart';
import 'homepage.dart';
import 'habit_list.dart';
import '../main.dart';
import 'package:intl/intl.dart';

class Progress extends StatefulWidget {
  final String userName;
  const Progress({required this.userName});

  @override
  State<Progress> createState() => _ProgressState();
}

class _ProgressState extends State<Progress> {
  DateTime selectedMonth = DateTime.now();
  List<Map<String, dynamic>> _moodLogs = [];
  int currentStreak = 0;
  int bestStreak = 0;
  int todayFinished = 0;
  int habitFinished = 0;
  int totalHabits = 0;
  final Color textColor = const Color.fromARGB(255, 206, 206, 193);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
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

    totalHabits = activeHabits.length;
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    final habitLogsWeek = await db.getHabitLogsInWeek(startOfWeek, endOfWeek);
    String todayStr =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    todayFinished = habitLogsWeek
        .where((log) => log['isCompleted'] == 1 && log['date'] == todayStr)
        .length;

    habitFinished = habitLogsWeek
        .where((log) => log['isCompleted'] == 1)
        .length;

    final allLogs = await db.getAllHabitLogs();
    Set<String> completedDays = {};
    for (var log in allLogs) {
      if (log['isCompleted'] == 1) {
        completedDays.add(log['date']);
      }
    }

    currentStreak = 0;
    DateTime checkDate = today;
    while (true) {
      String formatted =
          "${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}";
      if (completedDays.contains(formatted)) {
        currentStreak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    bestStreak = 0;
    int tempStreak = 0;
    List<String> sortedDays = completedDays.toList()..sort();
    for (int i = 0; i < sortedDays.length; i++) {
      if (i == 0) {
        tempStreak = 1;
      } else {
        DateTime prev = DateTime.parse(sortedDays[i - 1]);
        DateTime curr = DateTime.parse(sortedDays[i]);
        if (curr.difference(prev).inDays == 1) {
          tempStreak++;
        } else {
          tempStreak = 1;
        }
      }
      if (tempStreak > bestStreak) bestStreak = tempStreak;
    }

    final moodLogs = await db.getMoodLogsInMonth(
      selectedMonth.year,
      selectedMonth.month,
    );

    Map<String, Map<String, dynamic>> latestMood = {};
    for (var log in moodLogs) {
      latestMood[log['date']] = log;
    }

    setState(() {
      _moodLogs = latestMood.values.toList();
    });
  }

  String monthName(int month) {
    const months = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    double completionRate = totalHabits == 0
        ? 0
        : (todayFinished / totalHabits) * 100;
    int daysInMonth = DateTime(
      selectedMonth.year,
      selectedMonth.month + 1,
      0,
    ).day;

    return Scaffold(
      appBar: myAppBar('${widget.userName}\'s Progress'),
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
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: statCard(
                        "CURRENT\nSTREAK",
                        "$currentStreak",
                        "Best: $bestStreak",
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: statCard(
                        "HABIT\nFINISHED",
                        "$habitFinished",
                        "This week",
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: statCard(
                        "COMPLETE\nRATE",
                        "${completionRate.toInt()}%",
                        "$todayFinished/$totalHabits",
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(
                      255,
                      2,
                      11,
                      63,
                    ).withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "Mood Calendar",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "${monthName(selectedMonth.month)} ${selectedMonth.year}",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(width: 10),
                          DropdownButton<int>(
                            value: selectedMonth.month,
                            dropdownColor: const Color.fromARGB(255, 2, 11, 63),
                            items: List.generate(12, (i) => i + 1)
                                .map(
                                  (m) => DropdownMenuItem(
                                    value: m,
                                    child: Text(
                                      monthName(m),
                                      style: TextStyle(color: textColor),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (m) async {
                              if (m == null) return;
                              setState(() {
                                selectedMonth = DateTime(selectedMonth.year, m);
                              });
                              await _loadData();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: daysInMonth,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 7,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                            ),
                        itemBuilder: (context, index) {
                          int day = index + 1;
                          String dateStr =
                              "${selectedMonth.year}-${selectedMonth.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}";
                          var moodEntry = _moodLogs.firstWhere(
                            (e) => e['date'] == dateStr,
                            orElse: () => {},
                          );
                          bool hasMood = moodEntry.containsKey('mood');
                          return Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: hasMood
                                  ? const Color.fromARGB(255, 109, 131, 150)
                                  : textColor.withOpacity(0.8),
                            ),
                            alignment: Alignment.center,
                            child: hasMood
                                ? Text(
                                    moodEntry['mood'].toString(),
                                    style: const TextStyle(fontSize: 18),
                                  )
                                : Text(
                                    "$day",
                                    style: const TextStyle(color: Colors.black),
                                  ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                Card(
                  color: const Color.fromARGB(255, 2, 11, 63),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        "Congratulations ${widget.userName},\nkeep it up!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        selectedItemColor: const Color.fromARGB(255, 236, 234, 234),
        unselectedItemColor: Colors.white,
        backgroundColor: const Color.fromARGB(255, 2, 11, 63),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: "Habits"),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: "Progress",
          ),
        ],
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => HomePage(userName: widget.userName),
              ),
            );
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => HabitList(userName: widget.userName),
              ),
            );
          }
        },
      ),
    );
  }

  Widget statCard(String title, String value, String subtitle) {
    return Card(
      color: const Color.fromARGB(255, 2, 11, 63),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(subtitle, style: TextStyle(color: textColor)),
          ],
        ),
      ),
    );
  }
}
