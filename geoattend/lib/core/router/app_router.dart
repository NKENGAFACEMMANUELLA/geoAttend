import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:geoattend/core/core.dart';
import 'package:geoattend/shared/shared.dart';

import '../../features/admin/presentation/pages/admin_dashboard_page.dart';
import '../../features/admin/presentation/pages/admin_leave_page.dart';
import '../../features/admin/presentation/pages/company_settings_page.dart';
import '../../features/admin/presentation/pages/departments_pages.dart';
import '../../features/admin/presentation/pages/employees_pages.dart';
import '../../features/attendance/presentation/pages/attendance_details_page.dart';
import '../../features/attendance/presentation/pages/attendance_history_page.dart';
import '../../features/attendance/presentation/pages/clock_result_page.dart';
import '../../features/attendance/presentation/pages/location_verification_page.dart';
import '../../features/attendance/domain/attendance.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/reset_password_page.dart';
import '../../features/auth/presentation/pages/verify_code_page.dart';
import '../../features/correction/presentation/pages/correction_list_page.dart';
import '../../features/correction/presentation/pages/request_correction_page.dart';
import '../../features/hod/presentation/pages/hod_corrections_page.dart';
import '../../features/hod/presentation/pages/hod_leave_details_page.dart';
import '../../features/hod/presentation/pages/hod_pages.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/leave/presentation/pages/leave_details_page.dart';
import '../../features/leave/presentation/pages/leave_request_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/reports/presentation/pages/department_reports_page.dart';
import '../../features/reports/presentation/pages/report_result_page.dart';
import '../../features/requests/presentation/pages/my_requests_page.dart';
import '../../features/hod/domain/team.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/settings/presentation/pages/settings_section_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/workplace/presentation/pages/geofence_page.dart';
import '../../features/workplace/presentation/pages/workplaces_pages.dart';
import 'role_shell.dart';

const _authPaths = {R.login, R.loginHod, R.loginAdmin, R.register, R.forgot, R.verify, R.reset};
const _openPaths = {R.splash, R.success, R.error};

/// Keeps each role inside its own area of the app.
bool _allowed(UserRole role, String loc) {
  bool any(List<String> prefixes) => prefixes.any(loc.startsWith);
  switch (role) {
    case UserRole.employee:
      return !any(['/h/', '/hod/', '/a/', '/admin/', '/report']);
    case UserRole.hod:
      return !any(['/e/', '/a/', '/admin/', '/clock', '/leave', '/correction', '/attendance']);
    case UserRole.admin:
      return !any(['/e/', '/h/', '/hod/', '/clock', '/leave', '/correction', '/attendance']);
  }
}

StatefulShellBranch _branch(String path, Widget page) =>
    StatefulShellBranch(routes: [GoRoute(path: path, builder: (_, __) => page)]);

StatefulShellRoute _shell(UserRole role, List<Widget> pages) {
  // Employees get "Requests" in the third tab; HOD and Admin get "Reports".
  final third = role == UserRole.employee ? 'requests' : 'reports';
  final names = ['home', 'attendance', third, 'notifications', 'profile'];
  return StatefulShellRoute.indexedStack(
    builder: (_, __, shell) => RoleShell(role: role, shell: shell),
    branches: [for (var i = 0; i < names.length; i++) _branch(R.tab(role, names[i]), pages[i])],
  );
}

