import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../widgets/currency_picker_field.dart';
import '../../l10n/app_localizations.dart';
import '../../state/settings_controller.dart';

import '../../data/models/fuel_entry.dart';
import '../../utils/id_generator.dart';
import '../../data/models/vehicle.dart';
import '../../data/repo/fuel_repo.dart';
import '../../state/active_vehicle_controller.dart';
import 'fuel_form_controller.dart';

class FuelForm extends StatefulWidget {
  final FuelEntry? initial;
  final String? vehicleId;
  final SettingsController settings;

  const FuelForm.add({super.key, required this.vehicleId, required this.settings}) : initial = null;
  const FuelForm.edit({super.key, required this.initial, required this.settings}) : vehicleId = null;

  @override
  State<FuelForm> createState() => _FuelFormState();
}

class _FuelFormState extends State<FuelForm> {
  late final FuelFormController c;
  late String _currencyCode;
  late DateTime _date;
  String? _selectedVehicleId;

  @override
  void initState() {
    super.initState();
    c = FuelFormController();
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
        ..setLiters(e.liters)
        ..setPricePerLiter(e.pricePerLiter)
        ..setAmount(e.amount)
        ..setFullTank(e.fullTank)
        ..setDate(e.date)
        ..setNotes(e.notes);
      c.litersController.text = e.liters.toStringAsFixed(2);
      c.priceController.text = e.pricePerLiter.toStringAsFixed(3);
      c.amountController.text = e.amount.toStringAsFixed(2);
      c.odoController.text = e.odometerKm.toStringAsFixed(1);
    }
    c.addListener(() { if (mounted) setState(() {}); });

    // Format on blur listeners
    c.litersFocus.addListener(() { if (!c.litersFocus.hasFocus) _formatOnBlurLiters(); });
    c.priceFocus.addListener(() { if (!c.priceFocus.hasFocus) _formatOnBlurPrice(); });
    c.amountFocus.addListener(() { if (!c.amountFocus.hasFocus) _formatOnBlurAmount(); });
    c.odoFocus.addListener(() { if (!c.odoFocus.hasFocus) _formatOnBlurOdo(); });
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  void _formatOnBlurLiters() {
    final v = _parse(c.litersController.text);
    if (v != null) c.writeKeepingCaret(c.litersController, v.toStringAsFixed(2));
  }

  void _formatOnBlurPrice() {
    final v = _parse(c.priceController.text);
    if (v != null) c.writeKeepingCaret(c.priceController, v.toStringAsFixed(3));
  }

  void _formatOnBlurAmount() {
    final v = _parse(c.amountController.text);
    if (v != null) c.writeKeepingCaret(c.amountController, v.toStringAsFixed(2));
  }

  void _formatOnBlurOdo() {
    final v = _parse(c.odoController.text);
    if (v != null) c.writeKeepingCaret(c.odoController, v.toStringAsFixed(1));
  }

  // κρατήθηκε από προηγούμενη έκδοση, αλλά δεν χρησιμοποιείται πλέον
  // String _format(double? v) => v == null ? '' : v.toStringAsFixed(2);

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final vehiclesBox = Hive.box<Vehicle>('vehicles');
    final vehicles = vehiclesBox.values.where((v) => v.active).toList();
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.initial == null ? l10n.addFuelTitle : l10n.editFuelTitle, style: Theme.of(context).textTheme.titleLarge),
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
            if (vehicles.isNotEmpty) const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: c.litersController,
                  focusNode: c.litersFocus,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d{0,5}([.,]\d{0,2})?$'))],
                  decoration: InputDecoration(labelText: l10n.liters),
                  onChanged: (s) { c.setEditing(EditingField.liters); c.setLiters(_parse(s)); },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: c.priceController,
                  focusNode: c.priceFocus,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}([.,]\d{0,3})?$'))],
                  decoration: InputDecoration(
                    labelText: l10n.pricePerLiter,
                    suffixText: '$_currencyCode / L',
                  ),
                  onChanged: (s) { c.setEditing(EditingField.pricePerLiter); c.setPricePerLiter(_parse(s)); },
                ),
              ),
            ]),
            const SizedBox(height: 12),
            TextField(
              controller: c.amountController,
              focusNode: c.amountFocus,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d{0,6}([.,]\d{0,2})?$'))],
              decoration: InputDecoration(
                labelText: l10n.amount,
                suffixText: _currencyCode,
              ),
              onChanged: (s) { c.setEditing(EditingField.amount); c.setAmount(_parse(s)); },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: c.odoController,
              focusNode: c.odoFocus,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d{0,7}([.,]\d{0,1})?$'))],
              decoration: InputDecoration(labelText: AppLocalizations.of(context)!.odometerKm),
            ),
            const SizedBox(height: 12),
            CurrencyPickerField(
              value: _currencyCode,
              onChanged: (v) => setState(() => _currencyCode = v),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.date_range),
                    label: Text(_date.toLocal().toString().split(' ').first),
                    onPressed: _pickDate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    children: [
                      Text(l10n.fullTank),
                      const SizedBox(width: 8),
                      Switch(value: c.fullTank, onChanged: (v) => setState(() => c.setFullTank(v))),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              maxLines: 2,
              decoration: InputDecoration(labelText: l10n.notes),
              onChanged: (s) => c.setNotes(s.isEmpty ? null : s),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: Text(l10n.cancel),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  icon: const Icon(Icons.check),
                  label: Text(l10n.save),
                  onPressed: _onSubmit,
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _onSubmit() async {
    // Προαιρετικό: κάνε format on-blur πριν το save ώστε το UI να δείχνει καθαρά
    _formatOnBlurLiters();
    _formatOnBlurPrice();
    _formatOnBlurAmount();
    _formatOnBlurOdo();

    // Validation 1: χρειαζόμαστε και τα 3 υπολογισμένα τελικά
    if (c.liters == null || c.pricePerLiter == null || c.amount == null) {
      _showSnack('Συμπλήρωσε 2 από τα 3 πεδία για να υπολογιστεί το τρίτο.');
      return;
    }

    // Validation 2: δεν επιτρέπονται μελλοντικές ημερομηνίες
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final chosen = DateTime(_date.year, _date.month, _date.day);
    if (chosen.isAfter(todayDate)) {
      _showSnack('Δεν επιτρέπεται μελλοντική ημερομηνία.');
      return;
    }

    // Validation 3: odometerKm >= 0
  final odo = _parse(c.odoController.text) ?? 0;
    if (odo < 0) {
      _showSnack('Μη έγκυρη τιμή χιλιομέτρων');
      return;
    }

    final repo = FuelRepo();
  final id = widget.initial?.id ?? generateId();

    // Use selected vehicle, fallback to widget vehicleId, then active vehicle
    final vehicleId = _selectedVehicleId ?? widget.initial?.vehicleId ?? widget.vehicleId ?? await ActiveVehicleController().getActiveVehicleId();

    final entry = FuelEntry(
      id: id,
      vehicleId: vehicleId,
      date: _date,
      odometerKm: odo,
      liters: c.liters!,
      pricePerLiter: c.pricePerLiter!,
      amount: c.amount!,
      fullTank: c.fullTank,
      notes: c.notes,
      currencyCode: _currencyCode,
    );

    if (widget.initial == null) {
      await repo.add(entry);
    } else {
      await repo.update(entry);
    }

    if (mounted) Navigator.of(context).maybePop();
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
