import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MyTextfield extends StatefulWidget {
  const MyTextfield({
    super.key,
    required this.controller,
    required this.hintText,
    required this.obscureText,
    required this.leadingIcon,
    this.trailingIcon,
    this.keyboardType,
    this.inputFormatters,
    this.textInputAction,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final Widget leadingIcon;
  final Widget? trailingIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onSubmitted;

  @override
  State<MyTextfield> createState() => _MyTextfieldState();
}

class _MyTextfieldState extends State<MyTextfield> {
  late FocusNode focusNode;

  @override
  void initState() {
    super.initState();
    focusNode = FocusNode();
  }

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: TextField(
        controller: widget.controller,
        focusNode: focusNode,
        obscureText: widget.obscureText,
        keyboardType: widget.keyboardType,
        inputFormatters: widget.inputFormatters,
        textInputAction: widget.textInputAction ?? TextInputAction.next,
        onSubmitted: (value) {
          focusNode.unfocus(); // ferme le clavier
          if (widget.onSubmitted != null) widget.onSubmitted!(value);
        },
        cursorColor: const Color(0xff050c20),
        decoration: InputDecoration(
          prefixIcon: widget.leadingIcon,
          suffixIcon: widget.trailingIcon,
          hintText: widget.hintText,
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: const Color(0xff050c20).withOpacity(.5),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xff050c20)),
          ),
        ),
      ),
    );
  }
}
