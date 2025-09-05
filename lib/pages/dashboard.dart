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
import 'package:notesapp/pages/schedule.dart';
import 'package:notesapp/pages/tasks.dart';
import 'package:intl/intl.dart';

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

  List<_TaskStatusItem> todayTasks = [];

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadTasks();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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
    List<_TaskStatusItem> computed = [];

    for (var task in tasks) {
      final taskDate = task.date;
      final isDone = task.status.toLowerCase() == "done";

      // only today's tasks
      if (taskDate.year == now.year &&
          taskDate.month == now.month &&
          taskDate.day == now.day) {
        if (isDone) {
          completed++;
          continue;
        }

        DateTime? start;
        DateTime? end;

        try {
          if (task.startTime != null && task.startTime!.isNotEmpty) {
            final parsed = DateFormat.jm().parse(task.startTime!);
            start = DateTime(
                now.year, now.month, now.day, parsed.hour, parsed.minute);
          }
          if (task.endTime != null && task.endTime!.isNotEmpty) {
            final parsed = DateFormat.jm().parse(task.endTime!);
            end = DateTime(
                now.year, now.month, now.day, parsed.hour, parsed.minute);
          }
        } catch (_) {}

        String status;
        Color color;
        if (end != null && end.isBefore(now)) {
          status = "overdue";
          color = Colors.red;
          overdue++;
        } else if (start != null &&
            end != null &&
            now.isAfter(start) &&
            now.isBefore(end)) {
          status = "in_progress";
          color = Colors.orange;
        } else if (start != null && start.isAfter(now)) {
          status = "next";
          color = Colors.blue;
        } else {
          status = "todo";
          color = Colors.grey;
        }

        computed.add(_TaskStatusItem(task: task, status: status, color: color));
      }
    }

    // sort by startTime (or date if no startTime)
    computed.sort((a, b) {
      DateTime aTime = a.task.startTime != null && a.task.startTime!.isNotEmpty
          ? DateFormat.jm().parse(a.task.startTime!)
          : a.task.date;
      DateTime bTime = b.task.startTime != null && b.task.startTime!.isNotEmpty
          ? DateFormat.jm().parse(b.task.startTime!)
          : b.task.date;
      return aTime.compareTo(bTime);
    });

    setState(() {
      overdueCount = overdue;
      totalTasks = tasks.length;
      completedToday = completed;
      todayTasks = computed;
    });
  }

  void _openTasksPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TasksPage(email: widget.email),
      ),
    ).then((_) => _loadTasks());
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
                            onPressed: () {
                              Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          SchedulePage(email: widget.email)));
                            },
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

                // TASKS ORDERED BY TIME
                Column(
                  children: todayTasks.map((item) {
                    return GestureDetector(
                      onTap: _openTasksPage,
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: item.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(18),
                          border:
                              Border.all(color: item.color.withOpacity(0.4)),
                        ),
                        child: Text(
                          _statusLabel(item),
                          style: TextStyle(
                            color: item.color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
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

  String _statusLabel(_TaskStatusItem item) {
    final formatted =
        (item.task.startTime != null && item.task.startTime!.isNotEmpty)
            ? item.task.startTime
            : DateFormat.jm().format(item.task.date);

    switch (item.status) {
      case "overdue":
        return "⚠️ ${item.task.title} is overdue! Ended at $formatted";
      case "in_progress":
        return "⏰ It's time for: ${item.task.title} ($formatted)";
      case "next":
        return "👉 Next: ${item.task.title} at $formatted";
      default:
        return "${item.task.title} (No time set)";
    }
  }
}

class _TaskStatusItem {
  final Task task;
  final String status;
  final Color color;
  _TaskStatusItem(
      {required this.task, required this.status, required this.color});
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
