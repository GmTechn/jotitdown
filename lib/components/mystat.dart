import 'package:flutter/material.dart';

class StatTile extends StatelessWidget {
  StatTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.containerColor,
  });

  final IconData icon;
  final String label;
  final String value;
  Color containerColor;

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
                border: Border.all(color: containerColor),
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
