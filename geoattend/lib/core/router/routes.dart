import '../models/user_role.dart';

/// All route paths in one place. `...Of` helpers build parameterised paths.
class R {
  R._();
  static const splash = '/splash';
  static const login = '/login';
  static const loginHod = '/login/hod';
  static const loginAdmin = '/login/admin';
  static const register = '/register';
  static const forgot = '/forgot';
  static const verify = '/verify';
  static const reset = '/reset';

  static const settings = '/settings';
  static const settingsSection = '/settings/:section';
  static String settingsOf(String s) => '/settings/$s';

  static const verifyLocation = '/clock/verify/:mode';
  static String verifyLocationOf(String mode) => '/clock/verify/$mode';
  static const clockResult = '/clock/result';
  static const attendanceDetails = '/attendance/details';

  static const leaveNew = '/leave/new';
  static const leaveDetails = '/leave/:id';
  static String leaveOf(String id) => '/leave/$id';
  static const correctionNew = '/correction/new';
  static const correctionList = '/correction/list';

  static const success = '/success';
  static const error = '/error';

  static const hodLeave = '/hod/leave/:id';
  static String hodLeaveOf(String id) => '/hod/leave/$id';
  static const dailySummary = '/hod/summary';
  static const hodCorrections = '/hod/corrections';
  static const adminLeave = '/admin/leave';
  static const adminLeaveDetails = '/admin/leave/:id';
  static String adminLeaveOf(String id) => '/admin/leave/$id';
  static const reportResult = '/report/result';

  static const employees = '/admin/employees';
  static const employeeNew = '/admin/employees/new';
  static const employeeEdit = '/admin/employees/:id/edit';
  static String employeeEditOf(String id) => '/admin/employees/$id/edit';
  static const departments = '/admin/departments';
  static const departmentNew = '/admin/departments/new';
  static const departmentDetails = '/admin/departments/:id';
  static String departmentOf(String id) => '/admin/departments/$id';
  static const hodAssignment = '/admin/departments/:id/hod';
  static String hodAssignmentOf(String id) => '/admin/departments/$id/hod';
  static const workplaces = '/admin/workplaces';
  static const workplaceNew = '/admin/workplaces/new';
  static const workplaceDetails = '/admin/workplaces/:id';
  static String workplaceOf(String id) => '/admin/workplaces/$id';
  static const workplaceEdit = '/admin/workplaces/:id/edit';
  static String workplaceEditOf(String id) => '/admin/workplaces/$id/edit';
  static const geofence = '/admin/geofence';

  /// Bottom-nav tab path for a role: home, attendance, reports, notifications, profile.
  static String tab(UserRole role, String name) => '/${role.prefix}/$name';
}
