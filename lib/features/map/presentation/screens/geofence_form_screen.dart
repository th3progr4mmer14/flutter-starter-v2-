import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../l10n/l10n_x.dart';
import '../../../../shared/utils/validators.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/content_width.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../devices/domain/device.dart';
import '../../../devices/presentation/providers/devices_controller.dart';
import '../../domain/geofence.dart';
import '../../map_defaults.dart';
import '../providers/geofences_controller.dart';
import '../widgets/geofence_x.dart';

/// Crear (geofenceId == null) o editar una geocerca.
/// [initialPoint] viene de la pulsación larga en el mapa.
class GeofenceFormScreen extends ConsumerStatefulWidget {
  final String? geofenceId;
  final LatLng? initialPoint;

  const GeofenceFormScreen({super.key, this.geofenceId, this.initialPoint});

  @override
  ConsumerState<GeofenceFormScreen> createState() => _GeofenceFormScreenState();
}

class _GeofenceFormScreenState extends ConsumerState<GeofenceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _radius;
  late final TextEditingController _lat;
  late final TextEditingController _lng;
  late GeofenceTrigger _trigger;
  String? _deviceId;
  Geofence? _existing;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final id = widget.geofenceId;
    if (id != null) {
      final list = ref.read(geofencesControllerProvider).value ?? <Geofence>[];
      _existing = list.where((g) => g.id == id).firstOrNull;
    }

    final lat = _existing?.latitude ??
        widget.initialPoint?.latitude ??
        MapDefaults.center.latitude;
    final lng = _existing?.longitude ??
        widget.initialPoint?.longitude ??
        MapDefaults.center.longitude;

    _name = TextEditingController(text: _existing?.name ?? '');
    _radius = TextEditingController(
        text: (_existing?.radiusMeters ?? 500).toStringAsFixed(0));
    _lat = TextEditingController(text: lat.toStringAsFixed(6));
    _lng = TextEditingController(text: lng.toStringAsFixed(6));
    _trigger = _existing?.trigger ?? GeofenceTrigger.exit;
    _deviceId = _existing?.deviceId;
  }

  @override
  void dispose() {
    _name.dispose();
    _radius.dispose();
    _lat.dispose();
    _lng.dispose();
    super.dispose();
  }

  double _parse(String s) => double.parse(s.trim().replaceAll(',', '.'));

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final geofence = Geofence(
      id: _existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      name: _name.text.trim(),
      latitude: _parse(_lat.text),
      longitude: _parse(_lng.text),
      radiusMeters: _parse(_radius.text),
      trigger: _trigger,
      deviceId: _deviceId,
    );

    await ref.read(geofencesControllerProvider.notifier).save(geofence);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.l10n.saved)));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final devices = ref.watch(devicesControllerProvider).value ?? <Device>[];
    // Si el dispositivo elegido ya no existe, vuelve a "todos".
    final deviceValue = devices.any((d) => d.id == _deviceId) ? _deviceId : null;

    String? requiredCoordinate(String? v, double max) {
      final r = Validators.required(context)(v);
      return r ?? Validators.coordinate(context, max: max)(v);
    }

    const coordKeyboard =
        TextInputType.numberWithOptions(decimal: true, signed: true);

    return Scaffold(
      appBar: AppBar(
        title: Text(_existing == null ? l.addGeofence : l.editGeofence),
      ),
      body: ContentWidth(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  controller: _name,
                  label: l.geofenceName,
                  icon: Icons.label_outline,
                  validator: Validators.required(context),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _radius,
                  label: l.geofenceRadius,
                  icon: Icons.radio_button_unchecked,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: Validators.positiveNumber(context),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _lat,
                        label: l.deviceLatitude,
                        icon: Icons.my_location_outlined,
                        keyboardType: coordKeyboard,
                        validator: (v) => requiredCoordinate(v, 90),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        controller: _lng,
                        label: l.deviceLongitude,
                        icon: Icons.explore_outlined,
                        keyboardType: coordKeyboard,
                        validator: (v) => requiredCoordinate(v, 180),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<GeofenceTrigger>(
                  initialValue: _trigger,
                  decoration: InputDecoration(labelText: l.geofenceTrigger),
                  items: [
                    for (final t in GeofenceTrigger.values)
                      DropdownMenuItem(value: t, child: Text(t.label(l))),
                  ],
                  onChanged: (v) => setState(() => _trigger = v ?? _trigger),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String?>(
                  initialValue: deviceValue,
                  decoration: InputDecoration(labelText: l.geofenceDevice),
                  items: [
                    DropdownMenuItem<String?>(
                        value: null, child: Text(l.allDevices)),
                    for (final d in devices)
                      DropdownMenuItem<String?>(value: d.id, child: Text(d.name)),
                  ],
                  onChanged: (v) => setState(() => _deviceId = v),
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: l.save,
                  isLoading: _saving,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
