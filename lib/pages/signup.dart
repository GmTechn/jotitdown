import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:notesapp/components/mybutton.dart';
import 'package:notesapp/components/mytextfield.dart';
import 'package:notesapp/management/database.dart';
import 'package:notesapp/models/users.dart';
import 'package:notesapp/pages/dashboard.dart';
import 'package:google_fonts/google_fonts.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final fnameController = TextEditingController();
  final lnameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneController = TextEditingController();

  final DatabaseManager _dbManager = DatabaseManager();
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _dbManager.initialisation();
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> registerUser() async {
    final fname = fnameController.text.trim();
    final lname = lnameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final phone = phoneController.text.trim();

    if (fname.isEmpty || lname.isEmpty || email.isEmpty || password.isEmpty) {
      showMessage("Please fill in all required fields.");
      return;
    }

    if (!RegExp(r"^[\w\.-]+@[\w\.-]+\.\w+$").hasMatch(email)) {
      showMessage("Please enter a valid email address.");
      return;
    }

    try {
      final existingUser = await _dbManager.getUserByEmail(email);
      if (existingUser != null) {
        showMessage("An account with this email already exists.");
        return;
      }

      final newUser = AppUser(
        fname: fnameController.text.trim(),
        lname: lnameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        phone: phoneController.text.trim(),
        photoPath: '',
      );

      final db = DatabaseManager();
      await db.insertAppUser(newUser);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => Dashboard(email: newUser.email),
        ),
      );
    } catch (e) {
      showMessage("Registration failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
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
            const SizedBox(height: 20),
            const Text('Create your account here!',
                style: TextStyle(
                    color: Color(0xff050c20), fontWeight: FontWeight.normal)),
            const SizedBox(height: 40),
            Mytextfield(
                controller: fnameController,
                hintText: 'First Name',
                obscureText: false,
                leadingIcon:
                    const Icon(Icons.person, color: Color(0xff050c20))),
            const SizedBox(height: 10),
            Mytextfield(
                controller: lnameController,
                hintText: 'Last Name',
                obscureText: false,
                leadingIcon:
                    const Icon(Icons.person, color: Color(0xff050c20))),
            const SizedBox(height: 10),
            Mytextfield(
                controller: emailController,
                hintText: 'Email',
                obscureText: false,
                leadingIcon: const Icon(Icons.email, color: Color(0xff050c20))),
            const SizedBox(height: 10),
            Mytextfield(
              controller: passwordController,
              hintText: 'Password',
              obscureText: !_isPasswordVisible,
              leadingIcon: const Icon(Icons.lock, color: Color(0xff050c20)),
              trailingIcon: IconButton(
                icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: const Color(0xff050c20)),
                onPressed: () =>
                    setState(() => _isPasswordVisible = !_isPasswordVisible),
              ),
            ),
            const SizedBox(height: 10),
            Mytextfield(
              controller: phoneController,
              hintText: 'Phone (optional)',
              obscureText: false,
              leadingIcon: const Icon(Icons.phone, color: Color(0xff050c20)),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 40),
            MyButton(
                textbutton: 'Sign Up',
                onTap: registerUser,
                buttonHeight: 40,
                buttonWidth: 200),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Already have an account? ",
                    style: TextStyle(color: Color(0xff050c20))),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context); // or push to LoginPage if needed
                  },
                  child: const Text(
                    "Login",
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
