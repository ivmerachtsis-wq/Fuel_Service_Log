import 'package:flutter/widgets.dart';

/// Controller για φόρμα καυσίμων με λογική 2-από-3.
enum EditingField { none, liters, pricePerLiter, amount }

class FuelFormController extends ChangeNotifier {
  // Raw values
  double? _liters;
  double? _pricePerLiter;
  double? _amount;
  bool _fullTank = true;
  DateTime _date = DateTime.now();
  String? _notes;

  // UI control
  bool _programmatic = false;
  EditingField _editing = EditingField.none;

  // Public controllers & focus nodes for the form
  final TextEditingController litersController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController odoController = TextEditingController();

  final FocusNode litersFocus = FocusNode();
  final FocusNode priceFocus = FocusNode();
  final FocusNode amountFocus = FocusNode();
  final FocusNode odoFocus = FocusNode();

  // Getters
  double? get liters => _liters;
  double? get pricePerLiter => _pricePerLiter;
  double? get amount => _amount;
  bool get fullTank => _fullTank;
  DateTime get date => _date;
  String? get notes => _notes;

  // Editing API
  void setEditing(EditingField f) {
    _editing = f;
  }

  // Setters with guarded recompute
  void setLiters(double? v) {
    if (_programmatic) return;
    _liters = _sanitize(v);
    _recompute(from: EditingField.liters);
  }

  void setPricePerLiter(double? v) {
    if (_programmatic) return;
    _pricePerLiter = _sanitize(v);
    _recompute(from: EditingField.pricePerLiter);
  }

  void setAmount(double? v) {
    if (_programmatic) return;
    _amount = _sanitize(v);
    _recompute(from: EditingField.amount);
  }

  void setFullTank(bool v) {
    _fullTank = v;
    notifyListeners();
  }

  void setDate(DateTime d) {
    _date = d;
    notifyListeners();
  }

  void setNotes(String? s) {
    _notes = s;
    notifyListeners();
  }

  void writeKeepingCaret(TextEditingController c, String text) {
    c.text = text;
    c.selection = TextSelection.collapsed(offset: text.length);
  }

  // Core 2-of-3 logic with caret-safe updates
  void _recompute({required EditingField from}) {
    // Αν δεν υπάρχουν 2 τιμές, δεν υπολογίζουμε
    final count = [_liters, _pricePerLiter, _amount].where((e) => e != null).length;
    if (count < 2) {
      notifyListeners();
      return;
    }

    _programmatic = true;
    try {
      // liters + price -> amount (format 2 decimals)
      if (_liters != null && _pricePerLiter != null && from != EditingField.amount) {
        _amount = _sanitize(_liters! * _pricePerLiter!);
        if (_amount != null && _editing != EditingField.amount) {
          writeKeepingCaret(amountController, _amount!.toStringAsFixed(2));
        }
      }
      // liters + amount -> price (format 3 decimals)
      else if (_liters != null && _amount != null && _liters! > 0 && from != EditingField.pricePerLiter) {
        _pricePerLiter = _sanitize(_amount! / _liters!);
        if (_pricePerLiter != null && _editing != EditingField.pricePerLiter) {
          writeKeepingCaret(priceController, _pricePerLiter!.toStringAsFixed(3));
        }
      }
      // price + amount -> liters (format 3 decimals)
      else if (_pricePerLiter != null && _amount != null && _pricePerLiter! > 0 && from != EditingField.liters) {
        _liters = _sanitize(_amount! / _pricePerLiter!);
        if (_liters != null && _editing != EditingField.liters) {
          // liters programmatic formatting: 2 decimals
          writeKeepingCaret(litersController, _liters!.toStringAsFixed(2));
        }
      }
    } finally {
      _programmatic = false;
      notifyListeners();
    }
  }

  double? _sanitize(double? v) {
    if (v == null) return null;
    if (v.isNaN) return null;
    if (v <= 0) return null; // τα βασικά πεδία πρέπει να είναι > 0
    return v;
  }

  @override
  void dispose() {
    litersController.dispose();
    priceController.dispose();
    amountController.dispose();
    odoController.dispose();
    litersFocus.dispose();
    priceFocus.dispose();
    amountFocus.dispose();
    odoFocus.dispose();
    super.dispose();
  }
}
