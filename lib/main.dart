import 'package:flutter/material.dart';
import 'package:notesapp/management/database.dart';
import 'package:notesapp/pages/dashboard.dart';
import 'package:notesapp/pages/login.dart';
import 'package:notesapp/pages/profile.dart';
import 'package:notesapp/pages/schedule.dart';
import 'package:notesapp/pages/signup.dart';
import 'package:notesapp/pages/tasks.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dbManager = DatabaseManager();

  // ✅ Clear database during testing

  await dbManager.clearDatabase();

  await dbManager.initialisation();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Jot It Down',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginPage(),
        // You can handle navigation with email using onGenerateRoute
      },
      onGenerateRoute: (settings) {
        final args = settings.arguments as Map<String, dynamic>?;

        switch (settings.name) {
          case '/signup':
            return MaterialPageRoute(
              builder: (_) => SignUpPage(),
            );
          case '/dashboard':
            return MaterialPageRoute(
              builder: (_) => Dashboard(
                email: args?['email'] ?? '',
              ),
            );

          case '/transactions':
            return MaterialPageRoute(
              builder: (_) => SchedulePage(
                email: args?['email'] ?? '',
              ),
            );
          case '/mycards':
            return MaterialPageRoute(
              builder: (_) => TasksPage(
                email: args?['email'] ?? '',
              ),
            );
          case '/profile':
            return MaterialPageRoute(
              builder: (_) => ProfilePage(
                email: args?['email'],
              ),
            );

          default:
            return null;
        }
      },
    );
  }
}
