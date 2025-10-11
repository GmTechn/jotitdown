import 'package:flutter/material.dart';
import 'package:notesapp/management/notification_services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:notesapp/management/database.dart';
import 'package:notesapp/pages/dashboard.dart';
import 'package:notesapp/pages/login.dart';
import 'package:notesapp/pages/profile.dart';
import 'package:notesapp/pages/schedule.dart';
import 'package:notesapp/pages/signup.dart';
import 'package:notesapp/pages/tasks.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notifications
  await NotificationServices().initializeNotifications();

  // Database instance
  final dbManager = DatabaseManager();
  await dbManager.initialisation();

  //clear database
  //await dbManager.clearDatabase();

  // Check if user is logged in
  final prefs = await SharedPreferences.getInstance();
  final savedEmail = prefs.getString('loggedInEmail') ?? '';

  runApp(MyApp(initialEmail: savedEmail));
}

class MyApp extends StatelessWidget {
  final String initialEmail;
  const MyApp({super.key, required this.initialEmail});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'JotItDown',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // If a user is already logged in, show Dashboard, otherwise LoginPage
      home: initialEmail.isNotEmpty
          ? Dashboard(email: initialEmail)
          : LoginPage(email: ''),

      // Define routes for navigation
      onGenerateRoute: (settings) {
        final args = settings.arguments as Map<String, dynamic>?;

        switch (settings.name) {
          case '/signup':
            return MaterialPageRoute(builder: (_) => const SignUpPage());
          case '/dashboard':
            return MaterialPageRoute(
                builder: (_) =>
                    Dashboard(email: args?['email'] ?? initialEmail));
          case '/schedule':
            return MaterialPageRoute(
                builder: (_) =>
                    SchedulePage(email: args?['email'] ?? initialEmail));
          case '/taskspage':
            return MaterialPageRoute(
                builder: (_) =>
                    TasksPage(email: args?['email'] ?? initialEmail));
          case '/profile':
            return MaterialPageRoute(
                builder: (_) =>
                    ProfilePage(email: args?['email'] ?? initialEmail));
          default:
            return null;
        }
      },
    );
  }
}
