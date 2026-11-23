import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:geoattend/core/core.dart';
import 'package:geoattend/shared/shared.dart';

import '../../domain/workplace.dart';
import '../cubit/workplaces_cubit.dart';

/// Admin sets where (tap the map) and how far (slider) employees may clock in.
class GeofenceConfigurationPage extends StatefulWidget {
  const GeofenceConfigurationPage({super.key});

  @override
  State<GeofenceConfigurationPage> createState() => _GeofenceConfigurationPageState();
}

class _GeofenceConfigurationPageState extends State<GeofenceConfigurationPage> {
  final _map = MapController();
  Workplace? _wp;
  LatLng _center = const LatLng(4.1527, 9.2410);
  double _radius = 100;
  bool _saving = false;

  void _select(Workplace w, {bool moveMap = false}) {
    _wp = w;
    _center = LatLng(w.latitude, w.longitude);
    _radius = w.radius.clamp(50, 500).toDouble();
    if (moveMap) _map.move(_center, 16);
  }

  Future<void> _save() async {
    final wp = _wp;
    if (wp == null) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      await context.read<WorkplacesCubit>().save(
          wp.copyWith(latitude: _center.latitude, longitude: _center.longitude, radius: _radius));
      messenger.showSnackBar(const SnackBar(content: Text('Geofence saved')));
      if (mounted) context.pop();
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      context.push(R.error, extra: e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = context.watch<WorkplacesCubit>().state.data ?? const <Workplace>[];
    if (_wp == null && list.isNotEmpty) _select(list.first);

    return Scaffold(
      body: list.isEmpty
          ? const SafeArea(child: SkeletonList())
          : ListView(padding: EdgeInsets.zero, children: [
              Container(
                color: AppColors.navy,
                padding: EdgeInsets.fromLTRB(8, MediaQuery.of(context).padding.top + 8, 16, 40),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                      onPressed: () => context.canPop() ? context.pop() : context.go(UserRole.admin.homePath),
                    ),
                    const Text('Geofence Configuration',
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
                  ]),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(8, 4, 0, 0),
                    child: Text(
                      'Set the allowed location area for employees to clock in. When they are inside the defined area, the system will verify their location and allow the clock-in.',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Transform.translate(
                  offset: const Offset(0, -24),
                  child: Column(children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.background, borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 3))],
                      ),
                      child: AppDropdown<Workplace>(
                        label: 'Select Workplace', items: list, itemLabel: (w) => w.name, value: _wp,
                        onChanged: (w) {
                          if (w != null) setState(() => _select(w, moveMap: true));
                        },
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 250,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Stack(children: [
                          FlutterMap(
                            mapController: _map,
                            options: MapOptions(
                              initialCenter: _center, initialZoom: 16,
                              onTap: (_, p) => setState(() => _center = p),
                            ),
                            children: [
                              TileLayer(urlTemplate: AppConfig.mapTileUrl, userAgentPackageName: AppConfig.packageName),
                              CircleLayer(circles: [
                                CircleMarker(
                                  point: _center, radius: _radius, useRadiusInMeter: true,
                                  color: AppColors.skyBlue.withOpacity(0.5),
                                  borderColor: AppColors.navy, borderStrokeWidth: 2,
                                ),
                              ]),
                              MarkerLayer(markers: [
                                Marker(
                                  point: _center, width: 44, height: 44, alignment: Alignment.topCenter,
                                  child: const Icon(Icons.location_on, color: AppColors.navy, size: 44),
                                ),
                              ]),
                            ],
                          ),
                          Positioned(
                            left: 10, bottom: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.circular(6)),
                              child: Text('Radius: ${_radius.round()}m', style: const TextStyle(color: Colors.white, fontSize: 12)),
                            ),
                          ),
                          Positioned(
                            right: 8, bottom: 8,
                            child: Column(children: [
                              _zoom(Icons.add, 1),
                              const SizedBox(height: 4),
                              _zoom(Icons.remove, -1),
                            ]),
                          ),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                      decoration: BoxDecoration(
                        color: AppColors.background, borderRadius: BorderRadius.circular(8),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6, offset: const Offset(0, 2))],
                      ),
                      child: Column(children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          const Text('Geofence Radius', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                          Text('${_radius.round()} meters'),
                        ]),
                        Slider(
                          value: _radius, min: 50, max: 500, divisions: 45, activeColor: AppColors.navy,
                          onChanged: (v) => setState(() => _radius = v),
                        ),
                        const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text('50m', style: TextStyle(fontWeight: FontWeight.w500)),
                          Text('500m', style: TextStyle(fontWeight: FontWeight.w500)),
                        ]),
                      ]),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.paleBlue, borderRadius: BorderRadius.circular(6)),
                      child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Icon(Icons.info, color: AppColors.navy),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('How it works', style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.w500)),
                            Text('The system checks the employee’s GPS location and verifies if they are within the defined radius of the workplace.',
                                style: TextStyle(fontSize: 12)),
                          ]),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppColors.greenSoft, borderRadius: BorderRadius.circular(6)),
                      child: const Column(children: [
                        Text('Geofence ready', style: TextStyle(color: AppColors.greenDark, fontWeight: FontWeight.w500)),
                        Text('Tap the map to move the location, then save your changes.',
                            textAlign: TextAlign.center, style: TextStyle(color: AppColors.green, fontSize: 12)),
                      ]),
                    ),
                    const SizedBox(height: 14),
                    PrimaryButton(label: 'Save Geofence', onPressed: _save, loading: _saving),
                    const SizedBox(height: 16),
                  ]),
                ),
              ),
            ]),
    );
  }

  Widget _zoom(IconData icon, double delta) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        elevation: 2,
        child: InkWell(
          onTap: () => _map.move(_map.camera.center, _map.camera.zoom + delta),
          child: SizedBox(width: 38, height: 38, child: Icon(icon)),
        ),
      );
}
