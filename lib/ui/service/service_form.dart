import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../l10n/app_localizations.dart';
import '../../state/settings_controller.dart';
import '../../data/models/service_entry.dart';
import '../../data/models/vehicle.dart';
import '../../data/repo/service_repo.dart';
import '../../state/active_vehicle_controller.dart';
import 'service_form_controller.dart';

class ServiceForm extends StatefulWidget {
  final ServiceEntry? initial;
  final String? vehicleId;
  final SettingsController settings;

  const ServiceForm.add({super.key, required this.vehicleId, required this.settings}) : initial = null;
  const ServiceForm.edit({super.key, required this.initial, required this.settings}) : vehicleId = null;

  @override
  State<ServiceForm> createState() => _ServiceFormState();
}

class _ServiceFormState extends State<ServiceForm> {
  late final ServiceFormController c;
  late String _currencyCode;
  late DateTime _date;
  final _formKey = GlobalKey<FormState>();
  String? _selectedVehicleId;

  @override
  void initState() {
    super.initState();
    c = ServiceFormController();
    _currencyCode = widget.initial?.currencyCode ?? widget.settings.currencyCode;
    _date = widget.initial?.date ?? DateTime.now();

    // Initialize selected vehicle
    if (widget.initial != null) {
      _selectedVehicleId = widget.initial!.vehicleId;
    } else {
      _selectedVehicleId = widget.vehicleId;
    }

    if (widget.initial != null) {
      final e = widget.initial!;
      c
        ..setOdometerKm(e.odometerKm)
        ..setDescription(e.description)
        ..setTotalAmount(e.totalAmount)
        ..setDate(e.date)
        ..setNotes(e.notes);
      c.odoController.text = e.odometerKm.toStringAsFixed(1);
      c.descriptionController.text = e.description;
      c.amountController.text = e.totalAmount.toStringAsFixed(2);
      if (e.notes != null) c.notesController.text = e.notes!;
    }
    c.addListener(() {
      if (mounted) setState(() {});
    });

    // Format on blur listeners
    c.odoFocus.addListener(() {
      if (!c.odoFocus.hasFocus) _formatOnBlurOdo();
    });
    c.amountFocus.addListener(() {
      if (!c.amountFocus.hasFocus) _formatOnBlurAmount();
    });
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  void _formatOnBlurOdo() {
    final v = _parse(c.odoController.text);
    if (v != null) c.writeKeepingCaret(c.odoController, v.toStringAsFixed(1));
  }

  void _formatOnBlurAmount() {
    final v = _parse(c.amountController.text);
    if (v != null) c.writeKeepingCaret(c.amountController, v.toStringAsFixed(2));
  }

  double? _parse(String? s) {
    if (s == null) return null;
    final t = s.trim();
    if (t.isEmpty) return null;
    final normalized = t.replaceAll(',', '.');
    final v = double.tryParse(normalized);
    if (v == null || v.isNaN) return null;
    return v;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final initialDate = _date.isAfter(today) ? today : _date;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000, 1, 1),
      lastDate: today,
    );

