import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

String formatCurrency(num? value, {required String currencyCode, required BuildContext context}) {
  if (value == null) return '—';
  if (value.isNaN) return '—';
  final locale = Localizations.localeOf(context).toString();
  final f = NumberFormat.simpleCurrency(name: currencyCode, locale: locale);
  return f.format(value);
}
