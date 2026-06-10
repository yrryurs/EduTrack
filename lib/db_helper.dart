import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();
  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'edutrack.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: (db, oldVersion, newVersion) async {
        await db.execute("DROP TABLE IF EXISTS user");
        await db.execute("DROP TABLE IF EXISTS habits");
        await db.execute("DROP TABLE IF EXISTS habit_logs");
        await db.execute("DROP TABLE IF EXISTS mood");
        await _onCreate(db, newVersion);
      },
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE user (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        createdAt TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE habits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        description TEXT,
        category TEXT,
        frequency TEXT,
        selectedDays TEXT,
        dayOfMonth INTEGER,
        isCompleted INTEGER,
        createdAt TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE habit_logs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        habitId INTEGER,
        date TEXT,
        isCompleted INTEGER,
        FOREIGN KEY (habitId) REFERENCES habits(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE mood (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        habitId INTEGER,
        date TEXT,
        mood TEXT
      )
    ''');
  }

  Future<int> insertUser(String name) async {
    final db = await database;
    return await db.insert('user', {
      'name': name,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<String?> getUserName() async {
    final db = await database;
    final result = await db.query('user', limit: 1);
    if (result.isNotEmpty) return result.first['name'] as String;
    return null;
  }

  Future<int> insertHabit(Map<String, dynamic> habit) async {
    final db = await database;
    habit['createdAt'] = DateTime.now().toIso8601String();
    habit['isCompleted'] = 0;
    return await db.insert('habits', habit);
  }

  Future<List<Map<String, dynamic>>> getHabits() async {
    final db = await database;
    return await db.query('habits');
  }

  Future<int> updateHabit(int id, Map<String, dynamic> habit) async {
    final db = await database;
    habit.remove('isCompleted');
    habit.remove('createdAt');
    return await db.update('habits', habit, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteHabit(int id) async {
    final db = await database;
    return await db.delete('habits', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> toggleHabitCompletionOnDate(int habitId, DateTime date) async {
    final db = await database;
    String day = date.toIso8601String().substring(0, 10);
    final existing = await db.query(
      'habit_logs',
      where: 'habitId = ? AND date = ?',
      whereArgs: [habitId, day],
    );
    if (existing.isEmpty) {
      await db.insert('habit_logs', {
        'habitId': habitId,
        'date': day,
        'isCompleted': 1,
      });
    } else {
      int current = existing.first['isCompleted'] as int;
      int newValue = current == 1 ? 0 : 1;
      await db.update(
        'habit_logs',
        {'isCompleted': newValue},
        where: 'habitId = ? AND date = ?',
        whereArgs: [habitId, day],
      );
      if (newValue == 0) {
        await db.delete(
          'mood',
          where: 'habitId = ? AND date = ?',
          whereArgs: [habitId, day],
        );
      }
    }
  }

  Future<bool> isHabitCompletedOnDate(int habitId, DateTime date) async {
    final db = await database;
    String day = date.toIso8601String().substring(0, 10);
    final result = await db.query(
      'habit_logs',
      where: 'habitId = ? AND date = ?',
      whereArgs: [habitId, day],
    );
    if (result.isEmpty) return false;
    return result.first['isCompleted'] == 1;
  }

  Future<List<Map<String, dynamic>>> getHabitLogs(int habitId) async {
    final db = await database;
    return await db.query(
      'habit_logs',
      where: 'habitId = ?',
      whereArgs: [habitId],
    );
  }

  Future<List<Map<String, dynamic>>> getAllHabitLogs() async {
    final db = await database;
    return await db.query('habit_logs');
  }

  Future<List<Map<String, dynamic>>> getHabitLogsByDate(String date) async {
    final db = await database;
    return await db.query('habit_logs', where: 'date = ?', whereArgs: [date]);
  }

  Future<int> getCompletionRateThisWeek() async {
    final db = await database;
    final today = DateTime.now();
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final endOfWeek = startOfWeek.add(Duration(days: 6));
    final habits = await db.query('habits');
    final logs = await getHabitLogsInWeek(startOfWeek, endOfWeek);
    if (habits.isEmpty) return 0;
    int completed = logs.where((log) => log['isCompleted'] == 1).length;
    return completed;
  }

  Future<List<Map<String, dynamic>>> getHabitLogsInWeek(
    DateTime start,
    DateTime end,
  ) async {
    final db = await database;
    String startStr = start.toIso8601String().substring(0, 10);
    String endStr = end.toIso8601String().substring(0, 10);
    return await db.query(
      'habit_logs',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [startStr, endStr],
    );
  }

  Future<int> insertMood(int habitId, String date, String mood) async {
    final db = await database;
    return await db.insert('mood', {
      'habitId': habitId,
      'date': date,
      'mood': mood,
    });
  }

  Future<List<Map<String, dynamic>>> getMoodByDate(String date) async {
    final db = await database;
    return await db.query('mood', where: 'date = ?', whereArgs: [date]);
  }

  Future<List<Map<String, dynamic>>> getMoodLogsInMonth(
    int year,
    int month,
  ) async {
    final db = await database;
    String monthStr = month.toString().padLeft(2, '0');
    String likePattern = '$year-$monthStr-%';
    return await db.query(
      'mood',
      where: 'date LIKE ?',
      whereArgs: [likePattern],
    );
  }
}
