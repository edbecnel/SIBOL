import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTextField extends StatefulWidget {
  const AppTextField({
    required this.controller,
    required this.label,
    super.key,
    this.obscureText = false,
    this.isPassword = false,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.maxLines = 1,
    this.minLines,
    this.enabled = true,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String label;

  /// When true (or [isPassword] is true), the field is obscured with an eye toggle.
  final bool obscureText;

  /// Password field with standard visibility toggle (preferred over [obscureText]).
  final bool isPassword;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final int maxLines;
  final int? minLines;
  final bool enabled;
  final List<TextInputFormatter>? inputFormatters;

  bool get _usesPasswordToggle => isPassword || obscureText;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscured;

  @override
  void initState() {
    super.initState();
    _obscured = widget._usesPasswordToggle;
  }

  @override
  void didUpdateWidget(covariant AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget._usesPasswordToggle && !oldWidget._usesPasswordToggle) {
      _obscured = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final passwordField = widget._usesPasswordToggle;
    return TextField(
      controller: widget.controller,
      enabled: widget.enabled,
      obscureText: passwordField ? _obscured : false,
      keyboardType: widget.keyboardType,
      inputFormatters: widget.inputFormatters,
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onSubmitted,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      decoration: InputDecoration(
        labelText: widget.label,
        suffixIcon: passwordField
            ? IconButton(
                tooltip: _obscured ? 'Show password' : 'Hide password',
                onPressed: () => setState(() => _obscured = !_obscured),
                icon: Icon(
                  _obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                ),
              )
            : null,
      ),
    );
  }
}
