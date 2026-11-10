import 'package:flutter/material.dart';
import '../models/models.dart';
import 'home_tab.dart';
import 'plans_tab.dart';
import 'safety_tab.dart';
import 'trips_tab.dart';

/// Lets one tab ask another to open (e.g. Home driver card -> Plans tab).
class AppNav {
  static final tab = ValueNotifier<int>(0);
  static final selectedDriver = ValueNotifier<DriverInfo?>(null);
}

class MainShell extends StatelessWidget {
  final UserProfile profile;
  const MainShell({super.key, required this.profile});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
        valueListenable: AppNav.tab,
        builder: (context, index, _) => Scaffold(
          body: IndexedStack(index: index, children: [
            HomeTab(profile: profile),
            const TripsTab(),
            const PlansTab(),
            SafetyTab(profile: profile),
          ]),
          bottomNavigationBar: NavigationBar(
            selectedIndex: index,
            height: 68,
            onDestinationSelected: (i) => AppNav.tab.value = i,
            destinations: const [
              NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded, color: Color(0xFFE5383B)),
                  label: 'Home'),
              NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long_rounded, color: Color(0xFFE5383B)),
                  label: 'Trips'),
              NavigationDestination(
                  icon: Icon(Icons.calendar_month_outlined),
                  selectedIcon: Icon(Icons.calendar_month_rounded, color: Color(0xFFE5383B)),
                  label: 'Plans'),
              NavigationDestination(
                  icon: Icon(Icons.shield_outlined),
                  selectedIcon: Icon(Icons.shield_rounded, color: Color(0xFFE5383B)),
                  label: 'Safety'),
            ],
          ),
        ),
      );
}
