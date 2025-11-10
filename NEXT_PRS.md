# 🚀 Επόμενα PRs — Quick Reference

## PR #2: Charts Refactor (feature/stats-charts-refactor)

### Στόχος
Αντικατάσταση χειροποίητων monthly aggregation maps με `seriesFromTotals()` helper.

### Αλλαγές

#### 1. Προσθήκη helper στο stats_aggregator.dart
```dart
class MonthlyChartSeries {
  final List<String> labels;        // ['01/24', '02/24', ...]
  final List<double> liters;        // Σύνολο λίτρα/μήνα
  final List<double> fuelCosts;     // Κόστος καυσίμου/μήνα
  final List<double> serviceCosts;  // Κόστος service/μήνα
  final List<double> totalCosts;    // Συνολικό κόστος/μήνα
  
  const MonthlyChartSeries({
    required this.labels,
    required this.liters,
    required this.fuelCosts,
    required this.serviceCosts,
    required this.totalCosts,
  });
}

/// Μετατρέπει MonthlyTotals σε series για charts.
/// Χρειάζεται να διαχωρίσουμε fuel vs service costs (heuristic ή νέο field).
MonthlyChartSeries seriesFromTotals(
  List<MonthlyTotals> totals,
  String locale, // για DateFormat('MM/yy', locale)
) {
  final labels = <String>[];
  final liters = <double>[];
  final fuelCosts = <double>[];
  final serviceCosts = <double>[];
  final totalCosts = <double>[];
  
  for (final m in totals) {
    labels.add(DateFormat('MM/yy', locale).format(DateTime(m.month.year, m.month.month)));
    liters.add(m.totalLiters);
    
    // Heuristic: αν έχουμε λίτρα, θεωρούμε ότι ~70% είναι fuel cost
    final fuelShare = m.totalLiters > 0 ? 0.7 : 0.0;
    final fuel = m.totalCost * fuelShare;
    fuelCosts.add(fuel);
    serviceCosts.add(m.totalCost - fuel);
    totalCosts.add(m.totalCost);
  }
  
  return MonthlyChartSeries(
    labels: labels,
    liters: liters,
    fuelCosts: fuelCosts,
    serviceCosts: serviceCosts,
    totalCosts: totalCosts,
  );
}
```

**Σημείωση**: Το heuristic (70% fuel) είναι placeholder. Ιδανικά το `MonthlyTotals` θα έπρεπε να έχει:
```dart
class MonthlyTotals {
  // ... existing
  final double fuelCost;    // Κόστος μόνο fuel
  final double serviceCost; // Κόστος μόνο service
}
```
Αυτό θα απαιτεί αλλαγή στο `aggregateMonthly()` για να διακρίνει fuel vs service entries.

#### 2. Refactor stats_tab.dart charts
```dart
// Αντικατέστησε:
// final monthlyCosts = statsService.getMonthlyCost(...);
// final serviceMonthMap = <String, double>{...};

// Με:
final mergedEntries = <dynamic>[]
  ..addAll(windowFuel)
  ..addAll(windowService);
final monthlyTotals = aggregateMonthly(mergedEntries);
final series = seriesFromTotals(monthlyTotals, locale.toString());

// Bar Chart
_MonthlyCostBarChart(
  labels: series.labels,
  fuelCosts: series.fuelCosts,
  serviceCosts: series.serviceCosts,
  currencyCode: widget.settings.currencyCode,
)

// Optional: Line chart για λίτρα
_MonthlyLitersLineChart(
  labels: series.labels,
  liters: series.liters,
)
```

#### 3. Update _MonthlyCostBarChart widget
```dart
class _MonthlyCostBarChart extends StatelessWidget {
  final List<String> labels;
  final List<double> fuelCosts;
  final List<double> serviceCosts;
  final String currencyCode;
  
  // ... build με BarChartData που χρησιμοποιεί τα arrays απευθείας
}
```

