import 'dart:async';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:notesapp/models/users.dart';

class DatabaseManager {
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    await initialisation();
    return _database!;
  }

  Future<void> initialisation() async {
    _database = await openDatabase(
      join(await getDatabasesPath(), 'users_database.db'),
      version: 2, // keep your version
      onCreate: (db, version) async {
        // create users table
        await db.execute(
          '''CREATE TABLE IF NOT EXISTS users(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            fname TEXT,
            lname TEXT,
            email TEXT UNIQUE,
            password TEXT,
            phone TEXT,
            photoPath TEXT
          )''',
        );

        // create tasks table
        await db.execute(
          '''CREATE TABLE IF NOT EXISTS tasks(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userEmail TEXT,
        status TEXT,
        title TEXT,
        subtitle TEXT,
        date TEXT,
        startTime TEXT,   
        endTime TEXT,    
        createdAt TEXT
  )''',
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // ensure tables exist after upgrades
        await db.execute(
          '''CREATE TABLE IF NOT EXISTS users(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            fname TEXT,
            lname TEXT,
            email TEXT UNIQUE,
            password TEXT,
            phone TEXT,
            photoPath TEXT
          )''',
        );
        await db.execute(
          '''CREATE TABLE IF NOT EXISTS tasks(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          userEmail TEXT,
          status TEXT,
          title TEXT,
          subtitle TEXT,
          date TEXT,
          startTime TEXT,   
          endTime TEXT,    
          createdAt TEXT
        )''',
        );
      },
    );
  }

  /// ✅ Wipes the entire database (useful for testing)
  Future<void> clearDatabase() async {
    final path = join(await getDatabasesPath(), 'users_database.db');
    if (await File(path).exists()) {
      await deleteDatabase(path);
    }
    _database = null; // force re-init on next call
  }

  // ---------- Users (unchanged) ----------
  Future<List<AppUser>> getAllAppUsers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('users');
    return maps.map((map) => AppUser.fromMap(map)).toList();
  }

  Future<void> insertAppUser(AppUser user) async {
    final db = await database;
    await db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateAppUser(AppUser user) async {
    final db = await database;
    await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<void> deleteAppUser(int id) async {
    final db = await database;
    await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  Future<AppUser?> getUserByEmail(String email) async {
    final db = await database;
    final result =
        await db.query('users', where: 'email = ?', whereArgs: [email]);
    if (result.isNotEmpty) return AppUser.fromMap(result.first);
    return null;
  }

  // ---------- Tasks (NEW) ----------

  /// Insert a task for a specific user. Returns inserted row id.
  Future<int> insertTask({
    required String userEmail,
    required String status,
    required String title,
    required String subtitle,
    required DateTime date,
    String? startTime, // 🆕
    String? endTime, // 🆕
  }) async {
    final db = await database;
    final id = await db.insert(
      'tasks',
      {
        'userEmail': userEmail,
        'status': status,
        'title': title,
        'subtitle': subtitle,
        'date': date.toIso8601String(),
        'startTime': startTime,
        'endTime': endTime,
        'createdAt': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return id;
  }

  /// Get tasks for a specific user (ordered newest first)
  Future<List<Map<String, dynamic>>> getTasksForUser(String userEmail) async {
    final db = await database;
    final rows = await db.query(
      'tasks',
      where: 'userEmail = ?',
      whereArgs: [userEmail],
      orderBy: 'createdAt DESC',
    );
    return rows;
  }

  /// Delete a task by id
  Future<void> deleteTask(int id) async {
    final db = await database;
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  /// Update a task (you can pass a map prepared by calling toMap-like structure)
  Future<void> updateTask({
    required int id,
    required String status,
    required String title,
    required String subtitle,
    required DateTime date,
    String? startTime,
    String? endTime,
  }) async {
    final db = await database;
    await db.update(
      'tasks',
      {
        'status': status,
        'title': title,
        'subtitle': subtitle,
        'date': date.toIso8601String(),
        'startTime': startTime,
        'endTime': endTime,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
