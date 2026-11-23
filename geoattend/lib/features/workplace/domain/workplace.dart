class Workplace {
  const Workplace({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.radius,
    this.active = true,
  });

  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double radius; // meters
  final bool active;

  factory Workplace.fromJson(Map<String, dynamic> j) => Workplace(
        id: j['id'] as String,
        name: j['name'] as String,
        address: (j['address'] as String?) ?? '',
        latitude: (j['latitude'] as num).toDouble(),
        longitude: (j['longitude'] as num).toDouble(),
        radius: (j['radius'] as num).toDouble(),
        active: (j['active'] as bool?) ?? true,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'radius': radius.round(), // the server wants whole meters
        'active': active,
      };

  Workplace copyWith({
    String? id, String? name, String? address, double? latitude,
    double? longitude, double? radius, bool? active,
  }) =>
      Workplace(
        id: id ?? this.id,
        name: name ?? this.name,
        address: address ?? this.address,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        radius: radius ?? this.radius,
        active: active ?? this.active,
      );
}

abstract class WorkplaceRepository {
  Future<List<Workplace>> list();
  Future<Workplace> save(Workplace workplace);
}
