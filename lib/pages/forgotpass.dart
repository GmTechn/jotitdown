import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:notesapp/components/mybutton.dart';
import 'package:notesapp/components/mytextfield.dart';
import 'package:notesapp/management/database.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final emailController = TextEditingController();
  final newPasswordController = TextEditingController();
  final DatabaseManager dbManager = DatabaseManager();

  bool _obscurePassword = true;

  Future<void> _resetPassword() async {
    final email = emailController.text.trim();
    final newPassword = newPasswordController.text.trim();

    if (email.isEmpty || newPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields!')),
      );
      return;
    }

    final user = await dbManager.getUserByEmail(email);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No account found with this email!')),
      );
      return;
    }

    if (user.password == newPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Your new password cannot be the same as your old password!',
          ),
        ),
      );
      return;
    }

    await dbManager.updatePassword(email, newPassword);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password successfully updated!')),
    );

    // Wait 2 seconds, then return to login
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'R E S E T',
          style: TextStyle(color: Color(0xff050c20)),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 40),
            const Icon(CupertinoIcons.lock_fill, size: 40),
            const SizedBox(height: 20),
            const Text(
              'Enter your email and new password:',
              style: TextStyle(color: Color(0xff050c20)),
            ),
            const SizedBox(height: 40),
            Mytextfield(
              controller: emailController,
              hintText: 'Email',
              obscureText: false,
              leadingIcon: const Icon(
                CupertinoIcons.envelope_fill,
                color: const Color(0xff050c20),
              ),
            ),
            const SizedBox(height: 20),

            // Password field with toggle
            Mytextfield(
              controller: newPasswordController,
              hintText: 'New Password',
              obscureText: _obscurePassword,
              leadingIcon: const Icon(CupertinoIcons.lock_fill,
                  color: Color(0xff050c20)),
              trailingIcon: GestureDetector(
                onTap: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
                child: Icon(
                  _obscurePassword
                      ? CupertinoIcons.eye_slash_fill
                      : CupertinoIcons.eye_fill,
                  color: const Color(0xff050c20),
                ),
              ),
            ),

            const SizedBox(height: 40),
            MyButton(
              textbutton: 'Reset Password',
              onTap: _resetPassword,
              buttonHeight: 40,
              buttonWidth: 200,
            ),
          ],
        ),
      ),
    );
  }
}
