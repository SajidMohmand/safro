import 'package:flutter/material.dart';
import '../core/theme.dart';
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
            height: 70,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            indicatorColor: Colors.transparent,
            onDestinationSelected: (i) => AppNav.tab.value = i,
            destinations: const [
              NavigationDestination(
                  icon: Icon(Icons.home_outlined, size: 26),
                  selectedIcon: Icon(Icons.home_rounded, color: AppColors.navSelected, size: 26),
                  label: 'Home'),
              NavigationDestination(
                  icon: Icon(Icons.access_time_rounded, size: 26),
                  selectedIcon: Icon(Icons.access_time_filled, color: AppColors.navSelected, size: 26),
                  label: 'Trips'),
              NavigationDestination(
                icon: Icon(Icons.calendar_today_outlined, size: 26),
                selectedIcon: Icon(
                  Icons.calendar_today,
                  color: AppColors.navSelected,
                  size: 26,
                ),
                label: 'Plans',
              ),
              NavigationDestination(
                  icon: Icon(Icons.verified_user_outlined, size: 26),
                  selectedIcon: Icon(Icons.verified_user, color: AppColors.navSelected, size: 26),
                  label: 'Safety'),
            ],
          ),
        ),
      );
}
