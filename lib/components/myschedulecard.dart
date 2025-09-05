import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MyScheduleCard extends StatelessWidget {
  const MyScheduleCard({
    required this.title,
    required this.start,
    required this.end,
    required this.subtitle,
    required this.status,
    required this.avatarColor,
    this.onClockTap,
    super.key,
  });

  final String title;
  final String start;
  final String end;
  final String subtitle;
  final String status; // 'todo' | 'in_progress' | 'done' | 'overdue'
  final Color avatarColor;
  final VoidCallback? onClockTap;

  @override
  Widget build(BuildContext context) {
    IconData statusIcon;
    Color statusColor;

    //---- Switching between colors depending on the status of the app----

    switch (status) {
      case 'done':
        statusIcon = Icons.check_circle;
        statusColor = Colors.green;
        break;
      case 'in_progress':
        statusIcon = Icons.access_time;
        statusColor = Colors.orange;
        break;
      case 'overdue':
        statusIcon = Icons.cancel;
        statusColor = Colors.red;
        break;
      //Default status is when the task is 'to do'
      //meaning if I push a task to the next day,
      //it would be greyed out

      default:
        statusIcon = Icons.circle_outlined;
        statusColor = Colors.grey;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: statusColor, width: 2),
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
          InkWell(
            onTap: onClockTap,
            borderRadius: BorderRadius.circular(8),
            child: const Tooltip(
              message: "Set the time for your task",
              child: Icon(CupertinoIcons.clock, color: Colors.black54),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 86,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  start,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, color: Colors.black87),
                ),
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
                        fontWeight: FontWeight.bold, fontSize: 16)),
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
