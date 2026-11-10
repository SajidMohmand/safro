import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../core/constants.dart';
import '../core/geo.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../models/models.dart';
import '../services/db.dart';
import '../services/route_service.dart';
import '../services/trip_simulator.dart';
import '../widgets/common.dart';
import 'search_place_screen.dart';
import 'trip_screen.dart';

class BookRideScreen extends StatefulWidget {
  final Place pickup, drop;
  final String vehicle;
  const BookRideScreen({super.key, required this.pickup, required this.drop, this.vehicle = 'Car'});
  @override
  State<BookRideScreen> createState() => _BookRideScreenState();
}

class _BookRideScreenState extends State<BookRideScreen> {
  late Place _pickup = widget.pickup;
  late Place _drop = widget.drop;
  late String _vehicle = widget.vehicle;
  GoogleMapController? _map;
  RouteResult? _route;
  FareConfig _cfg = const FareConfig();
  List<Contact> _contacts = [];
  bool _family = true;
  bool _booking = false;
  final _uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cfg = await Db.fareConfig();
    final contacts = await Db.contactsOnce(_uid);
    if (!mounted) return;
    setState(() {
      _cfg = cfg;
      _contacts = contacts;
      _family = contacts.isNotEmpty;
    });
    await _loadRoute();
  }

  Future<void> _loadRoute() async {
    setState(() => _route = null);
    final r = await RouteService.route(_pickup.latLng, _drop.latLng);
    if (!mounted) return;
    setState(() => _route = r);
    _fit();
  }

  void _fit() {
    final pts = _route?.points ?? [_pickup.latLng, _drop.latLng];
    try {
      _map?.animateCamera(CameraUpdate.newLatLngBounds(boundsOf(pts), 60));
    } catch (_) {}
  }

  int _fare(String v) => _route == null ? 0 : _cfg.fare(_route!, v);
  String get _followerNames => _contacts.map((c) => c.name).join(', ');

  Future<void> _choose(bool pickup) async {
    final p = await Navigator.push<Place>(
        context, MaterialPageRoute(builder: (_) => SearchPlaceScreen(hint: pickup ? 'Pickup' : 'Drop')));
    if (p == null) return;
    setState(() => pickup ? _pickup = p : _drop = p);
    _loadRoute();
  }

  Future<void> _book() async {
    if (_route == null) return;
    if (_pickup.name == _drop.name) {
      showSnack(context, 'Pickup and drop are the same place', error: true);
      return;
    }
    setState(() => _booking = true);
    try {
      final id = await Db.createTrip(
        pickup: _pickup,
        drop: _drop,
        vehicle: _vehicle,
        fare: _fare(_vehicle),
        followers: _family ? _contacts.map((c) => c.name).toList() : [],
      );
      if (AppConfig.simulateDriver) TripSimulator.start(id);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => TripScreen(tripId: id)));
    } catch (e) {
      if (mounted) {
        setState(() => _booking = false);
        showSnack(context, 'Could not book. Check your connection.', error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final fare = _fare(_vehicle);
    return Scaffold(
      body: Stack(children: [
        Positioned.fill(
          child: GoogleMap(
            initialCameraPosition: CameraPosition(target: _pickup.latLng, zoom: 13),
            padding: EdgeInsets.only(bottom: h * .5),
            onMapCreated: (c) {
              _map = c;
              _fit();
            },
            polylines: {
              if (_route != null)
                Polyline(polylineId: const PolylineId('r'), points: _route!.points, color: AppColors.red, width: 5),
            },
            markers: {
              Marker(
                  markerId: const MarkerId('pickup'),
                  position: _pickup.latLng,
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)),
              Marker(
                  markerId: const MarkerId('drop'),
                  position: _drop.latLng,
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed)),
            },
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Material(
              color: Colors.white,
              elevation: 3,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => Navigator.pop(context),
                child: const SizedBox(
                    width: 44, height: 44, child: Icon(Icons.arrow_back_ios_new_rounded, size: 20)),
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            constraints: BoxConstraints(maxHeight: h * .72),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(.14), blurRadius: 22)],
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const SheetHandle(),
                  PickupDropCard(
                    pickup: _pickup.name,
                    drop: _drop.name,
                    showLabels: true,
                    onPickupTap: () => _choose(true),
                    onDropTap: () => _choose(false),
                  ),
                  const SizedBox(height: 12),
                  _vehicleCard('Car', '4 min away', fare),
                  const SizedBox(height: 10),
                  _vehicleCard('AC Car', '6 min away', _fare('AC Car')),
                  const SizedBox(height: 12),
                  Row(children: [
                    const Pill('Fixed fare', icon: Icons.lock_rounded, size: 13),
                    const SizedBox(width: 12),
                    const Icon(Icons.payments_outlined, size: 20, color: AppColors.grey),
                    const SizedBox(width: 6),
                    Text('Cash on arrival', style: ts(14, w: FontWeight.w600)),
                  ]),
                  const SizedBox(height: 12),
                  AppCard(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(children: [
                      const Icon(Icons.ios_share_rounded, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Family follows this trip', style: ts(14.5, w: FontWeight.w700)),
                          Text(_contacts.isEmpty ? 'Add contacts in Safety' : _followerNames,
                              style: ts(12.5, c: AppColors.grey)),
                        ]),
                      ),
                      Switch.adaptive(
                        value: _family,
                        activeColor: AppColors.green,
                        onChanged: _contacts.isEmpty ? null : (v) => setState(() => _family = v),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 14),
                  PrimaryButton(
                    label: _route == null ? 'Finding route...' : 'Book $_vehicle - PKR ${money(fare)}',
                    loading: _booking,
                    onPressed: _route == null ? null : _book,
                  ),
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _vehicleCard(String name, String eta, int price) {
    final sel = _vehicle == name;
    return AppCard(
      onTap: () => setState(() => _vehicle = name),
      borderColor: sel ? AppColors.red : AppColors.line,
      borderWidth: sel ? 2 : 1.3,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(children: [
        Icon(name == 'AC Car' ? Icons.local_taxi_rounded : Icons.directions_car_filled_rounded, size: 34),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: ts(18, w: FontWeight.w800)),
            Text(eta, style: ts(13, c: AppColors.grey)),
          ]),
        ),
        Text(_route == null ? '...' : 'PKR ${money(price)}', style: ts(19, w: FontWeight.w800)),
      ]),
    );
  }
}
