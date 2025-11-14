import 'package:flutter/material.dart';
import 'package:fuel_service_log/l10n/app_localizations.dart';

class DatePickerField extends StatelessWidget {
  final DateTime value;
  final ValueChanged<DateTime> onChanged;
  final String? label;
  final DateTime? firstDate;
  final DateTime? lastDate;
  const DatePickerField({super.key, required this.value, required this.onChanged, this.label, this.firstDate, this.lastDate});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lbl = label ?? l10n.serviceDate;
    return InkWell(
      onTap: () async {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final picked = await showDatePicker(
          context: context,
          initialDate: value.isAfter(today) ? today : value,
          firstDate: firstDate ?? DateTime(2000,1,1),
          lastDate: lastDate ?? today,
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: lbl,
          border: const OutlineInputBorder(),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${value.year}-${value.month.toString().padLeft(2,'0')}-${value.day.toString().padLeft(2,'0')}'),
            const Icon(Icons.calendar_today, size: 20),
          ],
        ),
      ),
    );
  }
}