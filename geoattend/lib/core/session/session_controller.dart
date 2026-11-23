import 'package:flutter/foundation.dart';

import '../models/user_role.dart';

/// Holds the signed-in user. The router listens to it for redirects.
class SessionController extends ChangeNotifier {
  AppUser? _user;
  AppUser? get user => _user;
  bool get isLoggedIn => _user != null;
  UserRole? get role => _user?.role;

  void signIn(AppUser user) {
    _user = user;
    notifyListeners();
  }

  void update(AppUser user) {
    _user = user;
    notifyListeners();
  }

  /// Set in DI: revokes the refresh token on the server when the user signs out.
  Future<void> Function()? onSignOut;

  void signOut() {
    final hook = onSignOut;
    _user = null;
    notifyListeners();
    if (hook != null) hook();
  }
}
