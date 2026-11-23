import '../../hod/domain/team.dart';

const employeeRoles = [
  'Software Engineer', 'Analyst', 'Senior Analyst', 'Junior Analyst', 'Sales Executive',
  'Marketing Officer', 'Accountant', 'Support Agent', 'HR Officer', 'HOD/Officer',
];

class Employee {
  const Employee({
    required this.id,
    required this.name,
    required this.code,
    required this.email,
    required this.phone,
    required this.department,
    required this.position,
    required this.workplace,
    this.active = true,
  });
  final String id;
  final String name;
  final String code; // e.g. EMP024
  final String email;
  final String phone;
  final String department;
  final String position;
  final String workplace;
  final bool active;

  factory Employee.fromJson(Map<String, dynamic> j) => Employee(
        id: j['id'] as String,
        name: j['name'] as String,
        code: j['code'] as String,
        email: j['email'] as String,
        phone: (j['phone'] as String?) ?? '',
        department: (j['department'] as String?) ?? '',
        position: (j['position'] as String?) ?? '',
        workplace: (j['workplace'] as String?) ?? '',
        active: (j['active'] as bool?) ?? true,
      );
}

class Department {
  const Department({
    required this.id,
    required this.name,
    this.description = '',
    this.hodName = '',
    this.hodEmail = '',
    this.employeeCount = 0,
    this.active = true,
  });
  final String id;
  final String name;
  final String description;
  final String hodName;
  final String hodEmail;
  final int employeeCount;
  final bool active;

  factory Department.fromJson(Map<String, dynamic> j) => Department(
        id: j['id'] as String,
        name: j['name'] as String,
        description: (j['description'] as String?) ?? '',
        hodName: (j['hodName'] as String?) ?? '',
        hodEmail: (j['hodEmail'] as String?) ?? '',
        employeeCount: (j['employeeCount'] as num?)?.toInt() ?? 0,
        active: (j['active'] as bool?) ?? true,
      );

  Department copyWith({String? hodName, String? hodEmail}) => Department(
        id: id, name: name, description: description,
        hodName: hodName ?? this.hodName, hodEmail: hodEmail ?? this.hodEmail,
        employeeCount: employeeCount, active: active,
      );
}

class HodCandidate {
  const HodCandidate({required this.id, required this.name, required this.email});
  final String id; // user id on the server
  final String name;
  final String email;

  factory HodCandidate.fromJson(Map<String, dynamic> j) =>
      HodCandidate(id: j['id'] as String, name: j['name'] as String, email: j['email'] as String);
}

class AdminOverview {
  const AdminOverview({
    required this.employees, required this.present, required this.late,
    required this.absent, required this.onLeave, required this.recent,
  });
  final int employees;
  final int present;
  final int late;
  final int absent;
  final int onLeave;
  final List<TeamRow> recent;

  factory AdminOverview.fromJson(Map<String, dynamic> j) => AdminOverview(
        employees: (j['employees'] as num).toInt(),
        present: (j['present'] as num).toInt(),
        late: (j['late'] as num).toInt(),
        absent: (j['absent'] as num).toInt(),
        onLeave: (j['onLeave'] as num).toInt(),
        recent: [for (final r in (j['recent'] as List)) TeamRow.fromJson(r as Map<String, dynamic>)],
      );

  /// Share of employees who showed up (present + late).
  int get rate => employees == 0 ? 0 : ((present + late) / employees * 100).round();
}

abstract class AdminRepository {
  Future<AdminOverview> overview();
  Future<List<Employee>> employees();
  Future<Employee> saveEmployee(Employee e);
  Future<List<Department>> departments();
  Future<Department> saveDepartment(Department d, {HodCandidate? hod});
  Future<List<HodCandidate>> hodCandidates();
  Future<void> assignHod(String departmentId, HodCandidate hod);
}
