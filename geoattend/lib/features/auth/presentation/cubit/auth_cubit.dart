import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geoattend/core/core.dart';

import '../../domain/auth_repository.dart';

/// State = "is a request running". Methods return an error message, or null on success.
class AuthCubit extends Cubit<bool> {
  AuthCubit(this._repo, this._session) : super(false);
  final AuthRepository _repo;
  final SessionController _session;

  static const _generic = 'Something went wrong. Please try again.';

  Future<String?> _guard(Future<void> Function() task) async {
    emit(true);
    try {
      await task();
      return null;
    } on AppException catch (e) {
      return e.message;
    } catch (_) {
      return _generic;
    } finally {
      emit(false);
    }
  }

  Future<String?> login(String email, String password, UserRole role) => _guard(() async {
        final user = await _repo.login(email: email, password: password, role: role);
        _session.signIn(user); // router redirects to the role's home
      });

  Future<String?> register(String name, String email, String employeeId, String password) =>
      _guard(() => _repo.register(name: name, email: email, employeeId: employeeId, password: password));

  Future<String?> sendResetCode(String email) => _guard(() => _repo.sendResetCode(email));

  /// On success `token` must be passed to [resetPassword].
  Future<({String? error, String? token})> verifyCode(String email, String code) async {
    emit(true);
    try {
      final token = await _repo.verifyCode(email: email, code: code);
      return (error: null, token: token);
    } on AppException catch (e) {
      return (error: e.message, token: null);
    } catch (_) {
      return (error: _generic, token: null);
    } finally {
      emit(false);
    }
  }

  Future<String?> resetPassword(String token, String newPassword) =>
      _guard(() => _repo.resetPassword(token: token, newPassword: newPassword));
}
