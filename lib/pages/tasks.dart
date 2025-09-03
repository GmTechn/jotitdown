// ==============================
// tasks_page.dart  (TasksPage)
// ==============================
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:notesapp/components/mynavbar.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({super.key, required this.email});
  final String email;

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  int selectedFilter = 0; // 0: All, 1: To do, 2: In progress, 3: Done

  @override
  Widget build(BuildContext context) {
    final pill = (String text, int idx) => ChoiceChip(
          label: Text(text),
          selected: selectedFilter == idx,
          onSelected: (_) => setState(() => selectedFilter = idx),
          selectedColor: const Color(0xff050c20),
          labelStyle: TextStyle(
            color: selectedFilter == idx ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: BorderSide(color: Colors.grey.shade300),
          ),
        );

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('M Y   T A S K S'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 8.0),
            child: Icon(CupertinoIcons.search),
          ),
          Padding(
            padding: EdgeInsets.only(right: 12.0),
            child: Icon(CupertinoIcons.person_crop_circle),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            // Filter chips row (like screenshot)
            Wrap(
              spacing: 10,
              children: [
                pill('All task', 0),
                pill('To do', 1),
                pill('In progress', 2),
                pill('Done', 3),
              ],
            ),
            const SizedBox(height: 14),

            // Filters & sort row
            Row(
              children: [
                _GhostButton(
                  icon: CupertinoIcons.line_horizontal_3_decrease,
                  label: 'Filters',
                  onTap: () {},
                ),
                const SizedBox(width: 10),
                _GhostButton(
                  icon: CupertinoIcons.arrow_up_arrow_down,
                  label: 'Sort by',
                  onTap: () {},
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Task cards
            _TaskCard(
              statusText: 'In progress',
              statusColor: const Color(0xffF3C76B),
              title: 'Read poem & answer questions',
              subject: 'English Literature',
              dateText: 'May 28, 2025',
              commentsCount: 12,
              progress: .55,
            ),
            const SizedBox(height: 14),
            _TaskCard(
              statusText: 'To do',
              statusColor: const Color(0xffB9A6F4),
              title: 'Create a comic strip with a story',
              subject: 'Social Studies',
              dateText: 'May 30, 2025',
              commentsCount: 2,
              progress: .0,
            ),
            const SizedBox(height: 14),
            _TaskCard(
              statusText: 'To do',
              statusColor: const Color(0xffB9A6F4),
              title: 'Prepare for the math test',
              subject: 'Mathematics',
              dateText: 'Jun 2, 2025',
              commentsCount: 0,
              progress: .2,
            ),
          ],
        ),
      ),
      bottomNavigationBar: MyNavBar(currentIndex: 2, email: widget.email),
    );
  }
}

class _GhostButton extends StatelessWidget {
  const _GhostButton({required this.icon, required this.label, this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: const Color(0xff050c20)),
        label: Text(label, style: const TextStyle(color: Color(0xff050c20))),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey.shade300),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          backgroundColor: Colors.white,
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.statusText,
    required this.statusColor,
    required this.title,
    required this.subject,
    required this.dateText,
    required this.commentsCount,
    required this.progress,
  });

  final String statusText;
  final Color statusColor;
  final String title;
  final String subject;
  final String dateText;
  final int commentsCount;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.06),
            blurRadius: 10,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(.25),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                color: statusColor.withOpacity(.95),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xff050c20),
            ),
          ),
          const SizedBox(height: 6),
          Text(subject, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(CupertinoIcons.calendar,
                  size: 18, color: Colors.black54),
              const SizedBox(width: 6),
              Text(dateText, style: const TextStyle(color: Colors.black54)),
              const Spacer(),
              const Icon(CupertinoIcons.text_bubble,
                  size: 18, color: Colors.black54),
              const SizedBox(width: 4),
              Text('$commentsCount comments',
                  style: const TextStyle(color: Colors.black54)),
            ],
          ),
          const SizedBox(height: 14),
          // Progress bar (rounded, like screenshot)
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 12,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
              ),
              child: Stack(
                children: [
                  FractionallySizedBox(
                    widthFactor: progress.clamp(0, 1),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xff050c20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
