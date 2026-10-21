import 'package:flutter/material.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    required this.controller,
    required this.label,
    super.key,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.maxLines = 1,
    this.minLines,
  });

  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final int maxLines;
  final int? minLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      maxLines: maxLines,
      minLines: minLines,
      decoration: InputDecoration(labelText: label),
    );
  }
}
