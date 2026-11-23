enum UserRole { employee, hod, admin }

extension UserRoleX on UserRole {
  String get label => switch (this) {
        UserRole.employee => 'Employee',
        UserRole.hod => 'Head of Department',
        UserRole.admin => 'Administrator',
      };

  /// Route prefix: e = employee, h = HOD, a = admin.
  String get prefix => switch (this) {
        UserRole.employee => 'e',
        UserRole.hod => 'h',
        UserRole.admin => 'a',
      };

  String get homePath => '/$prefix/home';
}

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone = '',
    this.employeeId = '',
    this.department = '',
    this.position = '',
    this.workplace = '',
    this.organisation = '',
    this.isActive = true,
  });

  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String phone;
  final String employeeId;
  final String department;
  final String position;
  final String workplace;
  final String organisation;
  final bool isActive;

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: j['id'] as String,
        name: j['name'] as String,
        email: j['email'] as String,
        role: UserRole.values.byName(j['role'] as String),
        phone: (j['phone'] as String?) ?? '',
        employeeId: (j['employeeId'] as String?) ?? '',
        department: (j['department'] as String?) ?? '',
        position: (j['position'] as String?) ?? '',
        workplace: (j['workplace'] as String?) ?? '',
        organisation: (j['organisation'] as String?) ?? '',
        isActive: (j['isActive'] as bool?) ?? true,
      );

  String get firstName => name.split(' ').first;

  AppUser copyWith({String? name, String? email, String? phone}) => AppUser(
        id: id,
        name: name ?? this.name,
        email: email ?? this.email,
        role: role,
        phone: phone ?? this.phone,
        employeeId: employeeId,
        department: department,
        position: position,
        workplace: workplace,
        organisation: organisation,
        isActive: isActive,
      );
}
