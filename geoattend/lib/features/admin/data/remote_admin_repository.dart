import 'package:geoattend/core/core.dart';

import '../../../core/network/api_client.dart';
import '../domain/admin.dart';

/// Employees, departments, HOD assignment and the dashboard numbers.
class RemoteAdminRepository implements AdminRepository {
  RemoteAdminRepository(this._api);
  final ApiClient _api;

  List<T> _list<T>(dynamic data, T Function(Map<String, dynamic>) parse) =>
      [for (final e in data as List) parse(e as Map<String, dynamic>)];

  @override
  Future<AdminOverview> overview() async {
    final data = await _api.send(() => _api.dio.get<dynamic>('/admin/overview'));
    return AdminOverview.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<List<Employee>> employees() async =>
      _list(await _api.send(() => _api.dio.get<dynamic>('/employees')), Employee.fromJson);

  @override
  Future<Employee> saveEmployee(Employee e) async {
    final body = {
      'name': e.name,
      'code': e.code,
      'email': e.email,
      'phone': e.phone,
      'department': e.department,
      'position': e.position,
      'workplace': e.workplace,
      if (e.id.isNotEmpty) 'active': e.active,
    };
    final data = await _api.send(() => e.id.isEmpty
        ? _api.dio.post<dynamic>('/employees', data: body)
        : _api.dio.patch<dynamic>('/employees/${e.id}', data: body));
    return Employee.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<List<Department>> departments() async =>
      _list(await _api.send(() => _api.dio.get<dynamic>('/departments')), Department.fromJson);

  @override
  Future<Department> saveDepartment(Department d, {HodCandidate? hod}) async {
    final data = await _api.send(() => d.id.isEmpty
        ? _api.dio.post<dynamic>('/departments', data: {
            'name': d.name,
            if (d.description.isNotEmpty) 'description': d.description,
            if (hod != null) 'hodUserId': hod.id,
          })
        : _api.dio.patch<dynamic>('/departments/${d.id}', data: {'name': d.name, 'description': d.description}));
    return Department.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<List<HodCandidate>> hodCandidates() async =>
      _list(await _api.send(() => _api.dio.get<dynamic>('/departments/hod-candidates')), HodCandidate.fromJson);

  @override
  Future<void> assignHod(String departmentId, HodCandidate hod) async {
    await _api.send(() => _api.dio.put<dynamic>('/departments/$departmentId/hod', data: {'userId': hod.id}));
  }
}