    if (picked != null) {
      setState(() {
        _date = picked;
        c.setDate(picked);
      });
    }
  }

  String? _validateDate(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = DateTime(d.year, d.month, d.day);
    if (picked.isAfter(today)) {
      final l10n = AppLocalizations.of(context)!;
      return l10n.errorFutureDateNotAllowed;
    }
    return null;
  }

  String? _validateOdometer(String? s, BuildContext context) {
    final v = _parse(s);
    if (v == null || v < 0) {
      final l10n = AppLocalizations.of(context)!;
      return '${l10n.serviceOdometer}: required, ≥ 0';
    }
    return null;
  }

  String? _validateDescription(String? s, BuildContext context) {
    if (s == null || s.trim().isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      return l10n.validationRequired;
    }
    return null;
  }

  String? _validateAmount(String? s, BuildContext context) {
    final v = _parse(s);
    if (v == null || v < 0) {
      final l10n = AppLocalizations.of(context)!;
      return '${l10n.serviceAmount}: required, ≥ 0';
    }
    return null;
  }

  Future<void> _save() async {
    // Validate date first (inline will show via InputDecorator if we had errorText)
    final dateError = _validateDate(_date);
    if (dateError != null) {
      // Για την ημερομηνία δείχνουμε SnackBar επειδή δεν έχουμε TextFormField validator εκεί
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(dateError)));
      return;
    }

    if (!_formKey.currentState!.validate()) {
      // Inline errors θα φανούν στα TextFormFields
      return;
    }

    final repo = ServiceRepo();
    
    // Use selected vehicle, fallback to widget vehicleId, then active vehicle
    final vehicleId = _selectedVehicleId ?? widget.initial?.vehicleId ?? widget.vehicleId ?? await ActiveVehicleController().getActiveVehicleId();
    
    final entry = ServiceEntry(
      id: widget.initial?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      vehicleId: vehicleId,
      date: _date,
      odometerKm: c.odometerKm!,
      description: c.description!,
      totalAmount: c.totalAmount!,
      notes: c.notes,
      invoicePhotoPath: widget.initial?.invoicePhotoPath,
      currencyCode: _currencyCode,
    );

    if (widget.initial != null) {
      await repo.update(entry);
    } else {
      await repo.add(entry);
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEdit = widget.initial != null;
    final vehiclesBox = Hive.box<Vehicle>('vehicles');
    final vehicles = vehiclesBox.values.where((v) => v.active).toList();

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEdit ? l10n.editService : l10n.addService,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              
              // Vehicle selector
              if (vehicles.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: _selectedVehicleId,
                  decoration: InputDecoration(
                    labelText: l10n.filterVehicle,
                    border: const OutlineInputBorder(),
                  ),
                  items: vehicles.map((vehicle) {
                    return DropdownMenuItem<String>(
                      value: vehicle.id,
                      child: Text(vehicle.title),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedVehicleId = value);
                    }
                  },
                ),
              if (vehicles.isNotEmpty) const SizedBox(height: 12),
              
              // Date picker
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: l10n.serviceDate,
                    border: const OutlineInputBorder(),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${_date.day}/${_date.month}/${_date.year}'),
                      const Icon(Icons.calendar_today, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Odometer
              TextFormField(
                controller: c.odoController,
                focusNode: c.odoFocus,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d{0,7}([.,]\d{0,1})?$')),
                ],
                decoration: InputDecoration(
                  labelText: l10n.serviceOdometer,
                  border: const OutlineInputBorder(),
                ),
                validator: (s) => _validateOdometer(s, context),
                onChanged: (s) => c.setOdometerKm(_parse(s)),
              ),
              const SizedBox(height: 12),

              // Description
              TextFormField(
                controller: c.descriptionController,
                focusNode: c.descriptionFocus,
                decoration: InputDecoration(
                  labelText: l10n.serviceDescription,
                  border: const OutlineInputBorder(),
                ),
                validator: (s) => _validateDescription(s, context),
                onChanged: (s) => c.setDescription(s),
              ),
              const SizedBox(height: 12),

              // Amount and Currency
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: c.amountController,
                      focusNode: c.amountFocus,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d{0,6}([.,]\d{0,2})?$')),
                      ],
                      decoration: InputDecoration(
                        labelText: l10n.serviceAmount,
                        border: const OutlineInputBorder(),
                      ),
                      validator: (s) => _validateAmount(s, context),
                      onChanged: (s) => c.setTotalAmount(_parse(s)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _currencyCode,
                      decoration: InputDecoration(
                        labelText: l10n.currency,
                        border: const OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                        DropdownMenuItem(value: 'USD', child: Text('USD')),
                        DropdownMenuItem(value: 'GBP', child: Text('GBP')),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          setState(() {
                            _currencyCode = v;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Notes
              TextFormField(
                controller: c.notesController,
                focusNode: c.notesFocus,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: l10n.serviceNotes,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (s) => c.setNotes(s),
              ),
              const SizedBox(height: 20),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.cancel),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _save,
                    child: Text(l10n.save),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