GoRouter buildRouter(SessionController session) {
  return GoRouter(
    initialLocation: R.splash,
    refreshListenable: session,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final role = session.role;
      if (role == null) {
        return (_authPaths.contains(loc) || _openPaths.contains(loc)) ? null : R.login;
      }
      if (_authPaths.contains(loc)) return role.homePath;
      if (loc == R.splash) return null;
      return _allowed(role, loc) ? null : role.homePath;
    },
    routes: [
      GoRoute(path: R.splash, builder: (_, __) => const SplashPage()),
      GoRoute(path: R.login, builder: (_, __) => const LoginPage()),
      GoRoute(path: R.loginHod, builder: (_, __) => const LoginPage(role: UserRole.hod)),
      GoRoute(path: R.loginAdmin, builder: (_, __) => const LoginPage(role: UserRole.admin)),
      GoRoute(path: R.register, builder: (_, __) => const RegisterPage()),
      GoRoute(path: R.forgot, builder: (_, __) => const ForgotPasswordPage()),
      GoRoute(path: R.verify, builder: (_, s) => VerifyCodePage(email: (s.extra as String?) ?? '')),
      GoRoute(path: R.reset, builder: (_, s) => ResetPasswordPage(token: (s.extra as String?) ?? '')),

      // Bottom-nav shells
      _shell(UserRole.employee, const [
        HomePage(), AttendanceHistoryPage(), MyRequestsPage(), NotificationsPage(), ProfilePage(),
      ]),
      _shell(UserRole.hod, const [
        HodDashboardPage(), DepartmentAttendancePage(), DepartmentReportsPage(), NotificationsPage(), ProfilePage(),
      ]),
      _shell(UserRole.admin, const [
        AdminDashboardPage(), OrganisationAttendancePage(), DepartmentReportsPage(), NotificationsPage(), CompanySettingsPage(),
      ]),

      // Shared
      GoRoute(path: R.settings, builder: (_, __) => const SettingsPage()),
      GoRoute(path: R.settingsSection, builder: (_, s) => SettingsSectionPage(section: s.pathParameters['section']!)),
      GoRoute(
        path: R.success,
        builder: (_, s) => SuccessPage(args: (s.extra as SuccessArgs?) ?? const SuccessArgs(nextRoute: R.login)),
      ),
      GoRoute(path: R.error, builder: (_, s) => ErrorPage(message: s.extra as String?)),

      // Employee flows
      GoRoute(
        path: R.verifyLocation,
        builder: (_, s) => LocationVerificationPage(isClockIn: s.pathParameters['mode'] == 'in'),
      ),
      GoRoute(path: R.clockResult, builder: (_, s) => ClockResultPage(args: s.extra as ClockResultArgs)),
      GoRoute(path: R.attendanceDetails, builder: (_, s) => AttendanceDetailsPage(record: s.extra as AttendanceRecord)),
      GoRoute(path: R.leaveNew, builder: (_, __) => const LeaveRequestPage()),
      GoRoute(path: R.leaveDetails, builder: (_, s) => LeaveDetailsPage(id: s.pathParameters['id']!)),
      GoRoute(path: R.correctionNew, builder: (_, __) => const RequestCorrectionPage()),
      GoRoute(path: R.correctionList, builder: (_, __) => const CorrectionListPage()),

      // HOD flows
      GoRoute(path: R.dailySummary, builder: (_, __) => const DailySummaryPage()),
      GoRoute(path: R.reportResult, builder: (_, s) => ReportResultPage(report: s.extra as AttendanceReport)),
      GoRoute(path: R.hodCorrections, builder: (_, __) => const HodCorrectionsPage()),
      GoRoute(path: R.hodLeave, builder: (_, s) => HodLeaveDetailsPage(id: s.pathParameters['id']!)),

      // Admin flows (specific paths before parameterised ones)
      GoRoute(path: R.adminLeave, builder: (_, __) => const AdminLeavePage()),
      GoRoute(path: R.adminLeaveDetails, builder: (_, s) => HodLeaveDetailsPage(id: s.pathParameters['id']!)),
      GoRoute(path: R.employees, builder: (_, __) => const EmployeesPage()),
      GoRoute(path: R.employeeNew, builder: (_, __) => const EmployeeFormPage()),
      GoRoute(path: R.employeeEdit, builder: (_, s) => EmployeeFormPage(id: s.pathParameters['id'])),
      GoRoute(path: R.departments, builder: (_, __) => const DepartmentsPage()),
      GoRoute(path: R.departmentNew, builder: (_, __) => const DepartmentFormPage()),
      GoRoute(path: R.departmentDetails, builder: (_, s) => DepartmentDetailsPage(id: s.pathParameters['id']!)),
      GoRoute(path: R.hodAssignment, builder: (_, s) => HodAssignmentPage(departmentId: s.pathParameters['id'])),
      GoRoute(path: R.workplaces, builder: (_, __) => const WorkplacesPage()),
      GoRoute(path: R.workplaceNew, builder: (_, __) => const WorkplaceFormPage()),
      GoRoute(path: R.workplaceDetails, builder: (_, s) => WorkplaceDetailsPage(id: s.pathParameters['id']!)),
      GoRoute(path: R.workplaceEdit, builder: (_, s) => WorkplaceFormPage(id: s.pathParameters['id'])),
      GoRoute(path: R.geofence, builder: (_, __) => const GeofenceConfigurationPage()),
    ],
  );
}
