import 'package:flutter/material.dart';
import 'l10n/app_localizations.dart';

void main() {
  runApp(const FuelServiceApp());
}

class FuelServiceApp extends StatelessWidget {
  const FuelServiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fuel & Service Log',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // Default: EL/GR, μπορείς να αλλάξεις από Settings
      locale: const Locale('el'),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MainTabsPage(),
    );
  }
}

class MainTabsPage extends StatefulWidget {
  const MainTabsPage({super.key});

  @override
  State<MainTabsPage> createState() => _MainTabsPageState();
}

class _MainTabsPageState extends State<MainTabsPage> {
  int _index = 0;

  final _pages = const [
    FuelPage(),
    ServicePage(),
    StatsPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    final items = <NavigationDestination>[
      NavigationDestination(icon: const Icon(Icons.local_gas_station), label: t.tabFuel),
      NavigationDestination(icon: const Icon(Icons.build), label: t.tabService),
      NavigationDestination(icon: const Icon(Icons.insights), label: t.tabStats),
      NavigationDestination(icon: const Icon(Icons.settings), label: t.tabSettings),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(t.appTitle),
      ),
      body: Row(
        children: [
          // Sidebar για Windows wide screens
          NavigationRail(
            extended: MediaQuery.of(context).size.width > 1100,
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: items
                .map((e) => NavigationRailDestination(
                      icon: e.icon,
                      label: Text(e.label),
                    ))
                .toList(),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: _pages[_index]),
        ],
      ),
      floatingActionButton: _index == 0 || _index == 1
          ? FloatingActionButton(
              onPressed: () {
                // TODO: open add dialogs per module
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

/// Fuel
class FuelPage extends StatelessWidget {
  const FuelPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    // TODO: Bind σε πραγματικά δεδομένα. Placeholder list:
    final items = <Map<String, dynamic>>[];

    if (items.isEmpty) {
      return Center(child: Text(t.emptyFuel));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemBuilder: (_, i) {
        final it = items[i];
        return Dismissible(
          key: ValueKey('fuel_$i'),
          background: Container(color: Colors.red),
          onDismissed: (_) {
            // TODO: delete + show SnackBar Undo
          },
          child: Card(
            child: ListTile(
              title: Text('Fuel #$i'),
              subtitle: Text('L/100km: ${it['consumption'] ?? '--'}'),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  // TODO: edit
                },
              ),
            ),
          ),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemCount: items.length,
    );
  }
}

/// Service
class ServicePage extends StatelessWidget {
  const ServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final items = <Map<String, dynamic>>[];

    if (items.isEmpty) {
      return Center(child: Text(t.emptyService));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemBuilder: (_, i) {
        return Card(
          child: ListTile(
            title: Text('Service #$i'),
            subtitle: const Text('Total: -- €'),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {},
            ),
          ),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemCount: items.length,
    );
  }
}

/// Stats (skeleton χωρίς εξωτερικές βιβλιοθήκες)
class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    // TODO: Replace με πραγματικούς υπολογισμούς ενεργού οχήματος
    final avgConsumption = '--';
    final costPerKm = '--';
    final monthlyCost = '--';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          _StatCard(title: t.statsTitle, value: ''),
          _StatCard(title: 'Avg L/100km', value: avgConsumption),
          _StatCard(title: 'Cost / km', value: costPerKm),
          _StatCard(title: '€ / month', value: monthlyCost),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  const _StatCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(value, style: Theme.of(context).textTheme.headlineMedium),
            ],
          ),
        ),
      ),
    );
  }
}

/// Settings (θα φιλοξενήσει και Language switch)
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          leading: const Icon(Icons.language),
          title: Text(t.settingsTitle),
          subtitle: const Text('Language: EL / EN'),
          onTap: () {
            // TODO: implement language switching via provider / settings box
          },
        ),
      ],
    );
  }
}
