import 'package:flutter/widgets.dart';

/// Controller για φόρμα service με validation και formatting
class ServiceFormController extends ChangeNotifier {
  // Raw values
  double? _odometerKm;
  String? _description;
  double? _totalAmount;
  DateTime _date = DateTime.now();
  String? _notes;

  // Public controllers & focus nodes for the form
  final TextEditingController odoController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  final FocusNode odoFocus = FocusNode();
  final FocusNode descriptionFocus = FocusNode();
  final FocusNode amountFocus = FocusNode();
  final FocusNode notesFocus = FocusNode();

  // Getters
  double? get odometerKm => _odometerKm;
  String? get description => _description;
  double? get totalAmount => _totalAmount;
  DateTime get date => _date;
  String? get notes => _notes;

  // Setters
  void setOdometerKm(double? v) {
    _odometerKm = v != null && v >= 0 ? v : null;
    notifyListeners();
  }

  void setDescription(String? s) {
    _description = s?.trim().isEmpty == true ? null : s?.trim();
    notifyListeners();
  }

  void setTotalAmount(double? v) {
    _totalAmount = v != null && v >= 0 ? v : null;
    notifyListeners();
  }

  void setDate(DateTime d) {
    _date = d;
    notifyListeners();
  }

  void setNotes(String? s) {
    _notes = s?.trim().isEmpty == true ? null : s?.trim();
    notifyListeners();
  }

  void writeKeepingCaret(TextEditingController c, String text) {
    final offset = c.selection.baseOffset;
    c.text = text;
    if (offset >= 0 && offset <= text.length) {
      c.selection = TextSelection.collapsed(offset: offset);
    } else {
      c.selection = TextSelection.collapsed(offset: text.length);
    }
  }

  @override
  void dispose() {
    odoController.dispose();
    descriptionController.dispose();
    amountController.dispose();
    notesController.dispose();
    odoFocus.dispose();
    descriptionFocus.dispose();
    amountFocus.dispose();
    notesFocus.dispose();
    super.dispose();
  }
}
