import 'package:geoattend/core/core.dart';

import '../../hod/domain/team.dart';
import '../domain/admin.dart';

class MockAdminRepository implements AdminRepository {
  Future<void> _wait([int ms = 350]) => Future<void>.delayed(Duration(milliseconds: ms));

  final List<Employee> _employees = [
    const Employee(id: 'e1', name: 'Sarah Kim', code: 'EMP024', email: 'sarahkim@company.com', phone: '+237 681 000 111', department: 'Sales', position: 'Analyst', workplace: 'Main Office'),
    const Employee(id: 'e2', name: 'Akwi Joy', code: 'EMP018', email: 'akwijoy@company.com', phone: '+237 681 000 222', department: 'Marketing', position: 'Sales Executive', workplace: 'Main Office'),
    const Employee(id: 'e3', name: 'Atabong Joel', code: 'EMP001', email: 'joelatabong@gmail.com', phone: '+237 681 292 993', department: 'Marketing', position: 'Software Engineer', workplace: 'Main Office'),
    const Employee(id: 'e4', name: 'John Doe', code: 'EMP007', email: 'johndoe@gmail.com', phone: '+237 681 000 333', department: 'IT', position: 'Software Engineer', workplace: 'Main Office'),
    const Employee(id: 'e5', name: 'Amboh Queency', code: 'EMP071', email: 'amabohqueency@gmail.com', phone: '+237 681 000 444', department: 'Customer Service', position: 'Support Agent', workplace: 'Branch Office'),
    const Employee(id: 'e6', name: 'Alice Besingi', code: 'EMP066', email: 'besingialice@gmail.com', phone: '+237 681 000 555', department: 'Finance', position: 'Accountant', workplace: 'Main Office'),
    const Employee(id: 'e7', name: 'Michael Brown', code: 'EMP045', email: 'michaelbrown@company.com', phone: '+237 681 000 666', department: 'Sales', position: 'Analyst', workplace: 'Remote Office', active: false),
  ];

  final List<Department> _departments = [
    const Department(id: 'd1', name: 'IT', hodName: 'John Doe', hodEmail: 'johndoe@gmail.com', employeeCount: 12),
    const Department(id: 'd2', name: 'Marketing', hodName: 'Bechem', hodEmail: 'bechem@company.com', employeeCount: 18),
    const Department(id: 'd3', name: 'Finance', hodName: 'Ebot Peter', hodEmail: 'ebotpeter@company.com', employeeCount: 5),
    const Department(id: 'd4', name: 'Application', hodName: 'Atabongankeng Levis', hodEmail: 'levis@company.com', employeeCount: 7),
    const Department(id: 'd5', name: 'Customer Service', hodName: 'Njikem Blessing', hodEmail: 'njikem@company.com', employeeCount: 25),
    const Department(id: 'd6', name: 'Sales', hodName: 'James Wilson', hodEmail: 'jameswilson101@gmail.com', employeeCount: 28),
  ];

  static const _candidates = [
    HodCandidate(id: 'h1', name: 'Cheryl Akiepoh', email: 'cherylakiepoh@gmail.com'),
    HodCandidate(id: 'h2', name: 'John Doe', email: 'johndoe@gmail.com'),
    HodCandidate(id: 'h3', name: 'Amboh Queency', email: 'amabohqueency@gmail.com'),
    HodCandidate(id: 'h4', name: 'Alice Besingi', email: 'besingialice@gmail.com'),
  ];

  @override
  Future<AdminOverview> overview() async {
    await _wait();
    final d = Fmt.dateOnly(DateTime.now());
    return AdminOverview(
      employees: 248, present: 198, late: 12, absent: 18, onLeave: 20,
      recent: [
        TeamRow(name: 'Sarah Kim', employeeId: 'EMP 00124', position: '', department: 'Sales', status: AttendanceStatus.present, time: Fmt.atTime(d, 8, 12)),
        TeamRow(name: 'David Lee', employeeId: 'EMP 00131', position: '', department: 'Sales', status: AttendanceStatus.late, time: Fmt.atTime(d, 9, 45)),
        TeamRow(name: 'Michael Brown', employeeId: 'EMP 00145', position: '', department: 'Sales', status: AttendanceStatus.absent),
      ],
    );
  }

  @override
  Future<List<Employee>> employees() async {
    await _wait();
    return List.of(_employees);
  }

  @override
  Future<Employee> saveEmployee(Employee e) async {
    await _wait(500);
    if (e.id.isEmpty) {
      final created = Employee(
        id: 'e${DateTime.now().microsecondsSinceEpoch}', name: e.name, code: e.code, email: e.email,
        phone: e.phone, department: e.department, position: e.position, workplace: e.workplace, active: e.active,
      );
      _employees.add(created);
      return created;
    }
    final i = _employees.indexWhere((x) => x.id == e.id);
    if (i >= 0) _employees[i] = e;
    return e;
  }

  @override
  Future<List<Department>> departments() async {
    await _wait();
    return List.of(_departments);
  }

  @override
  Future<Department> saveDepartment(Department d, {HodCandidate? hod}) async {
    await _wait(500);
    final created = Department(
      id: d.id.isEmpty ? 'd${DateTime.now().microsecondsSinceEpoch}' : d.id,
      name: d.name, description: d.description,
      hodName: hod?.name ?? d.hodName, hodEmail: hod?.email ?? d.hodEmail,
      employeeCount: d.employeeCount, active: d.active,
    );
    final i = _departments.indexWhere((x) => x.id == created.id);
    if (i >= 0) {
      _departments[i] = created;
    } else {
      _departments.add(created);
    }
    return created;
  }

  @override
  Future<List<HodCandidate>> hodCandidates() async => _candidates;

  @override
  Future<void> assignHod(String departmentId, HodCandidate hod) async {
    await _wait(500);
    final i = _departments.indexWhere((x) => x.id == departmentId);
    if (i >= 0) _departments[i] = _departments[i].copyWith(hodName: hod.name, hodEmail: hod.email);
  }
}
