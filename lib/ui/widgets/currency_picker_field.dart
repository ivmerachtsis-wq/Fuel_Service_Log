import 'package:flutter/material.dart';
import 'package:fuel_service_log/l10n/app_localizations.dart';

/// A form field that allows selecting a currency from a searchable list
class CurrencyPickerField extends StatelessWidget {
  final String? value;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final InputDecoration? decoration;
  final bool enabled;

  const CurrencyPickerField({
    super.key,
    this.value,
    this.onChanged,
    this.validator,
    this.decoration,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return FormField<String>(
      initialValue: value,
      validator: validator,
      builder: (FormFieldState<String> field) {
        return InputDecorator(
          decoration: (decoration ?? InputDecoration(
            labelText: l10n.currency,
            border: const OutlineInputBorder(),
          )).copyWith(
            errorText: field.errorText,
          ),
          child: InkWell(
            onTap: enabled ? () async {
              final selected = await _showCurrencyPicker(context, field.value);
              if (selected != null) {
                field.didChange(selected);
                onChanged?.call(selected);
              }
            } : null,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  field.value ?? l10n.currency,
                  style: TextStyle(
                    fontSize: 16,
                    color: field.value != null 
                      ? Theme.of(context).colorScheme.onSurface 
                      : Theme.of(context).hintColor,
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: enabled ? Theme.of(context).colorScheme.onSurface : Theme.of(context).disabledColor,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<String?> _showCurrencyPicker(BuildContext context, String? currentValue) async {
    final currencies = _getCurrencies();
    
    return await showDialog<String>(
      context: context,
      builder: (context) => _CurrencyPickerDialog(
        currencies: currencies,
        initialValue: currentValue,
      ),
    );
  }

  List<CurrencyInfo> _getCurrencies() {
    return [
      CurrencyInfo('EUR', 'Euro', '€'),
      CurrencyInfo('USD', 'US Dollar', '\$'),
      CurrencyInfo('GBP', 'British Pound', '£'),
      CurrencyInfo('JPY', 'Japanese Yen', '¥'),
      CurrencyInfo('CHF', 'Swiss Franc', 'CHF'),
      CurrencyInfo('CAD', 'Canadian Dollar', 'C\$'),
      CurrencyInfo('AUD', 'Australian Dollar', 'A\$'),
      CurrencyInfo('NZD', 'New Zealand Dollar', 'NZ\$'),
      CurrencyInfo('CNY', 'Chinese Yuan', '¥'),
      CurrencyInfo('INR', 'Indian Rupee', '₹'),
      CurrencyInfo('BRL', 'Brazilian Real', 'R\$'),
      CurrencyInfo('ZAR', 'South African Rand', 'R'),
      CurrencyInfo('RUB', 'Russian Ruble', '₽'),
      CurrencyInfo('KRW', 'South Korean Won', '₩'),
      CurrencyInfo('SGD', 'Singapore Dollar', 'S\$'),
      CurrencyInfo('HKD', 'Hong Kong Dollar', 'HK\$'),
      CurrencyInfo('SEK', 'Swedish Krona', 'kr'),
      CurrencyInfo('NOK', 'Norwegian Krone', 'kr'),
      CurrencyInfo('DKK', 'Danish Krone', 'kr'),
      CurrencyInfo('PLN', 'Polish Zloty', 'zł'),
      CurrencyInfo('CZK', 'Czech Koruna', 'Kč'),
      CurrencyInfo('HUF', 'Hungarian Forint', 'Ft'),
      CurrencyInfo('RON', 'Romanian Leu', 'lei'),
      CurrencyInfo('BGN', 'Bulgarian Lev', 'лв'),
      CurrencyInfo('HRK', 'Croatian Kuna', 'kn'),
      CurrencyInfo('TRY', 'Turkish Lira', '₺'),
      CurrencyInfo('ILS', 'Israeli Shekel', '₪'),
      CurrencyInfo('AED', 'UAE Dirham', 'د.إ'),
      CurrencyInfo('SAR', 'Saudi Riyal', '﷼'),
      CurrencyInfo('MXN', 'Mexican Peso', '\$'),
      CurrencyInfo('ARS', 'Argentine Peso', '\$'),
      CurrencyInfo('CLP', 'Chilean Peso', '\$'),
      CurrencyInfo('COP', 'Colombian Peso', '\$'),
      CurrencyInfo('THB', 'Thai Baht', '฿'),
      CurrencyInfo('MYR', 'Malaysian Ringgit', 'RM'),
      CurrencyInfo('IDR', 'Indonesian Rupiah', 'Rp'),
      CurrencyInfo('PHP', 'Philippine Peso', '₱'),
      CurrencyInfo('VND', 'Vietnamese Dong', '₫'),
    ];
  }
}

class CurrencyInfo {
  final String code;
  final String name;
  final String symbol;

  CurrencyInfo(this.code, this.name, this.symbol);

  bool matches(String query) {
    final q = query.toLowerCase();
    return code.toLowerCase().contains(q) || 
           name.toLowerCase().contains(q) ||
           symbol.contains(query);
  }
}

class _CurrencyPickerDialog extends StatefulWidget {
  final List<CurrencyInfo> currencies;
  final String? initialValue;

  const _CurrencyPickerDialog({
    required this.currencies,
    this.initialValue,
  });

  @override
  State<_CurrencyPickerDialog> createState() => _CurrencyPickerDialogState();
}

class _CurrencyPickerDialogState extends State<_CurrencyPickerDialog> {
  final TextEditingController _searchController = TextEditingController();
  late List<CurrencyInfo> _filteredCurrencies;

  @override
  void initState() {
    super.initState();
    _filteredCurrencies = widget.currencies;
    _searchController.addListener(_filterCurrencies);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterCurrencies() {
    setState(() {
      final query = _searchController.text;
      if (query.isEmpty) {
        _filteredCurrencies = widget.currencies;
      } else {
        _filteredCurrencies = widget.currencies
            .where((c) => c.matches(query))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.currency,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search currencies...',
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                          : null,
                    ),
                    autofocus: true,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _filteredCurrencies.isEmpty
                  ? Center(
                      child: Text(
                        'No currencies found',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredCurrencies.length,
                      itemBuilder: (context, index) {
                        final currency = _filteredCurrencies[index];
                        final isSelected = currency.code == widget.initialValue;
                        
                        return ListTile(
                          selected: isSelected,
                          leading: CircleAvatar(
                            backgroundColor: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.surfaceContainerHighest,
                            child: Text(
                              currency.symbol,
                              style: TextStyle(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.onPrimary
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                          title: Text(currency.name),
                          trailing: Text(
                            currency.code,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          onTap: () {
                            Navigator.of(context).pop(currency.code);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
