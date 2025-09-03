// ==============================
// dashboard.dart
// ==============================
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:notesapp/components/mybutton.dart';
import 'package:notesapp/components/mynavbar.dart';
import 'package:notesapp/management/database.dart';
import 'package:notesapp/management/listofusers.dart';
import 'package:notesapp/models/users.dart';
import 'package:notesapp/pages/login.dart';
import 'package:notesapp/pages/profile.dart';

class Dashboard extends StatefulWidget {
  final String email; // keep the email passed from signup

  const Dashboard({
    super.key,
    required this.email,
  });

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final DatabaseManager _databaseManager = DatabaseManager();
  AppUser? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    await _databaseManager.initialisation();
    final user = await _databaseManager.getUserByEmail(widget.email);
    setState(() {
      _currentUser = user;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Keep your structure; style the body to feel like the screenshot
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          ),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text(
          'D A S H B O A R D',
          style: TextStyle(color: Color(0xff050c20)),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfilePage(email: widget.email),
                ),
              );
            },
            icon: FutureBuilder<AppUser?>(
              future: _databaseManager.getUserByEmail(widget.email),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                }
                final path = snapshot.data?.photoPath ?? '';
                if (path.isNotEmpty) {
                  final file = File(path);
                  if (file.existsSync()) {
                    return CircleAvatar(
                      radius: 18,
                      backgroundImage: FileImage(file),
                    );
                  }
                }
                // Default icon if no photo
                return const Icon(
                  CupertinoIcons.person,
                  color: Colors.white,
                );
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header (welcome) — light, rounded look like the screenshot
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.white,
                      backgroundImage:
                          (_currentUser?.photoPath ?? '').isNotEmpty &&
                                  File(_currentUser!.photoPath!).existsSync()
                              ? FileImage(File(_currentUser!.photoPath!))
                              : null,
                      child: (_currentUser?.photoPath ?? '').isEmpty
                          ? const Icon(CupertinoIcons.person,
                              color: Color(0xff050c20))
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Welcome back,',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xff050c20))),
                          const SizedBox(height: 4),
                          Text(
                            _currentUser != null
                                ? "${_currentUser!.fname} ${_currentUser!.lname}"
                                : "Guest",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xff050c20),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Stack(
                      children: [
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(
                            CupertinoIcons.bell,
                            size: 28,
                            color: Color(0xff050c20),
                          ),
                        ),
                        Positioned(
                          right: 8,
                          top: 6,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Text(
                              '7',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Quick summary tiles (subtle, rounded)
              Row(
                children: [
                  _StatTile(
                    icon: CupertinoIcons.book,
                    label: 'Notes',
                    value: '24',
                  ),
                  const SizedBox(width: 12),
                  _StatTile(
                    icon: CupertinoIcons.checkmark_seal,
                    label: 'Tasks',
                    value: '8',
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // A simple “Today” card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Today',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xff050c20),
                        )),
                    SizedBox(height: 8),
                    Text(
                      'Keep up the streak! You’ve completed 3 items.',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // >>> Users button (kept at the VERY bottom of the column)
              Center(
                child: MyButton(
                  textbutton: 'Users',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ListOfUsers()),
                    ).then((_) => _loadUser());
                  },
                  buttonHeight: 40,
                  buttonWidth: 80,
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: MyNavBar(
        currentIndex: 0,
        email: widget.email,
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 82,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(10),
              child: Icon(icon, color: const Color(0xff050c20)),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: Colors.black54, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                Text(value,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            )
          ],
        ),
      ),
    );
  }
}
