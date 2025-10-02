import 'package:flutter/material.dart';
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
  //ensuring initialization
  WidgetsFlutterBinding.ensureInitialized();

//database instance
  final dbManager = DatabaseManager();

//notifications pluggin
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await dbManager.initialisation();

//---checkin if the user is logged in because we
//have saved their preferences

  final prefs = await SharedPreferences.getInstance();
  final savedEmail = prefs.getString('loggedInEmail');

  //initialization settings for android

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  // Initialization settings for iOS
  final DarwinInitializationSettings initializationSettingsDarwin =
      DarwinInitializationSettings();

  // Combine
  InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsDarwin,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  runApp(MyApp(initialEmail: savedEmail));
}

class MyApp extends StatelessWidget {
  final String? initialEmail;
  const MyApp({super.key, this.initialEmail});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'JotItDown',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),

      //initial route, first route to go to is login page

      initialRoute: initialEmail == null ? '/' : '/',
      routes: {
        '/': (context) => const LoginPage(),
      },
      onGenerateRoute: (settings) {
        //--- Generating routes to push the pages too
        //--- Different pages have different arguments that are being passed or not
        //---Sign up doesn't have any argument passed

        final args = settings.arguments as Map<String, dynamic>?;

        switch (settings.name) {
          case '/signup':
            return MaterialPageRoute(
              builder: (_) => const SignUpPage(),
            );

          //Dashboard gets the email argument from the signup page
          //because the name of the user has to be displayed
          //while they're being welcomed

          case '/dashboard':
            return MaterialPageRoute(
              builder: (_) => Dashboard(
                email: args?['email'] ?? initialEmail ?? '',
              ),
            );
          case '/schedule':
            return MaterialPageRoute(
              builder: (_) => SchedulePage(
                email: args?['email'] ?? initialEmail ?? '',
              ),
            );
          case '/taskspage':
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
