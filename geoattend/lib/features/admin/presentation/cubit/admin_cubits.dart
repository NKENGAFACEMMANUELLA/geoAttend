import 'package:geoattend/shared/shared.dart';

import '../../domain/admin.dart';

class AdminOverviewCubit extends AsyncCubit<AdminOverview> {
  AdminOverviewCubit(this._repo);
  final AdminRepository _repo;
  Future<void> load() => run(_repo.overview);
}

class EmployeesCubit extends AsyncCubit<List<Employee>> {
  EmployeesCubit(this._repo);
  final AdminRepository _repo;

  Future<void> load() => run(_repo.employees);

  Future<void> save(Employee e) async {
    await _repo.saveEmployee(e);
    set(await _repo.employees());
  }
}

class DepartmentsCubit extends AsyncCubit<List<Department>> {
  DepartmentsCubit(this._repo);
  final AdminRepository _repo;

  Future<void> load() => run(_repo.departments);

  Future<void> save(Department d, {HodCandidate? hod}) async {
    await _repo.saveDepartment(d, hod: hod);
    set(await _repo.departments());
  }

  Future<void> assignHod(String departmentId, HodCandidate hod) async {
    await _repo.assignHod(departmentId, hod);
    set(await _repo.departments());
  }
}
