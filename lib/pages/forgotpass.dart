import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:notesapp/components/mybutton.dart';
import 'package:notesapp/components/mytextfield.dart';
import 'package:notesapp/management/database.dart';

class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
//---Generating a text editing cotroller to get the email

    final emailController = TextEditingController();
    //---Generating a database instance

    final DatabaseManager dbManager = DatabaseManager();

//---Generating the sendResetlink function
//will be updated later on with the actual email reset function
//only showing snackbar errors for now

    Future<void> _sendResetLink() async {
      final email = emailController.text.trim();

      if (email.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your email!')),
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reset link sent to $email')),
      );
    }

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
              'Enter your email to reset password:',
              style: TextStyle(color: Color(0xff050c20)),
            ),
            const SizedBox(height: 40),
            Mytextfield(
              controller: emailController,
              hintText: 'Email',
              obscureText: false,
              leadingIcon: const Icon(CupertinoIcons.envelope_fill),
            ),
            const SizedBox(height: 40),
            MyButton(
              textbutton: 'Send reset link',
              onTap: _sendResetLink,
              buttonHeight: 40,
              buttonWidth: 200,
            ),
          ],
        ),
      ),
    );
  }
}
