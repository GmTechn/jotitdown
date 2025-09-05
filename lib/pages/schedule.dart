import 'package:flutter/cupertino.dart';

import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

import 'package:notesapp/components/mynavbar.dart';
import 'package:notesapp/components/myschedulecard.dart';

import 'package:notesapp/management/database.dart';

import 'package:notesapp/models/task.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key, required this.email});
  final String email;

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
//Database calling

  final DatabaseManager _db = DatabaseManager();

//generating an index to switch between days
//starting from day 0 to +1 each day
  int selectedDayIndex = 0;

//Dayitem that would display a label "Mon, Tue" + the 4 days of the
//current week

  late List<_DayItem> _days;

//List of all task to be displayed when called from the database

  List<Task> _allTasks = [];

//state initialisation
  @override
  void initState() {
    super.initState();
    _days = _generateDays();
    _loadAllTasks();
  }

//generating days 4 at a time plus the index talked about earlier on

  List<_DayItem> _generateDays() {
    final today = DateTime.now();
    return List.generate(4, (i) {
      final date = today.add(Duration(days: i));
      final label = _weekdayLabel(date.weekday);
      return _DayItem(label, date.day);
    });
  }

//switching to display labels according to days

  String _weekdayLabel(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Mon';
      case DateTime.tuesday:
        return 'Tue';
      case DateTime.wednesday:
        return 'Wed';
      case DateTime.thursday:
        return 'Thu';
      case DateTime.friday:
        return 'Fri';
      case DateTime.saturday:
        return 'Sat';
      case DateTime.sunday:
        return 'Sun';
      default:
        return '';
    }
  }

//loading all tasks from task.dart/database

  Future<void> _loadAllTasks() async {
    final tasks = await _db.getTasksForUser(widget.email);
    setState(() {
      _allTasks = tasks;
    });
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

//Choosing to only get the task of the day and displaying it
//by targeting a specific day = today = current day

  List<Task> get _tasksForSelectedDay {
    final targetDay = _days[selectedDayIndex].day;
    final filtered = _allTasks.where((t) => t.date.day == targetDay).toList();

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
      final ak = timeKey(a.startTime);
      final bk = timeKey(b.startTime);
      return ak.compareTo(bk);
    });

    return filtered;
  }

//setting the time for each task and parsing them to string
//for display in a AM and PM format
//Generating a Time picker clock as well which
//won't allow the end time to be < than the start time of a task

  Future<void> _setTaskTime(Task task) async {
    if (task.status.toLowerCase() == 'done') return;

    String? startStr = task.startTime?.trim();
    String? endStr = task.endTime?.trim();

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

            Future<void> _saveTimes() async {
              if (startTOD != null &&
                  endTOD != null &&
                  (endTOD!.hour < startTOD!.hour ||
                      (endTOD?.hour == startTOD?.hour &&
                          endTOD!.minute <= startTOD!.minute))) {
                await showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text("Invalid Time"),
                    content: const Text("End time must be after start time."),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text("OK"),
                      ),
                    ],
                  ),
                );
                return;
              }

              ///---updating a task (time) after time has been set----

              await _db.updateTask(
                id: task.id!,
                status: task.status,
                title: task.title,
                subtitle: task.subtitle,
                date: task.date,
                startTime: startTOD != null
                    ? DateFormat.jm().format(
                        DateTime(0, 1, 1, startTOD!.hour, startTOD!.minute))
                    : null,
                endTime: endTOD != null
                    ? DateFormat.jm()
                        .format(DateTime(0, 1, 1, endTOD!.hour, endTOD!.minute))
                    : null,
              );
              if (mounted) {
                Navigator.pop(context);
                await _loadAllTasks();
              }
            }

            //---- Generating the bottom modal sheet widgets----
            //a handle and listTiles

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
                  const SizedBox(height: 8),
                  const Text(
                    'Set the time for your task',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(CupertinoIcons.clock),
                          title: const Text('Start'),
                          subtitle: Text(_fmt(startTOD)),
                          onTap: pickStart,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
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
                        child: const Text(
                          'Clear',
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: _saveTimes,
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
    final pillColor = const Color(0xff050c20);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('M Y   S C H E D U L E'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Day selector
            Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(_days.length, (i) {
                  final isSel = i == selectedDayIndex;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => selectedDayIndex = i),
                      child: Container(
                        margin: EdgeInsets.only(
                          left: i == 0 ? 0 : 6,
                          right: i == _days.length - 1 ? 0 : 6,
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSel ? pillColor : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            if (isSel)
                              BoxShadow(
                                color: pillColor.withOpacity(.35),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              _days[i].label,
                              style: TextStyle(
                                color: isSel ? Colors.white : Color(0xff050c20),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _days[i].day.toString(),
                              style: TextStyle(
                                color: isSel ? Colors.white : Color(0xff050c20),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            Expanded(
              child: _tasksForSelectedDay.isEmpty
                  ? const Center(
                      child: Text(
                        'No tasks for this day',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: _tasksForSelectedDay.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final t = _tasksForSelectedDay[index];
                        final now = DateTime.now();
                        final today = DateTime(now.year, now.month, now.day);
                        final taskDate =
                            DateTime(t.date.year, t.date.month, t.date.day);

                        String normalizedStatus;

                        if (t.status.toLowerCase() == 'done') {
                          normalizedStatus = 'done';
                        } else if (taskDate == today) {
                          final startDT =
                              t.startTime != null && t.startTime!.isNotEmpty
                                  ? DateFormat.jm().parse(t.startTime!)
                                  : null;
                          final endDT =
                              t.endTime != null && t.endTime!.isNotEmpty
                                  ? DateFormat.jm().parse(t.endTime!)
                                  : null;

                          if (startDT != null && endDT != null) {
                            final st = DateTime(today.year, today.month,
                                today.day, startDT.hour, startDT.minute);
                            final en = DateTime(today.year, today.month,
                                today.day, endDT.hour, endDT.minute);

                            if (now.isAfter(en)) {
                              normalizedStatus = 'overdue';
                            } else if (now.isAfter(st) && now.isBefore(en)) {
                              normalizedStatus = 'in_progress';
                            } else {
                              normalizedStatus = 'todo';
                            }
                          } else {
                            normalizedStatus = 'todo';
                          }
                        } else {
                          normalizedStatus = 'todo';
                        }

                        final String start =
                            t.startTime?.trim().isNotEmpty == true
                                ? t.startTime!
                                : '--:--';
                        final String end = t.endTime?.trim().isNotEmpty == true
                            ? t.endTime!
                            : '--:--';

                        return MyScheduleCard(
                          title: t.title,
                          subtitle: t.subtitle,
                          start: start,
                          end: end,
                          status: normalizedStatus,
                          avatarColor: Colors.blue.shade300,
                          onClockTap: () => _setTaskTime(t),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: MyNavBar(currentIndex: 1, email: widget.email),
    );
  }
}

// --- Classe DayItem interne ---
class _DayItem {
  final String label;
  final int day;
  const _DayItem(this.label, this.day);
}

// --- Classe SheetHandle ---
class _SheetHandle extends StatelessWidget {
  const _SheetHandle();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 5,
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}
