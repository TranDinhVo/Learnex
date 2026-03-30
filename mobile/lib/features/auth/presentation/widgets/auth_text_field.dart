import 'package:flutter/material.dart';

class AuthTextField extends StatefulWidget {
  final String? label;
  final String hintText;
  final String initialValue;
  final IconData prefixIcon;
  final bool isPassword;
  final Widget? customSuffixIcon;
  final Widget? suffixIcon;
  final String? helperText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;

  const AuthTextField({
    super.key,
    this.label,
    required this.hintText,
    required this.prefixIcon,
    this.initialValue = '',
    this.isPassword = false,
    this.customSuffixIcon,
    this.suffixIcon,
    this.helperText,
    this.controller,
    this.onChanged,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  late bool _obscureText;
  
  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null)
          Padding(
            padding: const EdgeInsets.only(left: 4.0, bottom: 6.0),
            child: Text(
              widget.label!,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        TextFormField(
          controller: widget.controller,
          onChanged: widget.onChanged,
          initialValue: widget.controller == null ? widget.initialValue : null,
          obscureText: _obscureText,
          style: const TextStyle(fontSize: 15),
          decoration: InputDecoration(
            hintText: widget.hintText,
            prefixIcon: Icon(widget.prefixIcon, color: theme.colorScheme.onSurfaceVariant, size: 20),
            suffixIcon: widget.customSuffixIcon ?? widget.suffixIcon ?? (widget.isPassword ? IconButton(
              icon: Icon(
                _obscureText ? Icons.visibility_off : Icons.visibility,
                color: theme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  _obscureText = !_obscureText;
                });
              },
            ) : null),
            filled: true,
            fillColor: const Color(0xFFF3F4F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: theme.colorScheme.primary.withOpacity(0.4), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        if (widget.helperText != null)
          Padding(
            padding: const EdgeInsets.only(left: 4.0, top: 4.0),
            child: Text(
              widget.helperText!,
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}
