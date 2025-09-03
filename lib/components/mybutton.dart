import 'package:flutter/material.dart';

class MyButton extends StatelessWidget {
  MyButton(
      {super.key,
      required this.textbutton,
      required this.onTap,
      required this.buttonHeight,
      required this.buttonWidth});

  final String textbutton;
  final Function()? onTap;
  double buttonHeight;
  double buttonWidth;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Container(
        height: buttonHeight,
        width: buttonWidth,
        decoration: BoxDecoration(
          color: const Color(0xff050c20),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextButton(
            onPressed: onTap,
            child: Text(
              textbutton,
              style: const TextStyle(color: Colors.white),
            )),
      ),
    );
  }
}
