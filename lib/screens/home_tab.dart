import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../models/models.dart';
import '../services/db.dart';
import '../widgets/common.dart';
import 'book_ride_screen.dart';
import 'main_shell.dart';
import 'search_place_screen.dart';

class HomeTab extends StatefulWidget {
  final UserProfile profile;
  const HomeTab({super.key, required this.profile});
  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  GoogleMapController? _map;
  LatLng _center = Places.bahawalpur;
  bool _located = false;
  BitmapDescriptor? _carIcon;
  List<DriverInfo> _drivers = [];
  final _pager = PageController(viewportFraction: .93);
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final icon = await MapIcons.car();
    final drivers = await DriverRepo.load();
    if (!mounted) return;
    setState(() {
      _carIcon = icon;
      _drivers = drivers;
    });
    await _locate();
  }

  Future<void> _locate() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      var p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
      if (p == LocationPermission.denied || p == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
      if (!mounted) return;
      setState(() {
        _center = LatLng(pos.latitude, pos.longitude);
        _located = true;
      });
      _map?.animateCamera(CameraUpdate.newLatLngZoom(_center, 15));
    } catch (_) {}
  }

  /// A few verified drivers shown around the passenger (demo positions).
  Set<Marker> get _markers {
    if (_carIcon == null) return {};
    const offsets = [
      Offset(.004, .003), Offset(-.003, .005), Offset(.002, -.006), Offset(-.005, -.002),
    ];
    return {
      for (var i = 0; i < offsets.length; i++)
        Marker(
          markerId: MarkerId('car$i'),
          position: LatLng(_center.latitude + offsets[i].dx, _center.longitude + offsets[i].dy),
          icon: _carIcon!,
          anchor: const Offset(.5, .5),
          flat: true,
        ),
    };
  }

  Future<void> _openSearch() async {
    final drop = await Navigator.push<Place>(
        context, MaterialPageRoute(builder: (_) => const SearchPlaceScreen()));
    if (drop != null) _book(drop);
  }

  void _book(Place drop) {
    final pickup = drop.name == Places.home.name ? Places.university : Places.home;
    Navigator.push(context, MaterialPageRoute(builder: (_) => BookRideScreen(pickup: pickup, drop: drop)));
  }

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chips = <(String, IconData, Place?)>[
      ('Home', Icons.home_rounded, Places.home),
      ('Uni', Icons.school_rounded, Places.university),
      ('Hospital', Icons.local_hospital_rounded, Places.hospital),
      ('Market', Icons.storefront_rounded, Places.market),
      ('Station', Icons.train_rounded, Places.station),
      ('More', Icons.more_horiz_rounded, null),
    ];

    return Stack(children: [
      Positioned.fill(
        child: GoogleMap(
          initialCameraPosition: CameraPosition(target: _center, zoom: 14.5),
          onMapCreated: (c) {
            _map = c;
            if (_located) c.animateCamera(CameraUpdate.newLatLngZoom(_center, 15));
          },
          markers: _markers,
          myLocationEnabled: _located,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          compassEnabled: false,
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).size.height * .36),
        ),
      ),

      // Top bar: greeting (left) + Safe Mode (right)
      SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.fromLTRB(5, 5, 16, 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(.12), blurRadius: 12, offset: const Offset(0, 3))],
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Avatar(widget.profile.name, size: 38),
                const SizedBox(width: 10),
                Text('Salaam, ${widget.profile.firstName}', style: ts(15, w: FontWeight.w700)),
              ]),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => showSnack(context, 'Safe Mode: Ride PIN, live sharing, masked calls and SOS are on.'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.green,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(.12), blurRadius: 10, offset: const Offset(0, 3))],
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.shield_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 6),
                  Text('Safe Mode', style: ts(13, w: FontWeight.w700, c: Colors.white)),
                ]),
              ),
            ),
          ]),
        ),
      ),

      // Bottom sheet that cannot be closed (min size == initial size)
      DraggableScrollableSheet(
        initialChildSize: .40,
        minChildSize: .40,
        maxChildSize: .58,
        builder: (context, sc) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(.12), blurRadius: 20)],
          ),
          child: ListView(
            controller: sc,
            padding: const EdgeInsets.fromLTRB(18, 10, 0, 16),
            children: [
              const SheetHandle(),
              Padding(
                padding: const EdgeInsets.only(right: 18),
                child: GestureDetector(
                  onTap: _openSearch,
                  child: Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(16)),
                    child: Row(children: [
                      const Icon(Icons.search_rounded, size: 26),
                      const SizedBox(width: 12),
                      Text('Where to ?', style: ts(17, w: FontWeight.w600, c: AppColors.grey)),
                    ]),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(right: 18),
                  itemCount: chips.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, i) {
                    final c = chips[i];
                    return InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: () => c.$3 == null ? _openSearch() : _book(c.$3!),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                            border: Border.all(color: AppColors.line, width: 1.4),
                            borderRadius: BorderRadius.circular(30)),
                        child: Row(children: [
                          Icon(c.$2, size: 20, color: AppColors.red),
                          const SizedBox(width: 8),
                          Text(c.$1, style: ts(14, w: FontWeight.w600)),
                        ]),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              if (_drivers.isNotEmpty)
                SizedBox(
                  height: 100,
                  child: PageView.builder(
                    controller: _pager,
                    padEnds: false,
                    itemCount: _drivers.length,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: _driverCard(_drivers[i]),
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                for (var i = 0; i < _drivers.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _page ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                        color: i == _page ? AppColors.red : AppColors.line,
                        borderRadius: BorderRadius.circular(6)),
                  ),
              ]),
            ],
          ),
        ),
      ),
    ]);
  }

  Widget _driverCard(DriverInfo d) => AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        onTap: () {
          AppNav.selectedDriver.value = d;
          AppNav.tab.value = 2;
        },
        child: Row(children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: AppColors.redSoft, borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.calendar_month_rounded, color: AppColors.red),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(d.name, style: ts(16, w: FontWeight.w700)),
              Text('Same driver every day', style: ts(12.5, c: AppColors.grey)),
              Text('PKR ${money(d.monthlyPrice)} a month', style: ts(13, w: FontWeight.w700, c: AppColors.red)),
            ]),
          ),
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(color: AppColors.ink, shape: BoxShape.circle),
            child: const Icon(Icons.navigation_rounded, color: Colors.white, size: 18),
          ),
        ]),
      );
}
