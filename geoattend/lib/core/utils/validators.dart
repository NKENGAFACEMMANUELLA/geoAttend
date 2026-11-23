class Validators {
  Validators._();

  static String? required(String? v, [String label = 'This field']) =>
      (v == null || v.trim().isEmpty) ? '$label is required' : null;

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());
    return ok ? null : 'Enter a valid email address';
  }

  static bool hasMinLength(String v) => v.length >= 6;
  static bool hasNumber(String v) => RegExp(r'\d').hasMatch(v);

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (!hasMinLength(v)) return 'Use at least 6 characters';
    if (!hasNumber(v)) return 'Include at least one number';
    return null;
  }

  static String? Function(String?) matches(String Function() other) => (v) {
        if (v == null || v.isEmpty) return 'Please confirm your password';
        return v == other() ? null : 'Passwords do not match';
      };

  static String? phone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Phone number is required';
    return RegExp(r'^\+?[0-9\s]{8,16}$').hasMatch(v.trim())
        ? null
        : 'Enter a valid phone number';
  }

  static String? _number(String? v, String label, double min, double max) {
    if (v == null || v.trim().isEmpty) return '$label is required';
    final n = double.tryParse(v.trim());
    if (n == null) return 'Enter a valid number';
    if (n < min || n > max) return '$label must be between $min and $max';
    return null;
  }

  static String? latitude(String? v) => _number(v, 'Latitude', -90, 90);
  static String? longitude(String? v) => _number(v, 'Longitude', -180, 180);
  static String? radius(String? v) {
    final e = _number(v, 'Radius', 50, 500);
    return e == null ? null : 'Radius must be between 50 and 500 meters';
  }
}
