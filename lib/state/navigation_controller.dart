import 'package:flutter/foundation.dart';

/// Απλός controller για πλοήγηση.
/// Χρησιμοποιεί `ValueNotifier<int>` για το ενεργό tab.
class NavigationController extends ValueNotifier<int> {
  /// Δημιουργεί controller με προεπιλεγμένο αρχικό index.
  NavigationController([super.value = 0]);

  int get index => value;

  set index(int i) {
    if (i == value) return;
    value = i;
  }

  void next() {
    index = (value + 1) % 4;
  }
}
