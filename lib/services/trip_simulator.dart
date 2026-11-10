import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../core/geo.dart';
import '../models/models.dart';
import 'db.dart';
import 'route_service.dart';

/// DEMO ONLY - plays the part of the driver app so the whole ride cycle can
/// be tested end to end. It writes to the same trip document the real driver
/// app will write to: status, driver, driverLat/Lng, etaMin, driverArrived,
/// progress. Turn it off with AppConfig.simulateDriver = false.
class TripSimulator {
  static final Map<String, TripSimulator> _active = {};

  static void start(String tripId) {
    if (_active.containsKey(tripId)) return;
    debugPrint('[Safro Simulator] Starting simulation for trip $tripId');
    final s = TripSimulator._(tripId);
    _active[tripId] = s;
    s._run().whenComplete(() {
      debugPrint('[Safro Simulator] Finished simulation for trip $tripId');
      _active.remove(tripId);
    });
  }

  final String tripId;
  TripSimulator._(this.tripId);

  bool _stop = false;
  TripModel? _latest;
  StreamSubscription<TripModel?>? _sub;

  Future<void> _wait(num seconds) =>
      Future.delayed(Duration(milliseconds: (seconds * 1000).round()));

  Future<void> _run() async {
    _sub = Db.tripStream(tripId).listen((t) {
      _latest = t;
      if (t != null && (t.status == TripStatus.cancelled || t.status == TripStatus.completed)) {
        _stop = true;
      }
    });

    try {
      var trip = await Db.getTrip(tripId);
      if (trip == null) {
        debugPrint('[Safro Simulator] Trip $tripId not found');
        return;
      }
      if (trip.status == TripStatus.cancelled || trip.status == TripStatus.completed) return;

      // 1. Nearest driver "accepts" if still searching
      if (trip.status == TripStatus.searching) {
        await _wait(2.5);
        if (_stop) return;
        final drivers = await DriverRepo.load();
        final driver = drivers.first;
        await Db.updateTrip(tripId, {
          'status': TripStatus.found,
          'driver': driver.toMap(),
        });
        debugPrint('[Safro Simulator] Driver accepted: ${driver.name}');
        await _wait(2);
        if (_stop) return;
        trip = await Db.getTrip(tripId) ?? trip;
      }

      // 2. Driver drives to the pickup
      if (trip.status == TripStatus.found || trip.status == TripStatus.searching) {
        final pickup = trip.pickup.latLng;
        final start = LatLng(pickup.latitude + 0.008, pickup.longitude - 0.007);
        final approach = await RouteService.route(start, pickup);
        await Db.updateTrip(tripId, {
          'status': TripStatus.onTheWay,
          'driverLat': start.latitude,
          'driverLng': start.longitude,
          'etaMin': 3,
          'driverArrived': false,
        });
        debugPrint('[Safro Simulator] Driver is on the way to pickup');

        // Drive to pickup over 5 steps (~5 seconds)
        await _drive(approach.path, 5, (f) => {'etaMin': (3 * (1 - f)).ceil().clamp(1, 3)});
        if (_stop) return;

        await Db.updateTrip(tripId, {'driverArrived': true, 'etaMin': 0});
        debugPrint('[Safro Simulator] Driver arrived at pickup');
      }

      // 3. Wait for the passenger to start the trip with the PIN
      debugPrint('[Safro Simulator] Waiting for PIN verification & trip start...');
      var waited = 0;
      while (!_stop && _latest?.status != TripStatus.inProgress) {
        await _wait(0.5);
        if (++waited > 1200) return; // 10 minutes timeout
      }
      if (_stop) return;
      debugPrint('[Safro Simulator] Trip started! Driving to destination...');

      // 4. Drive to destination
      final pickup = trip.pickup.latLng;
      final main = await RouteService.route(pickup, trip.drop.latLng);
      await Db.updateTrip(tripId, {'etaMin': 10, 'progress': 0.0});

      // Drive main route over 12 steps (~14 seconds)
      await _drive(main.path, 12, (f) => {
            'etaMin': (10 * (1 - f)).ceil().clamp(1, 10),
            'progress': f,
            'status': f >= 0.85 ? TripStatus.arriving : TripStatus.inProgress,
          });
      if (_stop) return;

      await _wait(1.5);
      await Db.updateTrip(tripId, {
        'status': TripStatus.completed,
        'progress': 1.0,
        'etaMin': 0,
        'endedAt': DateTime.now().toIso8601String(),
      });
      debugPrint('[Safro Simulator] Trip completed successfully');
    } catch (e, st) {
      debugPrint('[Safro Simulator] Error: $e\n$st');
    } finally {
      await _sub?.cancel();
    }
  }

  Future<void> _drive(GeoPath path, int steps, Map<String, dynamic> Function(double f) extra) async {
    for (var i = 1; i <= steps; i++) {
      await _wait(1);
      if (_stop) return;
      final f = i / steps;
      final p = path.at(f);
      await Db.updateTrip(tripId, {
        'driverLat': p.latitude,
        'driverLng': p.longitude,
        ...extra(f),
      });
    }
  }
}
