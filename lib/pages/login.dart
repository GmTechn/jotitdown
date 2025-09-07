import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notesapp/components/mybutton.dart';
import 'package:notesapp/components/mytextfield.dart';
import 'package:notesapp/management/database.dart';
import 'package:notesapp/pages/forgotpass.dart';
import 'package:notesapp/pages/signup.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  final DatabaseManager _dbManager = DatabaseManager();

  void showErrorMessage(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        content: Text(
          message,
          style: const TextStyle(color: Color(0xff050c20)),
        ),
      ),
    );
  }

  Future<void> loginUser() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showErrorMessage("Please fill all fields.");
      return;
    }

    if (!RegExp(r"^[\w\.-]+@[\w\.-]+\.\w+$").hasMatch(email)) {
      showErrorMessage("Please enter a valid email address.");
      return;
    }

    try {
      final user = await _dbManager.getUserByEmail(email);

      if (user == null) {
        showErrorMessage("No account found with this email.");
        return;
      }

      if (user.password != password) {
        showErrorMessage("Incorrect password. Please try again.");
        return;
      }

      // Sauvegarde l'email dans SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('loggedInEmail', email);

      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        '/dashboard',
        arguments: {'email': email},
      );
    } catch (e) {
      showErrorMessage("Login failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              top: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 50),
              const Icon(
                CupertinoIcons.book_fill,
                color: Color(0xff050c20),
                size: 60,
              ),
              const SizedBox(height: 20),
              Text(
                'J O T   I T   D O W N!',
                style: GoogleFonts.abel(
                  fontWeight: FontWeight.bold,
                  fontSize: 40,
                ),
              ),
              const SizedBox(height: 10),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Welcome back!'),
                ],
              ),
              const SizedBox(height: 60),
              Mytextfield(
                controller: emailController,
                hintText: 'Email',
                obscureText: false,
                leadingIcon: const Icon(
                  CupertinoIcons.envelope_fill,
                  color: Color(0xff050c20),
                ),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 20),
              Mytextfield(
                controller: passwordController,
                hintText: 'Password',
                obscureText: !_isPasswordVisible,
                leadingIcon: const Icon(CupertinoIcons.lock_fill,
                    color: Color(0xff050c20)),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                    icon: Icon(
                      _isPasswordVisible
                          ? CupertinoIcons.eye_fill
                          : CupertinoIcons.eye_slash_fill,
                      color: const Color(0xff050c20),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ForgotPasswordPage(),
                        ),
                      );
                    },
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: Color(0xff050c20),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              MyButton(
                textbutton: 'Login',
                onTap: loginUser,
                buttonHeight: 40,
                buttonWidth: 200,
              ),
              const SizedBox(height: 80),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account?",
                      style: TextStyle(color: Color(0xff050c20))),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SignUpPage()),
                    ),
                    child: const Text(
                      ' Sign up',
                      style: TextStyle(
                          color: Colors.blue, fontWeight: FontWeight.bold),
                    ),
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
