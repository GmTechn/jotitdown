import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:notesapp/components/mynavbar.dart';
import 'package:notesapp/management/database.dart';
import 'package:notesapp/components/myschedulecard.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key, required this.email});
  final String email;

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
//creating a database instance

  final DatabaseManager _db = DatabaseManager();

//first day would have index 0 but then
//we'll be adding +1 to get 4 days displayed
//as a small calendar in the schedule

  int selectedDayIndex = 0;
  late List<_DayItem> _days;

//generating a list of tasks that would display
//tasks from my tasks page/database

  List<Map<String, dynamic>> _allTasks = [];

  @override
  void initState() {
    super.initState();
    _days = _generateDays();
    _loadAllTasks();
  }

//generating a list of 4 days starting from the current day index i
//to the duration you add the index
//meaning today + i = the next day
//then retun a day item that has the date + day in a colum
//meaning label and date of the day

  List<_DayItem> _generateDays() {
    final today = DateTime.now();
    return List.generate(4, (i) {
      final date = today.add(Duration(days: i));
      final label = _weekdayLabel(date.weekday);
      return _DayItem(label, date.day);
    });
  }

//switching between the days of the week
//to know what day the current day is to display
//the respective text monday = mon

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

//loading the tasks from the database and the date/time they
//are due in a row based on the user email

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

//now target only the dask for the specific date
//meaning compare today's date with the database date
//if they match, display a list of those days
//This code selects tasks for the chosen day
//and gives each a “time value” so you can sort
//them from earliest to latest.

  List<Map<String, dynamic>> get _tasksForSelectedDay {
    final targetDay = _days[selectedDayIndex].day;
    final filtered = _allTasks.where((row) {
      final d = _rowDate(row);
      return d != null && d.day == targetDay;
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

//

  Future<void> _setTaskTime(Map<String, dynamic> task) async {
    if ((task['status'] as String?)?.toLowerCase() == 'done')
      return; // protection

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

              final db = await _db.database;
              await db.update(
                'tasks',
                {
                  'startTime': startTOD != null
                      ? DateFormat.jm().format(
                          DateTime(0, 1, 1, startTOD!.hour, startTOD!.minute))
                      : '',
                  'endTime': endTOD != null
                      ? DateFormat.jm().format(
                          DateTime(0, 1, 1, endTOD!.hour, endTOD!.minute))
                      : '',
                },
                where: 'id = ?',
                whereArgs: [task['id']],
              );
              if (mounted) {
                Navigator.pop(context);
                await _loadAllTasks();
              }
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
                  const SizedBox(height: 8),
                  const Text(
                    'Set the time for your task',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Start
                      InkWell(
                        onTap: pickStart,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(CupertinoIcons.clock, size: 28),
                            const SizedBox(width: 8),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Start',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _fmt(startTOD),
                                  style: const TextStyle(color: Colors.black87),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 80), // space between start and end
                      // End
                      InkWell(
                        onTap: pickEnd,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(CupertinoIcons.clock_fill, size: 28),
                            const SizedBox(width: 8),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'End',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _fmt(endTOD),
                                  style: const TextStyle(color: Colors.black87),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
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
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ),
                      const SizedBox(width: 80),
                      TextButton(
                        onPressed: _saveTimes,
                        child: const Text(
                          'Save',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
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
                                color: isSel ? Colors.white : Colors.black54,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _days[i].day.toString(),
                              style: TextStyle(
                                color: isSel ? Colors.white : Colors.black87,
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

                        final String title = (t['title'] as String?) ?? '';
                        final String subtitle =
                            (t['subtitle'] as String?) ?? '';
                        final String statusRaw =
                            ((t['status'] as String?) ?? '').toLowerCase();

                        String normalized;
                        if (statusRaw.contains('done')) {
                          normalized = 'done';
                        } else if (statusRaw.contains('progress')) {
                          normalized = 'in_progress';
                        } else {
                          normalized = 'todo';
                        }

                        final String start =
                            (t['startTime'] as String?)?.trim().isNotEmpty ==
                                    true
                                ? (t['startTime'] as String)
                                : '--:--';
                        final String end =
                            (t['endTime'] as String?)?.trim().isNotEmpty == true
                                ? (t['endTime'] as String)
                                : '--:--';

                        return MyScheduleCard(
                          title: title,
                          subtitle: subtitle,
                          start: start,
                          end: end,
                          status: normalized,
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
