import 'package:flutter/material.dart';
import 'package:fuel_service_log/data/models/vehicle.dart';
import 'package:fuel_service_log/l10n/app_localizations.dart';

/// Dialog for adding or editing a vehicle
class VehicleFormDialog extends StatefulWidget {
  final Vehicle? vehicle; // null for add, non-null for edit

  const VehicleFormDialog({super.key, this.vehicle});

  @override
  State<VehicleFormDialog> createState() => _VehicleFormDialogState();
}

class _VehicleFormDialogState extends State<VehicleFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _plateController;
  late TextEditingController _currencyController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.vehicle?.title ?? '');
    _plateController = TextEditingController(text: widget.vehicle?.plate ?? '');
    _currencyController = TextEditingController(text: widget.vehicle?.currencyCode ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _plateController.dispose();
    _currencyController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    final l10n = AppLocalizations.of(context)!;
    if (value == null || value.trim().isEmpty) {
      return l10n.error_required;
    }
    if (value.trim().length < 2) {
      return l10n.error_required; // Could add a specific "min 2 chars" error
    }
    return null;
  }

  String? _validateCurrency(String? value) {
    final l10n = AppLocalizations.of(context)!;
    if (value == null || value.trim().isEmpty) {
      return l10n.error_required;
    }
    final trimmed = value.trim().toUpperCase();
    if (trimmed.length != 3) {
      return l10n.error_currency3;
    }
    // Basic ISO 4217 validation (3 uppercase letters)
    if (!RegExp(r'^[A-Z]{3}$').hasMatch(trimmed)) {
      return l10n.error_currency3;
    }
    return null;
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final vehicle = Vehicle(
        id: widget.vehicle?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: _nameController.text.trim(),
        plate: _plateController.text.trim().isEmpty ? null : _plateController.text.trim(),
        currencyCode: _currencyController.text.trim().toUpperCase(),
        active: widget.vehicle?.active ?? true,
      );
      Navigator.of(context).pop(vehicle);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEdit = widget.vehicle != null;

    return AlertDialog(
      title: Text(isEdit ? l10n.vehicle_edit : l10n.vehicle_add),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.vehicle_name,
                border: const OutlineInputBorder(),
              ),
              validator: _validateName,
              autofocus: !isEdit,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _plateController,
              decoration: InputDecoration(
                labelText: '${l10n.vehicle_plate} (${l10n.optional})',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _currencyController,
              decoration: InputDecoration(
                labelText: l10n.vehicle_currency,
                border: const OutlineInputBorder(),
                hintText: 'EUR',
              ),
              validator: _validateCurrency,
              textCapitalization: TextCapitalization.characters,
              maxLength: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.vehicle_cancel),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(l10n.vehicle_save),
        ),
      ],
    );
  }
}
