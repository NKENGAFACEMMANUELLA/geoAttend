import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../constants/app_config.dart';

/// A GPS reading plus what the server needs to judge it.
class LocationFix {
  const LocationFix(this.point, {this.accuracy, this.mocked = false});
  final LatLng point;
  final double? accuracy; // meters
  final bool mocked; // Android: position came from a mock-location app
}

class LocationService {
  /// Returns the device position, or null if GPS is off / permission denied.
  /// With [AppConfig.useMockLocation] it returns a point ~11 m from [mockNear].
  Future<LocationFix?> currentFix({LatLng? mockNear}) async {
    if (AppConfig.useMockLocation && mockNear != null) {
      return LocationFix(LatLng(mockNear.latitude + 0.0001, mockNear.longitude), accuracy: 8);
    }
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      return LocationFix(LatLng(pos.latitude, pos.longitude), accuracy: pos.accuracy, mocked: pos.isMocked);
    } catch (_) {
      return null;
    }
  }

  Future<LatLng?> currentPosition({LatLng? mockNear}) async => (await currentFix(mockNear: mockNear))?.point;

  double distanceMeters(LatLng a, LatLng b) =>
      const Distance().as(LengthUnit.Meter, a, b);
}
