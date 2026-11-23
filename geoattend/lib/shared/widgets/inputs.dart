import 'package:flutter/material.dart';
import 'package:geoattend/core/core.dart';

class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.isPassword = false,
    this.keyboardType,
    this.validator,
    this.readOnly = false,
    this.onTap,
    this.suffixIcon,
    this.maxLines = 1,
    this.onChanged,
    this.textInputAction,
  });

  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final bool isPassword;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final bool readOnly;
  final VoidCallback? onTap;
  final Widget? suffixIcon;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscure = widget.isPassword;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(widget.label!, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: widget.controller,
          obscureText: _obscure,
          keyboardType: widget.keyboardType,
          validator: widget.validator,
          readOnly: widget.readOnly,
          onTap: widget.onTap,
          onChanged: widget.onChanged,
          maxLines: widget.isPassword ? 1 : widget.maxLines,
          textInputAction: widget.textInputAction,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: widget.hint,
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(
                        _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: Colors.black),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  )
                : widget.suffixIcon,
          ),
        ),
      ],
    );
  }
}

class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    this.label,
    this.hint,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    this.value,
    this.validator,
  });

  final String? label;
  final String? hint;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T?>? onChanged;
  final T? value;
  final String? Function(T?)? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 8),
        ],
        DropdownButtonFormField<T>(
          value: items.contains(value) ? value : null,
          isExpanded: true,
          validator: validator,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black),
          decoration: InputDecoration(hintText: hint),
          style: const TextStyle(fontSize: 14, color: Colors.black),
          items: items
              .map((e) => DropdownMenuItem<T>(value: e, child: Text(itemLabel(e))))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class SearchField extends StatelessWidget {
  const SearchField({super.key, required this.onChanged, this.hint = 'Search by name or ID'});
  final ValueChanged<String> onChanged;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search, color: AppColors.hint),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }
}

/// "At least 6 characters / Contains a number" live checklist.
/// Grey while empty, red when failing, green when passing.
class PasswordRules extends StatelessWidget {
  const PasswordRules({super.key, required this.password});
  final String password;

  Widget _rule(String text, bool ok) {
    final color = password.isEmpty
        ? AppColors.hint
        : (ok ? AppColors.greenDark : AppColors.red);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: TextStyle(fontSize: 12, color: color)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Your password must contain:', style: TextStyle(fontSize: 14)),
        const SizedBox(height: 8),
        _rule('At least 6 characters', Validators.hasMinLength(password)),
        _rule('Contains a number', Validators.hasNumber(password)),
      ],
    );
  }
}
