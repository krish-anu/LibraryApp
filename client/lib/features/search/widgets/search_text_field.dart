import 'package:flutter/material.dart';
import 'package:libraryapp/core/theme/app_pallete.dart';

/// A search text field widget with styling.
class SearchTextField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final FocusNode? focusNode;
  final bool autofocus;

  const SearchTextField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.focusNode,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        focusNode: focusNode,
        autofocus: autofocus,
        style: const TextStyle(color: Pallete.textPrimary),
        decoration: InputDecoration(
          filled: true,
          fillColor: Pallete.cardBackground,
          hintText: "Search books...",
          hintStyle: TextStyle(color: Pallete.textSecondary),
          prefixIcon: Icon(Icons.search, color: Pallete.textSecondary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
