import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  await dbManager.initialisation();

//---check if the user is logged in

  final prefs = await SharedPreferences.getInstance();
  final savedEmail = prefs.getString('loggedInEmail');

  runApp(MyApp(initialEmail: savedEmail));
}

class MyApp extends StatelessWidget {
  final String? initialEmail;
  const MyApp({super.key, this.initialEmail});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Jot It Down',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: initialEmail == null ? '/' : '/dashboard',
      routes: {
        '/': (context) => const LoginPage(),
      },
      onGenerateRoute: (settings) {
        final args = settings.arguments as Map<String, dynamic>?;

        switch (settings.name) {
          case '/signup':
            return MaterialPageRoute(
              builder: (_) => const SignUpPage(),
            );
          case '/dashboard':
            return MaterialPageRoute(
              builder: (_) => Dashboard(
                email: args?['email'] ?? initialEmail ?? '',
              ),
            );
          case '/transactions':
            return MaterialPageRoute(
              builder: (_) => SchedulePage(
                email: args?['email'] ?? initialEmail ?? '',
              ),
            );
          case '/mycards':
            return MaterialPageRoute(
              builder: (_) => TasksPage(
                email: args?['email'] ?? initialEmail ?? '',
              ),
            );
          case '/profile':
            return MaterialPageRoute(
              builder: (_) => ProfilePage(
                email: args?['email'] ?? initialEmail ?? '',
              ),
            );
          default:
            return null;
        }
      },
    );
  }
}
