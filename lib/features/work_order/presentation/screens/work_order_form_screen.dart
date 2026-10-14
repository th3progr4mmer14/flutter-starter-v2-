import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/l10n_x.dart';
import '../../../../shared/utils/validators.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/content_width.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../domain/work_order_item.dart';
import '../providers/work_order_controller.dart';

/// Sirve para crear (itemId == null) y para editar.
class WorkOrderFormScreen extends ConsumerStatefulWidget {
  final String? itemId;
  const WorkOrderFormScreen({super.key, this.itemId});

  @override
  ConsumerState<WorkOrderFormScreen> createState() =>
      _WorkOrderFormScreenState();
}

class _WorkOrderFormScreenState extends ConsumerState<WorkOrderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _notes;
  WorkOrderItem? _existing;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final id = widget.itemId;
    if (id != null) {
      final list =
          ref.read(workOrderControllerProvider).value ?? <WorkOrderItem>[];
      _existing = list.where((i) => i.id == id).firstOrNull;
    }
    _name = TextEditingController(text: _existing?.name ?? '');
    _notes = TextEditingController(text: _existing?.notes ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final item = WorkOrderItem(
      id: _existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      name: _name.text.trim(),
      notes: _notes.text.trim(),
    );

    await ref.read(workOrderControllerProvider.notifier).save(item);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.l10n.saved)));
    context.pop();
  }

  Future<void> _delete() async {
    final l = context.l10n;
    final ok = await showConfirmDialog(
      context,
      title: l.workOrderDeleteTitle,
      message: l.deleteConfirm(_existing!.name),
    );
    if (!ok) return;
    await ref.read(workOrderControllerProvider.notifier).delete(_existing!.id);
    if (!mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(_existing == null ? l.workOrderAdd : l.workOrderEdit),
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
                  label: l.workOrderName,
                  icon: Icons.label_outline,
                  validator: Validators.required(context),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _notes,
                  label: l.workOrderNotes,
                  icon: Icons.notes_outlined,
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
