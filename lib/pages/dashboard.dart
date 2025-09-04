import 'dart:io';

import 'package:flutter/cupertino.dart';

import 'package:flutter/material.dart';

import 'package:notesapp/components/mybutton.dart';
import 'package:notesapp/components/mynavbar.dart';

import 'package:notesapp/management/database.dart';
import 'package:notesapp/management/listofusers.dart';

import 'package:notesapp/models/users.dart';
import 'package:notesapp/models/task.dart';

import 'package:notesapp/pages/profile.dart';

class Dashboard extends StatefulWidget {
  final String email;

  const Dashboard({super.key, required this.email});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final DatabaseManager _databaseManager = DatabaseManager();
  AppUser? _currentUser;

  int overdueCount = 0;
  int totalTasks = 0;
  int completedToday = 0;
  Task? nextTask;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadTasks();
  }

  Future<void> _loadUser() async {
    await _databaseManager.initialisation();
    final user = await _databaseManager.getUserByEmail(widget.email);
    setState(() {
      _currentUser = user;
    });
  }

  Future<void> _loadTasks() async {
    await _databaseManager.initialisation();
    final tasks = await _databaseManager.getTasksForUser(widget.email);

    final now = DateTime.now();

    int overdue = 0;
    int completed = 0;
    Task? next;

    for (var task in tasks) {
      final dueDate = task.date;
      final isDone = task.status.toLowerCase() == "done";

      if (!isDone && dueDate.isBefore(now)) {
        overdue++;
      }

      if (isDone &&
          dueDate.year == now.year &&
          dueDate.month == now.month &&
          dueDate.day == now.day) {
        completed++;
      }

      if (!isDone && dueDate.isAfter(now)) {
        if (next == null || dueDate.isBefore(next.date)) {
          next = task;
        }
      }
    }

    setState(() {
      overdueCount = overdue;
      totalTasks = tasks.length;
      completedToday = completed;
      nextTask = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'D A S H B O A R D',
          style: TextStyle(color: Color(0xff050c20)),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadTasks,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HEADER
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    ProfilePage(email: widget.email)),
                          ).then((_) => _loadUser());
                        },
                        child: CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.white,
                          backgroundImage: (_currentUser?.photoPath ?? '')
                                      .isNotEmpty &&
                                  File(_currentUser!.photoPath!).existsSync()
                              ? FileImage(File(_currentUser!.photoPath!))
                              : null,
                          child: (_currentUser?.photoPath ?? '').isEmpty
                              ? const Icon(CupertinoIcons.person,
                                  color: Color(0xff050c20))
                              : null,
                        ),
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
                          if (overdueCount > 0)
                            Positioned(
                              right: 8,
                              top: 6,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '$overdueCount',
                                  style: const TextStyle(
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

                // STATS
                Row(
                  children: [
                    _StatTile(
                      icon: CupertinoIcons.book,
                      label: 'Notes',
                      value: '$totalTasks',
                    ),
                    const SizedBox(width: 12),
                    _StatTile(
                      icon: CupertinoIcons.checkmark_seal,
                      label: 'Tasks',
                      value: '$completedToday',
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // TODAY CARD
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Today',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xff050c20),
                          )),
                      const SizedBox(height: 8),
                      Text(
                        "Keep up the streak! You’ve completed $completedToday items today.",
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // ALERT CARD
                if (overdueCount > 0)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      "⚠️ You have $overdueCount overdue tasks. Please review them!",
                      style: const TextStyle(
                          color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ),

                const SizedBox(height: 18),

                // NEXT TASK CARD
                if (nextTask != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Next Task",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xff050c20))),
                        const SizedBox(height: 8),
                        Text(nextTask!.title,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                        Text(
                          "Due: ${nextTask!.date}",
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 28),

                Center(
                  child: MyButton(
                    textbutton: 'Users',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ListOfUsers()),
                      ).then((_) {
                        _loadUser();
                        _loadTasks();
                      });
                    },
                    buttonHeight: 40,
                    buttonWidth: 80,
                  ),
                ),
              ],
            ),
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
