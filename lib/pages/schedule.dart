// ==============================
// schedule_page.dart  (SchedulePage)
// ==============================
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:notesapp/components/mynavbar.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key, required this.email});
  final String email;

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  int selectedDayIndex = 1; // mimic screenshot (Tue selected)

  final _days = const [
    _DayItem('Mon', 18),
    _DayItem('Tue', 19),
    _DayItem('Wed', 20),
    _DayItem('Thu', 21),
    _DayItem('Fri', 22),
  ];

  @override
  Widget build(BuildContext context) {
    final pillColor = const Color(0xff6D5DF6); // soft purple like screenshot
    final accentGreen = const Color(0xffA6F0B5);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('M Y   S C H E D U L E'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(CupertinoIcons.calendar),
          )
        ],
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
                            right: i == _days.length - 1 ? 0 : 6),
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
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  _ScheduleCard(
                    title: 'Social Studies',
                    start: '8:30 AM',
                    end: '10:00 AM',
                    room: 'B3, Room 124',
                    teacherName: 'Mrs. Goodman',
                    avatarColor: Colors.orange.shade300,
                  ),
                  const SizedBox(height: 10),
                  _ScheduleCard(
                    highlightColor: accentGreen,
                    title: 'English Literature',
                    start: '10:30 AM',
                    end: '12:00 AM',
                    room: 'B2, Room 156',
                    teacherName: 'Mrs. Melton',
                    avatarColor: Colors.green.shade400,
                    isHighlighted: true,
                  ),
                  const SizedBox(height: 10),
                  _ScheduleCard(
                    title: 'Computer Science',
                    start: '12:15 AM',
                    end: '1:45 PM',
                    room: 'B3, Room 310',
                    teacherName: 'Mr. Hodge',
                    avatarColor: Colors.blue.shade300,
                  ),
                ],
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
  final int day;
  const _DayItem(this.label, this.day);
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({
    required this.title,
    required this.start,
    required this.end,
    required this.room,
    required this.teacherName,
    required this.avatarColor,
    this.isHighlighted = false,
    this.highlightColor,
  });

  final String title;
  final String start;
  final String end;
  final String room;
  final String teacherName;
  final Color avatarColor;
  final bool isHighlighted;
  final Color? highlightColor;

  @override
  Widget build(BuildContext context) {
    final bg = isHighlighted
        ? (highlightColor ?? const Color(0xffA6F0B5))
        : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.06),
            blurRadius: 10,
            offset: const Offset(0, 6),
          )
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(CupertinoIcons.clock, color: Colors.black54),
          const SizedBox(width: 10),
          SizedBox(
            width: 86,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(start,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, color: Colors.black87)),
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
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xff050c20))),
                const SizedBox(height: 6),
                Text(room, style: const TextStyle(color: Colors.black54)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: avatarColor,
                      child: const Icon(Icons.person,
                          color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 8),
                    Text(teacherName,
                        style: const TextStyle(color: Colors.black87)),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
