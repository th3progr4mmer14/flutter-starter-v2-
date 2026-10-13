import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../l10n/l10n_x.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../devices/domain/device.dart';
import '../../../devices/presentation/providers/devices_controller.dart';
import '../../../devices/presentation/widgets/device_x.dart';
import '../../domain/geofence.dart';
import '../../map_defaults.dart';
import '../providers/geofences_controller.dart';
import '../providers/live_locations_provider.dart';
import '../providers/my_location_controller.dart';
import '../providers/trails_controller.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final _controller = MapController();
  bool _mapReady = false;
  bool _showTrails = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _fitAll(List<LatLng> points) {
    if (points.isEmpty) return;
    if (points.length == 1) {
      _controller.move(points.first, 15);
      return;
    }
    _controller.fitCamera(
      CameraFit.coordinates(
        coordinates: points,
        padding: const EdgeInsets.all(64),
      ),
    );
  }

  String _formatDistance(double meters) => meters < 1000
      ? '${meters.round()} m'
      : '${(meters / 1000).toStringAsFixed(1)} km';

  void _showDevice(Device d, LatLng pos, LatLng? me) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        final l = ctx.l10n;
        final theme = Theme.of(ctx);
        final distanceText = me == null
            ? null
            : l.distanceFromYou(
                _formatDistance(const Distance().distance(me, pos)));

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(child: Icon(d.type.icon)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(d.name, style: theme.textTheme.titleMedium),
                    ),
                    StatusChip(status: d.status),
                  ],
                ),
                const SizedBox(height: 12),
                Text('${d.location} · ${d.type.label(l)}'),
                const SizedBox(height: 4),
                Text(
                  '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}',
                  style: theme.textTheme.bodySmall,
                ),
                if (distanceText != null) ...[
                  const SizedBox(height: 4),
                  Text(distanceText, style: theme.textTheme.bodySmall),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.center_focus_strong),
                        label: Text(l.centerOnMap),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          _controller.move(pos, 16);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.edit_outlined),
                        label: Text(l.editDevice),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          context.push(AppRoutes.deviceEdit(d.id));
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);

    // Avisos de permisos y centrado en la primera lectura de "mi ubicación".
    ref.listen<MyLocationState>(myLocationControllerProvider, (prev, next) {
      if (prev?.status != next.status) {
        final msg = switch (next.status) {
          MyLocationStatus.serviceDisabled => l.locationServiceOff,
          MyLocationStatus.denied => l.locationDenied,
          MyLocationStatus.deniedForever => l.locationDeniedForever,
          _ => null,
        };
        if (msg != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        }
      }
      final p = next.position;
      if (prev?.position == null && p != null && _mapReady) {
        _controller.move(p, 16);
      }
    });

    final devicesAsync = ref.watch(devicesControllerProvider);
    final located = (devicesAsync.value ?? <Device>[])
        .where((d) => d.hasLocation)
        .toList();
    final positions =
        ref.watch(liveLocationsProvider).value ?? <String, LatLng>{};
    final geofences =
        ref.watch(geofencesControllerProvider).value ?? <Geofence>[];
    final trails = ref.watch(trailsControllerProvider);
    final me = ref.watch(myLocationControllerProvider);

    final visible = located.where((d) => positions.containsKey(d.id)).toList();
    final points = [for (final d in visible) positions[d.id]!];
    final showMap = visible.isNotEmpty;

    Widget body;
    if (devicesAsync.isLoading && located.isEmpty) {
      body = const Center(child: CircularProgressIndicator());
    } else if (located.isEmpty) {
      body = EmptyState(
        icon: Icons.location_off_outlined,
        title: l.noLocatedDevices,
        subtitle: l.noLocatedDevicesHint,
      );
    } else if (!showMap) {
      body = const Center(child: CircularProgressIndicator());
    } else {
      body = FlutterMap(
        mapController: _controller,
        options: MapOptions(
          initialCenter: points.length == 1 ? points.first : MapDefaults.center,
          initialZoom: points.length == 1 ? 15 : MapDefaults.zoom,
          initialCameraFit: points.length > 1
              ? CameraFit.coordinates(
                  coordinates: points,
                  padding: const EdgeInsets.all(64),
                )
              : null,
          minZoom: 2,
          maxZoom: 19,
          onMapReady: () => _mapReady = true,
          // Pulsación larga = crear una geocerca en ese punto.
          onLongPress: (_, point) =>
              context.push(AppRoutes.geofenceNew, extra: point),
        ),
        children: [
          TileLayer(
            urlTemplate: MapDefaults.tileUrl,
            userAgentPackageName: MapDefaults.userAgentPackage,
          ),
          // Geocercas
          CircleLayer(
            circles: [
              for (final g in geofences)
                CircleMarker(
                  point: LatLng(g.latitude, g.longitude),
                  radius: g.radiusMeters,
                  useRadiusInMeter: true,
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderColor: theme.colorScheme.primary,
                  borderStrokeWidth: 2,
                ),
            ],
          ),
          // Recorridos
          if (_showTrails)
            PolylineLayer(
              polylines: [
                for (final d in visible)
                  if ((trails[d.id]?.length ?? 0) > 1)
                    Polyline(
                      points: trails[d.id]!,
                      strokeWidth: 3,
                      color: d.status.color.withValues(alpha: 0.8),
                    ),
              ],
            ),
          // Dispositivos
          MarkerLayer(
            markers: [
              for (final d in visible)
                Marker(
                  point: positions[d.id]!,
                  width: 48,
                  height: 48,
                  alignment: Alignment.topCenter,
                  child: GestureDetector(
                    onTap: () =>
                        _showDevice(d, positions[d.id]!, me.position),
                    child: Icon(Icons.location_on,
                        size: 44, color: d.status.color),
                  ),
                ),
            ],
          ),
          // Mi ubicación
          if (me.position != null)
            MarkerLayer(
              markers: [
                Marker(
                  point: me.position!,
                  width: 28,
                  height: 28,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: const [
                        BoxShadow(blurRadius: 6, color: Colors.black26),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          const RichAttributionWidget(
            attributions: [
              TextSourceAttribution('© OpenStreetMap contributors'),
            ],
          ),
        ],
      );
    }

    final meActive = me.status == MyLocationStatus.on ||
        me.status == MyLocationStatus.loading;

    return AppScaffold(
      title: l.navMap,
      currentRoute: AppRoutes.map,
      floatingActionButton: showMap
          ? FloatingActionButton(
              tooltip: l.myLocation,
              onPressed: () {
                if (me.status == MyLocationStatus.loading) return;
                if (me.status == MyLocationStatus.on && me.position != null) {
                  _controller.move(me.position!, 16);
                } else {
                  ref.read(myLocationControllerProvider.notifier).start();
                }
              },
              child: me.status == MyLocationStatus.loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : Icon(me.status == MyLocationStatus.on
                      ? Icons.my_location
                      : Icons.location_searching),
            )
          : null,
      actions: [
        IconButton(
          tooltip: l.fitAll,
          icon: const Icon(Icons.zoom_out_map),
          onPressed: points.isEmpty ? null : () => _fitAll(points),
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'me':
                ref.read(myLocationControllerProvider.notifier).toggle();
              case 'trails':
                setState(() => _showTrails = !_showTrails);
              case 'clear':
                ref.read(trailsControllerProvider.notifier).clear();
              case 'geofences':
                context.push(AppRoutes.geofences);
            }
          },
          itemBuilder: (_) => <PopupMenuEntry<String>>[
            CheckedPopupMenuItem<String>(
              value: 'me',
              checked: meActive,
              child: Text(l.myLocation),
            ),
            CheckedPopupMenuItem<String>(
              value: 'trails',
              checked: _showTrails,
              child: Text(l.showTrails),
            ),
            PopupMenuItem<String>(value: 'clear', child: Text(l.clearTrails)),
            PopupMenuItem<String>(
                value: 'geofences', child: Text(l.geofences)),
          ],
        ),
      ],
      body: body,
    );
  }
}
