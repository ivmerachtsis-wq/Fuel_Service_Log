import 'package:flutter/foundation.dart';

/// Controller για φόρμα καυσίμων με λογική 2-από-3.
class FuelFormController extends ChangeNotifier {
  double? _liters;
  double? _pricePerLiter;
  double? _amount;
  bool _fullTank = true;
  DateTime _date = DateTime.now();
  String? _notes;

  bool _isCalculating = false;

  double? get liters => _liters;
  double? get pricePerLiter => _pricePerLiter;
  double? get amount => _amount;
  bool get fullTank => _fullTank;
  DateTime get date => _date;
  String? get notes => _notes;

  void setLiters(double? v) {
    if (_isCalculating) return;
    _liters = _sanitize(v);
    _recalc(from: 'liters');
  }

  void setPricePerLiter(double? v) {
    if (_isCalculating) return;
    _pricePerLiter = _sanitize(v);
    _recalc(from: 'price');
  }

  void setAmount(double? v) {
    if (_isCalculating) return;
    _amount = _sanitize(v);
    _recalc(from: 'amount');
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

  // Core 2-of-3 logic
  void _recalc({required String from}) {
    // Αν δεν υπάρχουν 2 τιμές, δεν υπολογίζουμε
    final count = [_liters, _pricePerLiter, _amount].where((e) => e != null).length;
    if (count < 2) {
      notifyListeners();
      return;
    }

    _isCalculating = true;
    try {
      if (from != 'amount' && _liters != null && _pricePerLiter != null) {
        final a = _liters! * _pricePerLiter!;
        _amount = _sanitize(a);
      } else if (from != 'price' && _liters != null && _amount != null && _liters! > 0) {
        final p = _amount! / _liters!;
        _pricePerLiter = _sanitize(p);
      } else if (from != 'liters' && _pricePerLiter != null && _amount != null && _pricePerLiter! > 0) {
        final l = _amount! / _pricePerLiter!;
        _liters = _sanitize(l);
      }
    } finally {
      _isCalculating = false;
      notifyListeners();
    }
  }

  double? _sanitize(double? v) {
    if (v == null) return null;
    if (v.isNaN) return null;
    // Απορρίπτουμε αρνητικές και -0.0
    if (v <= 0) return null;
    return v;
  }
}
