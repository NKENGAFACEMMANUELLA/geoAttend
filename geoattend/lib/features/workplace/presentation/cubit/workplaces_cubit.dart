import 'package:geoattend/shared/shared.dart';

import '../../domain/workplace.dart';

class WorkplacesCubit extends AsyncCubit<List<Workplace>> {
  WorkplacesCubit(this._repo);
  final WorkplaceRepository _repo;

  Future<void> load() => run(_repo.list);

  Future<Workplace> save(Workplace w) async {
    final saved = await _repo.save(w);
    set(await _repo.list());
    return saved;
  }
}
