// ==============================
// schedule_page.dart (FIXED)
// ==============================
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:notesapp/components/mynavbar.dart';
import 'package:notesapp/management/database.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key, required this.email});
  final String email;

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  final DatabaseManager _db = DatabaseManager();

  int selectedDayIndex = 0;

  List<DateTime> _days = [];
  List<Map<String, dynamic>> _allTasks = [];

  @override
  void initState() {
    super.initState();
    _generateDays();
    _loadAllTasks();
  }

  void _generateDays() {
    final today = DateTime.now();
    _days = List.generate(4, (i) => today.add(Duration(days: i)));
  }

  Future<void> _loadAllTasks() async {
    final rows = await _db.getTasksForUser(widget.email);
    setState(() => _allTasks = rows);
  }

  DateTime? _rowDate(Map<String, dynamic> row) {
    final raw = row['date'];
    if (raw == null || (raw is String && raw.isEmpty)) return null;
    try {
      return DateTime.parse(raw as String);
    } catch (_) {
      return null;
    }
  }

  List<Map<String, dynamic>> get _tasksForSelectedDay {
    final targetDate = _days[selectedDayIndex];
    final filtered = _allTasks.where((row) {
      final d = _rowDate(row);
      return d != null &&
          d.year == targetDate.year &&
          d.month == targetDate.month &&
          d.day == targetDate.day;
    }).toList();

    int timeKey(String? t) {
      if (t == null || t.isEmpty) return 24 * 60 + 1;
      try {
        final dt = DateFormat.jm().parse(t);
        return dt.hour * 60 + dt.minute;
      } catch (_) {
        return 24 * 60 + 1;
      }
    }

    filtered.sort((a, b) {
      final ak = timeKey(a['startTime'] as String?);
      final bk = timeKey(b['startTime'] as String?);
      return ak.compareTo(bk);
    });

    return filtered;
  }

  Future<void> _setTaskTime(Map<String, dynamic> task) async {
    String? startStr = (task['startTime'] as String?)?.trim();
    String? endStr = (task['endTime'] as String?)?.trim();

    TimeOfDay? _toTOD(String? t) {
      if (t == null || t.isEmpty) return null;
      try {
        final dt = DateFormat.jm().parse(t);
        return TimeOfDay(hour: dt.hour, minute: dt.minute);
      } catch (_) {
        return null;
      }
    }

    TimeOfDay? startTOD = _toTOD(startStr);
    TimeOfDay? endTOD = _toTOD(endStr);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            String _fmt(TimeOfDay? tod) {
              if (tod == null) return '--:--';
              final dt = DateTime(0, 1, 1, tod.hour, tod.minute);
              return DateFormat.jm().format(dt);
            }

            Future<void> pickStart() async {
              final picked = await showTimePicker(
                context: context,
                initialTime: startTOD ?? TimeOfDay.now(),
              );
              if (picked != null) setStateSheet(() => startTOD = picked);
            }

            Future<void> pickEnd() async {
              final picked = await showTimePicker(
                context: context,
                initialTime: endTOD ?? TimeOfDay.now(),
              );
              if (picked != null) setStateSheet(() => endTOD = picked);
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _SheetHandle(),
                  const SizedBox(height: 12),
                  const Text(
                    'Set task time',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          leading: const Icon(CupertinoIcons.clock),
                          title: const Text('Start'),
                          subtitle: Text(_fmt(startTOD)),
                          onTap: pickStart,
                        ),
                      ),
                      Expanded(
                        child: ListTile(
                          leading: const Icon(CupertinoIcons.clock_fill),
                          title: const Text('End'),
                          subtitle: Text(_fmt(endTOD)),
                          onTap: pickEnd,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          setStateSheet(() {
                            startTOD = null;
                            endTOD = null;
                          });
                        },
                        child: const Text('Clear',
                            style: TextStyle(color: Colors.red)),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () async {
                          String? startSave;
                          String? endSave;

                          String _formatSave(TimeOfDay tod) {
                            final dt = DateTime(0, 1, 1, tod.hour, tod.minute);
                            return DateFormat.jm().format(dt);
                          }

                          if (startTOD != null)
                            startSave = _formatSave(startTOD!);
                          if (endTOD != null) endSave = _formatSave(endTOD!);

                          final db = await _db.database;
                          await db.update(
                            'tasks',
                            {
                              'startTime': startSave ?? '',
                              'endTime': endSave ?? '',
                            },
                            where: 'id = ?',
                            whereArgs: [task['id']],
                          );
                          if (mounted) {
                            Navigator.pop(context);
                            await _loadAllTasks();
                          }
                        },
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pillColor = const Color(0xff6D5DF6);

    return Scaffold(
      appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('M Y   S C H E D U L E')),
      body: SafeArea(
        child: Column(
          children: [
            // Day selector
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: List.generate(_days.length, (i) {
                  final isSel = i == selectedDayIndex;
                  final d = _days[i];
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => selectedDayIndex = i),
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSel ? pillColor : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          children: [
                            Text(DateFormat.E().format(d),
                                style: TextStyle(
                                    color:
                                        isSel ? Colors.white : Colors.black54)),
                            Text('${d.day}',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isSel ? Colors.white : Colors.black87)),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Task list
            Expanded(
              child: _tasksForSelectedDay.isEmpty
                  ? const Center(child: Text('No tasks'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _tasksForSelectedDay.length,
                      itemBuilder: (_, i) {
                        final t = _tasksForSelectedDay[i];
                        return _ScheduleCard(
                          task: t,
                          onClockTap: () => _setTaskTime(t),
                        );
                      }),
            ),
          ],
        ),
      ),
      bottomNavigationBar: MyNavBar(currentIndex: 1, email: widget.email),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final Map<String, dynamic> task;
  final VoidCallback? onClockTap;

  const _ScheduleCard({required this.task, this.onClockTap});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    String title = task['title'] ?? '';
    String subtitle = task['subtitle'] ?? '';
    String statusRaw = (task['status'] ?? '').toString().toLowerCase();

    String start = (task['startTime'] ?? '').toString();
    String end = (task['endTime'] ?? '').toString();
    if (start.isEmpty) start = '--:--';
    if (end.isEmpty) end = '--:--';

    DateTime? date;
    try {
      date = DateTime.parse(task['date']);
    } catch (_) {}

    DateTime? _parse(String t) {
      if (t == '--:--') return null;
      try {
        return DateFormat.jm().parse(t);
      } catch (_) {
        return null;
      }
    }

    final startDT = _parse(start);
    final endDT = _parse(end);

    IconData statusIcon = Icons.radio_button_unchecked;
    Color statusColor = Colors.grey;

    if (statusRaw.contains('done')) {
      statusIcon = Icons.check_circle;
      statusColor = Colors.green;
    } else if (date != null) {
      final today = DateTime(now.year, now.month, now.day);
      final taskDay = DateTime(date.year, date.month, date.day);

      if (taskDay.isAfter(today)) {
        // future date
        statusIcon = Icons.circle_outlined;
        statusColor = Colors.grey;
      } else if (taskDay.isAtSameMomentAs(today)) {
        if (startDT != null && endDT != null) {
          final st = DateTime(
              today.year, today.month, today.day, startDT.hour, startDT.minute);
          final en = DateTime(
              today.year, today.month, today.day, endDT.hour, endDT.minute);

          if (now.isAfter(en)) {
            statusIcon = Icons.cancel;
            statusColor = Colors.red;
          } else if (now.isAfter(st) && now.isBefore(en)) {
            statusIcon = Icons.access_time;
            statusColor = Colors.orange;
          } else {
            statusIcon = Icons.circle_outlined;
            statusColor = Colors.grey;
          }
        }
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: statusColor, width: 2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: onClockTap,
            child: const Icon(CupertinoIcons.clock, color: Colors.black54),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 86,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(start,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.black87)),
                Text(end, style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 16)),
                Text(subtitle, style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ),
          Icon(statusIcon, color: statusColor),
        ],
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 5,
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}
