import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Mytextfield extends StatelessWidget {
  const Mytextfield({
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
  Widget build(BuildContext context) {
    final focusNode = FocusNode();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: TextField(
        style: const TextStyle(
          color: Color(0xff050c20),
        ),
        focusNode: focusNode,
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        textInputAction: textInputAction ?? TextInputAction.next,
        onSubmitted: (value) {
          focusNode.unfocus();
          if (textInputAction == TextInputAction.done) {
            FocusScope.of(context).unfocus();
          }
          if (onSubmitted != null) {
            onSubmitted!(value);
          }
        },
        cursorColor: const Color(0xff050c20),
        decoration: InputDecoration(
          prefixIcon: leadingIcon,
          suffixIcon: trailingIcon,
          hintText: hintText,
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
