import 'package:flutter/material.dart';
import '../state/navigation_controller.dart';
import '../state/settings_controller.dart';
import '../state/stats_filter_controller.dart';
import 'tabs/fuel_tab.dart';
import 'tabs/service_tab.dart';
import 'tabs/stats_tab.dart';
import 'tabs/vehicles_tab.dart';
import 'tabs/settings_tab.dart';
import '../l10n/app_localizations.dart';

class Shell extends StatelessWidget {
  final NavigationController controller;
  final SettingsController settings;
  final StatsFilterController statsFilterController;
  const Shell({required this.controller, required this.settings, required this.statsFilterController, super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final index = controller.index;
        return Scaffold(
          appBar: AppBar(title: Text(l10n.appTitle)),
          body: LayoutBuilder(builder: (context, constraints) {
            final wide = constraints.maxWidth > 900;
            final content = _buildContent(index);

            if (wide) {
              return Row(
                children: [
                  NavigationRail(
                    extended: constraints.maxWidth > 1100,
                    selectedIndex: index,
                    onDestinationSelected: (i) => controller.index = i,
                    destinations: [
                      NavigationRailDestination(icon: const Icon(Icons.local_gas_station), label: Text(l10n.tabFuel)),
                      NavigationRailDestination(icon: const Icon(Icons.build), label: Text(l10n.tabService)),
                      NavigationRailDestination(icon: const Icon(Icons.insights), label: Text(l10n.tabStats)),
                      NavigationRailDestination(icon: const Icon(Icons.directions_car), label: Text(l10n.tabVehicles)),
                      NavigationRailDestination(icon: const Icon(Icons.settings), label: Text(l10n.tabSettings)),
                    ],
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: content),
                ],
              );
            }

            return Scaffold(
              body: content,
              bottomNavigationBar: BottomNavigationBar(
                currentIndex: index,
                onTap: (i) => controller.index = i,
                items: [
                  BottomNavigationBarItem(icon: const Icon(Icons.local_gas_station), label: l10n.tabFuel),
                  BottomNavigationBarItem(icon: const Icon(Icons.build), label: l10n.tabService),
                  BottomNavigationBarItem(icon: const Icon(Icons.insights), label: l10n.tabStats),
                  BottomNavigationBarItem(icon: const Icon(Icons.directions_car), label: l10n.tabVehicles),
                  BottomNavigationBarItem(icon: const Icon(Icons.settings), label: l10n.tabSettings),
                ],
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildContent(int index) {
    switch (index) {
      case 0:
        return FuelTab(settings: settings);
      case 1:
        return ServiceTab(settings: settings);
      case 2:
        return StatsTab(settings: settings, statsFilterController: statsFilterController);
      case 3:
        return VehiclesTab();
      case 4:
        return SettingsTab(settings: settings);
      default:
        return const SizedBox.shrink();
    }
  }
}
