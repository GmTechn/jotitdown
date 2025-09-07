import 'dart:async';
import 'dart:io';
import 'package:notesapp/models/task.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:notesapp/models/users.dart';

class DatabaseManager {
  Database? _database;

//--- Initialising the database

  Future<Database> get database async {
    if (_database != null) return _database!;
    await initialisation();
    return _database!;
  }

//creating tables of users with their "profile details"
//meaning leur sign up info mais en rajoutant
//le imagePath pour sauvergarder la PP

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

        // create tasks table with their start and end time
        //qui permettront les calculs des status
        //"done", "in progress" etc...
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

      //when a task is upgraded, changes are applied to the database
      //and it generates a new task version

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

        //generates a table if none exists yet
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

  ///  Wipes the entire database for testing
  /// instead of creating several users
  /// can be commented out when app is ready for deployment "I guess"
  Future<void> clearDatabase() async {
    final path = join(await getDatabasesPath(), 'users_database.db');
    if (await File(path).exists()) {
      await deleteDatabase(path);
    }

    //forcing reinitialisation
    _database = null;
  }

  // ---------- Getting all appusers  ----------
  Future<List<AppUser>> getAllAppUsers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('users');
    return maps.map((map) => AppUser.fromMap(map)).toList();
  }
  //----Inseting a new user in the database

  Future<void> insertAppUser(AppUser user) async {
    final db = await database;
    await db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

//---Updating a user's info dans la database
  Future<void> updateAppUser(AppUser user) async {
    final db = await database;
    await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  ///deleting user dans la database

  Future<void> deleteAppUser(int id) async {
    final db = await database;
    await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  //getting user by email, useful to display their names
  //sur le dashboard ou les autres pages si necessary
  //also helps recollect corresponding tasks ans statuses

  Future<AppUser?> getUserByEmail(String email) async {
    final db = await database;
    final result =
        await db.query('users', where: 'email = ?', whereArgs: [email]);
    if (result.isNotEmpty) return AppUser.fromMap(result.first);
    return null;
  }

  // ---------- Generating Tasks  ----------

  /// Insert a task for a specific user via their email

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

  /// Get tasks for a specific user
  /// en ordre the stack newest first
  ///
  Future<List<Task>> getTasksForUser(String userEmail) async {
    final db = await database;
    final rows = await db.query(
      'tasks',
      where: 'userEmail = ?',
      whereArgs: [userEmail],
      orderBy: 'createdAt DESC',
    );

    ///Converting a Map to a Task object
    ///instrad of having a list of maps

    return rows.map((row) => Task.fromMap(row)).toList();
  }

  /// Delete a task by its id just like for a user
  ///
  Future<void> deleteTask(int id) async {
    final db = await database;
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  /// Update a task by it's id just like
  /// on fait avec les users
  ///
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
