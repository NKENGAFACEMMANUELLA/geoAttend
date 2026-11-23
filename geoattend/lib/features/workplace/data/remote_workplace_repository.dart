import 'package:geoattend/core/core.dart';

import '../../../core/network/api_client.dart';
import '../domain/workplace.dart';

/// GET/POST/PATCH /api/v1/workplaces
class RemoteWorkplaceRepository implements WorkplaceRepository {
  RemoteWorkplaceRepository(this._api);
  final ApiClient _api;

  @override
  Future<List<Workplace>> list() async {
    final data = await _api.send(() => _api.dio.get<dynamic>('/workplaces'));
    return [for (final w in data as List) Workplace.fromJson(w as Map<String, dynamic>)];
  }

  @override
  Future<Workplace> save(Workplace w) async {
    final isNew = w.id.isEmpty;
    final data = await _api.send(() => isNew
        ? _api.dio.post<dynamic>('/workplaces', data: w.toJson())
        : _api.dio.patch<dynamic>('/workplaces/${w.id}', data: w.toJson()));
    return Workplace.fromJson(data as Map<String, dynamic>);
  }
}
