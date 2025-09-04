import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:notesapp/components/mynavbar.dart';
import 'package:notesapp/management/database.dart';
import 'package:notesapp/components/myschedulecard.dart';
import 'package:notesapp/models/task.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key, required this.email, this.selectedDate});
  final String email;
  final DateTime?
      selectedDate; // permet d’ouvrir sur une date spécifique depuis dashboard

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  final DatabaseManager _db = DatabaseManager();

  int selectedDayIndex = 0;
  late List<_DayItem> _days;

  List<Task> _allTasks = [];

  @override
  void initState() {
    super.initState();
    _days = _generateDays();
    // si on vient du dashboard avec une date spécifique
    if (widget.selectedDate != null) {
      final idx = _days.indexWhere((d) =>
          d.date.year == widget.selectedDate!.year &&
          d.date.month == widget.selectedDate!.month &&
          d.date.day == widget.selectedDate!.day);
      if (idx >= 0) selectedDayIndex = idx;
    }

    _loadAllTasks();
  }

  List<_DayItem> _generateDays() {
    final today = DateTime.now();
    return List.generate(4, (i) {
      final date = today.add(Duration(days: i));
      final label = _weekdayLabel(date.weekday);
      return _DayItem(label, date);
    });
  }

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

  Future<void> _loadAllTasks() async {
    final tasks = await _db.getTasksForUser(widget.email);
    setState(() {
      _allTasks = tasks;
    });
  }

  List<Task> get _tasksForSelectedDay {
    final targetDate = _days[selectedDayIndex].date;
    final filtered = _allTasks
        .where((t) =>
            t.date.year == targetDate.year &&
            t.date.month == targetDate.month &&
            t.date.day == targetDate.day)
        .toList();

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
                      const SizedBox(width: 80),
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
                        child: const Text('Clear'),
                      ),
                      const SizedBox(width: 80),
                      TextButton(
                        onPressed: _saveTimes,
                        child: const Text('Save'),
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
    final pillColor = const Color(0xff050c20);
    final today = DateTime.now();

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
                              _days[i].date.day.toString(),
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

                        // ✅ Correction : statut gris si date dans le futur
                        String normalized;
                        final now = DateTime.now();
                        if (t.date.isAfter(now)) {
                          normalized = 'todo'; // gris
                        } else {
                          final statusRaw = t.status.toLowerCase();
                          if (statusRaw.contains('done')) {
                            normalized = 'done';
                          } else if (statusRaw.contains('progress')) {
                            normalized = 'in_progress';
                          } else {
                            normalized = 'todo';
                          }
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

class _DayItem {
  final String label;
  final DateTime date;
  const _DayItem(this.label, this.date);
}

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
