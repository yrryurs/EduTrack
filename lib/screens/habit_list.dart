import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import '../db_helper.dart';
import '../main.dart';
import '../notification_service.dart';
import 'add_habit.dart';
import 'homepage.dart';
import 'progress.dart';

class HabitList extends StatefulWidget {
  final String userName;
  HabitList({required this.userName});

  @override
  _HabitListState createState() => _HabitListState();
}

class _HabitListState extends State<HabitList> {
  List<Map<String, dynamic>> _habits = [];
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    NotificationService().init().then((_) async {
      if (Platform.isAndroid) {
        var status = await Permission.notification.status;
        print('Notification permission status: $status');
        if (!status.isGranted) {
          await Permission.notification.request();
        }
      }
      await _loadHabits();
    });
  }

  Future<void> _loadHabits() async {
    final allHabits = await DBHelper().getHabits();
    print("Total habits from DB: ${allHabits.length}");
    for (var h in allHabits) {
      print("Habit: ${h['id']} - ${h['name']}");
    }
    final filteredHabits = allHabits.where((habit) {
      String freq = habit['frequency'] ?? 'Everyday';
      if (freq == 'Everyday') return true;
      if (freq == 'Days') {
        String daysStr = habit['selectedDays'] ?? '';
        List<String> days = daysStr.split(',').map((e) => e.trim()).toList();
        String weekday = DateFormat('EEE').format(selectedDate);
        return days.contains(weekday);
      }
      if (freq == 'Date') {
        int? dayOfMonth = habit['dayOfMonth'];
        return dayOfMonth == selectedDate.day;
      }
      return false;
    }).toList();
    setState(() {
      _habits = filteredHabits;
    });
  }

  Future<void> scheduleTodayNotifications(DateTime date) async {
    final habits = await DBHelper().getHabits();
    final notif = NotificationService();
    int todayHabitCount = 0;
    for (var habit in habits) {
      String freq = habit['frequency'] ?? 'Everyday';
      bool shouldNotify = false;
      if (freq == 'Everyday') shouldNotify = true;
      if (freq == 'Days') {
        List<String> days = (habit['selectedDays'] ?? '')
            .split(',')
            .map((e) => e.trim())
            .toList();
        String weekday = DateFormat('EEE').format(date);
        if (days.contains(weekday)) shouldNotify = true;
      }
      if (freq == 'Date') {
        int? dayOfMonth = habit['dayOfMonth'];
        if (dayOfMonth == date.day) shouldNotify = true;
      }
      if (shouldNotify) todayHabitCount++;
    }
    const int dailyNotificationId = 999;
    await notif.cancelNotification(dailyNotificationId);
    if (todayHabitCount == 0) return;
    DateTime now = DateTime.now();
    DateTime scheduledTime = DateTime(now.year, now.month, now.day, 10, 0);
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(Duration(days: 1));
    }
    await notif.scheduleNotification(
      id: dailyNotificationId,
      title: "Habit Reminder",
      body: todayHabitCount == 1
          ? "You have 1 habit to complete today !"
          : "You have $todayHabitCount habits to complete today !",
      scheduledDate: scheduledTime,
    );
  }

  Map<String, List<Map<String, dynamic>>> _groupByCategory() {
    Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var h in _habits) {
      String category = h['category'] ?? 'Other';
      grouped.putIfAbsent(category, () => []);
      grouped[category]!.add(h);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat(
      'EEEE (d MMMM yyyy)',
    ).format(selectedDate);
    final groupedHabits = _groupByCategory();
    return Scaffold(
      appBar: myAppBar("${widget.userName}'s Habit"),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/bg.png'),
                repeat: ImageRepeat.repeat,
                fit: BoxFit.none,
                colorFilter: ColorFilter.mode(
                  Color.fromARGB(255, 129, 129, 109).withOpacity(0.48),
                  BlendMode.dstATop,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Center(
                    child: Card(
                      color: Color.fromARGB(255, 2, 11, 63),
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              formattedDate,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(255, 206, 206, 193),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.calendar_today,
                                color: Colors.white,
                              ),
                              onPressed: () async {
                                DateTime? picked = await showDatePicker(
                                  context: context,
                                  initialDate: selectedDate,
                                  firstDate: DateTime(2023),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null) {
                                  setState(() {
                                    selectedDate = picked;
                                  });
                                  _loadHabits();
                                  scheduleTodayNotifications(selectedDate);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _habits.isEmpty
                      ? Center(child: Text("No habits for this day."))
                      : ListView(
                          children: groupedHabits.entries.map((entry) {
                            final category = entry.key;
                            final habitsInCategory = entry.value;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  child: Text(
                                    category,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                ...habitsInCategory.map((habit) {
                                  return Card(
                                    color: Colors.white.withOpacity(0.6),
                                    margin: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 6,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 12,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  habit['name'],
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                if ((habit['description'] ?? '')
                                                    .isNotEmpty)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          top: 2.0,
                                                        ),
                                                    child: Text(
                                                      habit['description'],
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.grey[800],
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              FutureBuilder<bool>(
                                                future: DBHelper()
                                                    .isHabitCompletedOnDate(
                                                      habit['id'],
                                                      selectedDate,
                                                    ),
                                                builder: (context, snapshot) {
                                                  bool completed =
                                                      snapshot.data ?? false;
                                                  return Checkbox(
                                                    activeColor: Colors.green,
                                                    value: completed,
                                                    onChanged: (val) async {
                                                      await DBHelper()
                                                          .toggleHabitCompletionOnDate(
                                                            habit['id'],
                                                            selectedDate,
                                                          );
                                                      if (val == true) {
                                                        await HapticFeedback.mediumImpact();
                                                        _showMoodDialog(
                                                          habit['id'],
                                                        );
                                                      }
                                                      setState(() {});
                                                    },
                                                  );
                                                },
                                              ),
                                              IconButton(
                                                icon: Icon(
                                                  Icons.edit,
                                                  size: 20,
                                                ),
                                                onPressed: () async {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          AddHabit(
                                                            existingHabit:
                                                                habit,
                                                          ),
                                                    ),
                                                  ).then((_) async {
                                                    await _loadHabits();
                                                    await scheduleTodayNotifications(
                                                      selectedDate,
                                                    );
                                                  });
                                                },
                                              ),
                                              IconButton(
                                                icon: Icon(
                                                  Icons.delete,
                                                  size: 20,
                                                ),
                                                onPressed: () async {
                                                  bool confirm =
                                                      await _showDeleteConfirmation();
                                                  if (confirm) {
                                                    await DBHelper()
                                                        .deleteHabit(
                                                          habit['id'],
                                                        );
                                                    _loadHabits();
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ],
                            );
                          }).toList(),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Color.fromARGB(255, 2, 11, 63),
        foregroundColor: Color.fromARGB(255, 206, 206, 193),
        child: Icon(Icons.add),
        onPressed: () async {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddHabit()),
          ).then((_) async {
            await _loadHabits();
            await scheduleTodayNotifications(selectedDate);
          });
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        selectedItemColor: Color.fromARGB(255, 236, 234, 234),
        unselectedItemColor: Colors.white,
        backgroundColor: Color.fromARGB(255, 2, 11, 63),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Habits'),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Progress',
          ),
        ],
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => HomePage(userName: widget.userName),
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

  void _showMoodDialog(int habitId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("How do you feel?"),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _moodEmoji("😊", habitId),
            _moodEmoji("😐", habitId),
            _moodEmoji("😔", habitId),
          ],
        ),
      ),
    );
  }

  Widget _moodEmoji(String emoji, int habitId) {
    return GestureDetector(
      onTap: () async {
        String today = selectedDate.toIso8601String().substring(0, 10);
        await DBHelper().insertMood(habitId, today, emoji);
        Navigator.pop(context);
      },
      child: Text(emoji, style: TextStyle(fontSize: 30)),
    );
  }

  Future<bool> _showDeleteConfirmation() async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("Delete Habit"),
            content: Text("Are you sure you want to delete this habit?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text("Delete"),
              ),
            ],
          ),
        ) ??
        false;
  }
}
