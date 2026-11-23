import 'package:geoattend/core/core.dart';

import '../../features/admin/data/mock_admin_repository.dart';
import '../../features/admin/data/remote_admin_repository.dart';
import '../../features/admin/domain/admin.dart';
import '../../features/attendance/data/mock_attendance_repository.dart';
import '../../features/attendance/data/remote_attendance_repository.dart';
import '../../features/attendance/domain/attendance.dart';
import '../../features/auth/data/mock_auth_repository.dart';
import '../../features/auth/data/remote_auth_repository.dart';
import '../../features/auth/domain/auth_repository.dart';
import '../../features/correction/data/mock_correction_repository.dart';
import '../../features/correction/data/remote_correction_repository.dart';
import '../../features/correction/domain/correction.dart';
import '../../features/hod/data/mock_team_repository.dart';
import '../../features/hod/data/remote_team_repository.dart';
import '../../features/hod/domain/team.dart';
import '../../features/leave/data/mock_leave_repository.dart';
import '../../features/leave/data/remote_leave_repository.dart';
import '../../features/leave/domain/leave.dart';
import '../../features/notifications/data/mock_notifications_repository.dart';
import '../../features/notifications/data/remote_notifications_repository.dart';
import '../../features/notifications/domain/notification.dart';
import '../../features/workplace/data/mock_workplace_repository.dart';
import '../../features/workplace/data/remote_workplace_repository.dart';
import '../../features/workplace/domain/workplace.dart';
import '../network/api_client.dart';
import '../network/token_storage.dart';

/// Wires everything to the in-memory mock repositories.
/// To go live, register your Dio-backed implementations here instead.
void setupDependencies() {
  sl.registerLazySingleton<SessionController>(() => SessionController());
  sl.registerLazySingleton<LocationService>(() => LocationService());

  sl.registerLazySingleton<TokenStorage>(() => TokenStorage());
  sl.registerLazySingleton<ApiClient>(() => ApiClient(sl<TokenStorage>(), sl<SessionController>()));
  // Phase 1: real login.
  sl.registerLazySingleton<AuthRepository>(() => AppConfig.useMockAuth
      ? MockAuthRepository()
      : RemoteAuthRepository(sl<ApiClient>(), sl<TokenStorage>()));
  // Phase 2: workplaces, departments and employees come from the API.
  sl.registerLazySingleton<WorkplaceRepository>(
      () => AppConfig.useMockAdmin ? MockWorkplaceRepository() : RemoteWorkplaceRepository(sl<ApiClient>()));
  // Phases 3-6: attendance, leave, corrections, notifications, team and reports.
  const mockOps = AppConfig.useMockOps;
  sl.registerLazySingleton<AttendanceRepository>(() => mockOps
      ? MockAttendanceRepository(sl<WorkplaceRepository>(), sl<LocationService>(), sl<SessionController>())
      : RemoteAttendanceRepository(
          sl<ApiClient>(), sl<WorkplaceRepository>(), sl<LocationService>(), sl<SessionController>()));
  sl.registerLazySingleton<LeaveRepository>(
      () => mockOps ? MockLeaveRepository(sl<SessionController>()) : RemoteLeaveRepository(sl<ApiClient>()));
  sl.registerLazySingleton<CorrectionRepository>(
      () => mockOps ? MockCorrectionRepository() : RemoteCorrectionRepository(sl<ApiClient>()));
  sl.registerLazySingleton<NotificationsRepository>(
      () => mockOps ? MockNotificationsRepository() : RemoteNotificationsRepository(sl<ApiClient>()));
  sl.registerLazySingleton<TeamRepository>(
      () => mockOps ? MockTeamRepository() : RemoteTeamRepository(sl<ApiClient>()));
  sl.registerLazySingleton<AdminRepository>(
      () => AppConfig.useMockAdmin ? MockAdminRepository() : RemoteAdminRepository(sl<ApiClient>()));

  // Revoke the refresh token on the server whenever the user signs out.
  sl<SessionController>().onSignOut = () => sl<AuthRepository>().logout();
}
