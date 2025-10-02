import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notesapp/components/mybutton.dart';
import 'package:notesapp/components/mytextfield.dart';
import 'package:notesapp/management/database.dart';
import 'package:notesapp/models/users.dart';
import 'package:notesapp/pages/forgotpass.dart';
import 'package:notesapp/pages/login.dart';
import 'package:notesapp/pages/profile.dart';
import 'package:notesapp/pages/signup.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  //controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmpasswordController = TextEditingController();

//visibility for password
  bool _isPasswordVisible = false;

//database instance
  final DatabaseManager _dbManager = DatabaseManager();

//initialization of state
  @override
  void initState() {
    super.initState();
    _dbManager.initialisation();
  }

//error message

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

  //register user function

  Future<void> registerUser() async {
    final email = emailController.text.trim();
    var password = passwordController.text.trim();
    final confirmPassword = confirmpasswordController.text.trim();

    if (!RegExp(r"^[\w\.-]+@[\w\.-]+\.\w+$").hasMatch(email)) {
      showErrorMessage("Please enter a valid email address.");
      return;
    }

    if (confirmPassword != password) {
      showErrorMessage('Passwords do not match!');
      return;
    } else {
      password = confirmPassword;
    }

    try {
      final existingUser = await _dbManager.getUserByEmail(email);
      if (existingUser != null) {
        showErrorMessage("An account with this email already exists.");
        return;
      }

      final newUser = AppUser(
        fname: '',
        lname: '',
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        photoPath: '',
      );

      final db = DatabaseManager();
      await db.insertAppUser(newUser);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ProfilePage(email: newUser.email),
        ),
      );
    } catch (e) {
      showErrorMessage("Registration failed: $e");
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
                  Text('Create an account here!'),
                ],
              ),
              const SizedBox(height: 30),
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
                trailingIcon: IconButton(
                  icon: Icon(
                      _isPasswordVisible
                          ? CupertinoIcons.eye_fill
                          : CupertinoIcons.eye_slash_fill,
                      color: const Color(0xff050c20)),
                  onPressed: () =>
                      setState(() => _isPasswordVisible = !_isPasswordVisible),
                ),
              ),
              const SizedBox(height: 10),
              Mytextfield(
                controller: confirmpasswordController,
                hintText: 'Confirm Password',
                obscureText: !_isPasswordVisible,
                leadingIcon: const Icon(
                  CupertinoIcons.lock_fill,
                  color: Color(0xff050c20),
                ),
                trailingIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? CupertinoIcons.eye_fill
                        : CupertinoIcons.eye_slash_fill,
                    color: const Color(0xff050c20),
                  ),
                  onPressed: () =>
                      setState(() => _isPasswordVisible = !_isPasswordVisible),
                ),
              ),
              const SizedBox(height: 40),
              MyButton(
                textbutton: 'Sign Up',
                onTap: registerUser,
                buttonHeight: 40,
                buttonWidth: 200,
              ),
              const SizedBox(height: 80),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have an account?",
                      style: TextStyle(color: Color(0xff050c20))),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginPage()),
                    ),
                    child: const Text(
                      ' Login',
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
