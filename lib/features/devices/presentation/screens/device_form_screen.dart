import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/l10n_x.dart';
import '../../../../shared/utils/validators.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/content_width.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../domain/device.dart';
import '../providers/devices_controller.dart';
import '../widgets/device_x.dart';

/// Sirve para crear (deviceId == null) y para editar.
class DeviceFormScreen extends ConsumerStatefulWidget {
  final String? deviceId;
  const DeviceFormScreen({super.key, this.deviceId});

  @override
  ConsumerState<DeviceFormScreen> createState() => _DeviceFormScreenState();
}

class _DeviceFormScreenState extends ConsumerState<DeviceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _location;
  late final TextEditingController _threshold;
  late final TextEditingController _lat;
  late final TextEditingController _lng;
  late DeviceType _type;
  late DeviceStatus _status;
  Device? _existing;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final id = widget.deviceId;
    if (id != null) {
      final list = ref.read(devicesControllerProvider).value ?? <Device>[];
      _existing = list.where((d) => d.id == id).firstOrNull;
    }
    _name = TextEditingController(text: _existing?.name ?? '');
    _location = TextEditingController(text: _existing?.location ?? '');
    _threshold =
        TextEditingController(text: (_existing?.threshold ?? 80).toString());
    _lat = TextEditingController(text: _existing?.latitude?.toString() ?? '');
    _lng = TextEditingController(text: _existing?.longitude?.toString() ?? '');
    _type = _existing?.type ?? DeviceType.sensor;
    _status = _existing?.status ?? DeviceStatus.online;
  }

  @override
  void dispose() {
    _name.dispose();
    _location.dispose();
    _threshold.dispose();
    _lat.dispose();
    _lng.dispose();
    super.dispose();
  }

  double? _parseCoord(String s) {
    final t = s.trim();
    if (t.isEmpty) return null;
    return double.tryParse(t.replaceAll(',', '.'));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    // La ubicación solo se guarda si hay latitud Y longitud.
    final lat = _parseCoord(_lat.text);
    final lng = _parseCoord(_lng.text);
    final hasLocation = lat != null && lng != null;

    final device = Device(
      id: _existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      name: _name.text.trim(),
      location: _location.text.trim(),
      type: _type,
      status: _status,
      threshold: double.parse(_threshold.text.trim().replaceAll(',', '.')),
      latitude: hasLocation ? lat : null,
      longitude: hasLocation ? lng : null,
    );

    await ref.read(devicesControllerProvider.notifier).save(device);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.l10n.saved)));
    context.pop();
  }

  Future<void> _delete() async {
    final l = context.l10n;
    final ok = await showConfirmDialog(
      context,
      title: l.deleteTitle,
      message: l.deleteConfirm(_existing!.name),
    );
    if (!ok) return;
    await ref.read(devicesControllerProvider.notifier).delete(_existing!.id);
    if (!mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    const coordKeyboard =
        TextInputType.numberWithOptions(decimal: true, signed: true);

    return Scaffold(
      appBar: AppBar(
        title: Text(_existing == null ? l.addDevice : l.editDevice),
        actions: [
          if (_existing != null)
            IconButton(
              tooltip: l.delete,
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
        ],
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
                  label: l.deviceName,
                  icon: Icons.label_outline,
                  validator: Validators.required(context),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _location,
                  label: l.deviceLocation,
                  icon: Icons.place_outlined,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<DeviceType>(
                  initialValue: _type,
                  decoration: InputDecoration(labelText: l.deviceType),
                  items: [
                    for (final t in DeviceType.values)
                      DropdownMenuItem(value: t, child: Text(t.label(l))),
                  ],
                  onChanged: (v) => setState(() => _type = v ?? _type),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<DeviceStatus>(
                  initialValue: _status,
                  decoration: InputDecoration(labelText: l.deviceStatus),
                  items: [
                    for (final s in DeviceStatus.values)
                      DropdownMenuItem(value: s, child: Text(s.label(l))),
                  ],
                  onChanged: (v) => setState(() => _status = v ?? _status),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _threshold,
                  label: l.deviceThreshold,
                  icon: Icons.speed_outlined,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: Validators.number(context),
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
                        validator: Validators.coordinate(context, max: 90),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        controller: _lng,
                        label: l.deviceLongitude,
                        icon: Icons.explore_outlined,
                        keyboardType: coordKeyboard,
                        validator: Validators.coordinate(context, max: 180),
                      ),
                    ),
                  ],
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