### Tests
```dart
// test/stats/stats_series_test.dart
void main() {
  test('seriesFromTotals generates correct arrays', () {
    final totals = [
      MonthlyTotals(month: MonthKey(2024,1), totalLiters: 100, totalCost: 200, totalDistance: 500),
      MonthlyTotals(month: MonthKey(2024,2), totalLiters: 80, totalCost: 150, totalDistance: 400),
    ];
    
    final series = seriesFromTotals(totals, 'en');
    
    expect(series.labels.length, 2);
    expect(series.labels[0], '01/24');
    expect(series.liters[0], 100);
    expect(series.totalCosts[0], 200);
  });
}
```

### Commit Plan
1. `git checkout ai-dev`
2. `git pull`
3. `git checkout -b feature/stats-charts-refactor`
4. Προσθήκη `seriesFromTotals()` + tests → commit
5. Refactor `stats_tab.dart` charts → commit
6. `flutter analyze && flutter test` → PASS
7. `git push -u origin feature/stats-charts-refactor`
8. Open PR → ai-dev

---

## PR #3: Distance Fallback (feature/stats-distance-fallback)

### Στόχος
Όταν fuel entries < 2, χρησιμοποίησε service odometers για distance.

### Αλλαγή στο stats_aggregator.dart
```dart
/// Υπολογίζει απόσταση από odometer spread (fuel prioritized, fallback σε service).
double computeWindowDistance({
  required List<dynamic> fuelEntries,    // με odometerKm ή odometer
  required List<dynamic> serviceEntries, // με odometerKm ή odometer
}) {
  // Priority: fuel odometers
  final fuelOdo = fuelEntries
      .map((e) => (e.odometerKm ?? e.odometer) as double?)
      .whereType<double>()
      .toList()
    ..sort();
  
  if (fuelOdo.length >= 2) {
    return (fuelOdo.last - fuelOdo.first).abs();
  }
  
  // Fallback: merge fuel + service odometers
  final allOdo = <double>[
    ...fuelOdo,
    ...serviceEntries
        .map((e) => (e.odometerKm ?? e.odometer) as double?)
        .whereType<double>(),
  ]..sort();
  
  if (allOdo.length >= 2) {
    return (allOdo.last - allOdo.first).abs();
  }
  
  return 0.0; // Καμία αξιόπιστη πληροφορία
}
```

### Update stats_tab.dart
```dart
// Αντικατέστησε το manual distance calculation:
final distanceKmWindow = computeWindowDistance(
  fuelEntries: windowFuel,
  serviceEntries: windowService,
);
```

### Tests
```dart
test('uses service odometers when fuel sparse', () {
  final fuel = [_Fuel(date: d1, odometerKm: 1000)]; // Μόνο 1 fuel
  final service = [
    _Service(date: d2, odometerKm: 1200),
    _Service(date: d3, odometerKm: 1500),
  ];
  
  final distance = computeWindowDistance(
    fuelEntries: fuel,
    serviceEntries: service,
  );
  
  expect(distance, 500); // 1500 - 1000
});
```

### Commit Plan
Ίδιο flow με PR #2.

---

## 🎯 Priority Order
1. **PR #2 (Charts Refactor)** — μεγαλύτερο impact, αφαιρεί ~80 lines duplicate code
2. **PR #3 (Distance Fallback)** — edge case fix, μικρότερο scope

---

## 📋 Checklist Template (για κάθε PR)
- [ ] Branch από ai-dev (`git checkout -b feature/...`)
- [ ] Implementation + tests
- [ ] `flutter analyze` → PASS
- [ ] `flutter test` → PASS
- [ ] Atomic commits με `[AI]` prefix
- [ ] Push branch
- [ ] Create PR → ai-dev
- [ ] Merge (after review)
- [ ] `git checkout ai-dev && git pull`
- [ ] Tag νέο RC (π.χ. v1.1.0-rc.3)
- [ ] Update CHANGELOG

---

**Ημερομηνία δημιουργίας**: 2025-11-09  
**Τελευταία ενημέρωση**: μετά το merge του feature/stats-graphs
