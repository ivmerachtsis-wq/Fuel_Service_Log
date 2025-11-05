import 'package:flutter/material.dart';

import '../../data/models/fuel_entry.dart';
import '../../data/repo/fuel_repo.dart';
import '../../state/active_vehicle_controller.dart';
import 'fuel_form_controller.dart';

class FuelForm extends StatefulWidget {
  final FuelEntry? initial;
  final String? vehicleId;

  const FuelForm.add({super.key, required this.vehicleId}) : initial = null;
  const FuelForm.edit({super.key, required this.initial}) : vehicleId = null;

  @override
  State<FuelForm> createState() => _FuelFormState();
}

class _FuelFormState extends State<FuelForm> {
  late final FuelFormController c;
  final _litersCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  bool _programmatic = false;

  @override
  void initState() {
    super.initState();
    c = FuelFormController();
    if (widget.initial != null) {
      final e = widget.initial!;
      c
        ..setLiters(e.liters)
        ..setPricePerLiter(e.pricePerLiter)
        ..setAmount(e.amount)
        ..setFullTank(e.fullTank)
        ..setDate(e.date)
        ..setNotes(e.notes);
      _syncTextFields();
    }
    c.addListener(_syncTextFields);
  }

  @override
  void dispose() {
    c.removeListener(_syncTextFields);
    _litersCtrl.dispose();
    _priceCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  void _syncTextFields() {
    if (!mounted) return;
    _programmatic = true;
    _litersCtrl.text = _format(c.liters);
    _priceCtrl.text = _format(c.pricePerLiter);
    _amountCtrl.text = _format(c.amount);
    _programmatic = false;
    setState(() {});
  }

  String _format(double? v) => v == null ? '' : v.toStringAsFixed(2);

  double? _parse(String s) {
    final t = s.replaceAll(',', '.');
    final d = double.tryParse(t);
    if (d == null) return null;
    if (d.isNaN || d <= 0) return null;
    return d;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.initial == null ? 'Add Fuel' : 'Edit Fuel', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _litersCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Liters'),
                  onChanged: (s) { if (_programmatic) return; c.setLiters(_parse(s)); },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _priceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Price / L (\u20AC)'),
                  onChanged: (s) { if (_programmatic) return; c.setPricePerLiter(_parse(s)); },
                ),
              ),
            ]),
            const SizedBox(height: 12),
            TextField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Amount (\u20AC)'),
              onChanged: (s) { if (_programmatic) return; c.setAmount(_parse(s)); },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.date_range),
                    label: Text('${c.date.toLocal().toString().split(' ').first}'),
                    onPressed: () async {
                      final now = c.date;
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: now,
                        firstDate: DateTime(now.year - 5),
                        lastDate: DateTime(now.year + 5),
                      );
                      if (picked != null) c.setDate(DateTime(picked.year, picked.month, picked.day, now.hour, now.minute));
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    children: [
                      const Text('Full tank'),
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
              decoration: const InputDecoration(labelText: 'Notes'),
              onChanged: (s) => c.setNotes(s.isEmpty ? null : s),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text('Save'),
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
    // Απλή validation: χρειαζόμαστε και τα 3 υπολογισμένα τελικά
    if (c.liters == null || c.pricePerLiter == null || c.amount == null) {
      _showSnack('Συμπλήρωσε 2 από τα 3 πεδία για να υπολογιστεί το τρίτο.');
      return;
    }

    final repo = FuelRepo();
    final id = widget.initial?.id ?? DateTime.now().microsecondsSinceEpoch.toString();

    final vehicleId = widget.initial?.vehicleId ?? widget.vehicleId ?? await ActiveVehicleController().getActiveVehicleId();

    final entry = FuelEntry(
      id: id,
      vehicleId: vehicleId,
      date: c.date,
      odometerKm: 0, // TODO: πεδίο στην φόρμα σε επόμενο βήμα
      liters: c.liters!,
      pricePerLiter: c.pricePerLiter!,
      amount: c.amount!,
      fullTank: c.fullTank,
      notes: c.notes,
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
