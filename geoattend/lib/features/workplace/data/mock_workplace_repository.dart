import '../domain/workplace.dart';

class MockWorkplaceRepository implements WorkplaceRepository {
  final List<Workplace> _items = [
    const Workplace(id: 'w1', name: 'Main Office', address: 'Buea, Cameroon', latitude: 4.1527, longitude: 9.2410, radius: 100),
    const Workplace(id: 'w2', name: 'Branch Office', address: 'Limbe, Cameroon', latitude: 4.0186, longitude: 9.2040, radius: 150),
    const Workplace(id: 'w3', name: 'Remote Office', address: 'Yaounde, Cameroon', latitude: 3.8480, longitude: 11.5021, radius: 100, active: false),
  ];

  @override
  Future<List<Workplace>> list() async => List.of(_items);

  @override
  Future<Workplace> save(Workplace w) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (w.id.isEmpty) {
      final created = w.copyWith(id: 'w${DateTime.now().microsecondsSinceEpoch}');
      _items.add(created);
      return created;
    }
    final i = _items.indexWhere((e) => e.id == w.id);
    if (i >= 0) _items[i] = w;
    return w;
  }
}
