import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart' show FieldValue;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/constants.dart';
import '../core/geo.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../services/db.dart';
import '../services/route_service.dart';
import '../services/trip_simulator.dart';
import '../widgets/common.dart';
import 'rating_screen.dart';
import 'sos_screen.dart';

/// One screen for the whole live ride. The map stays; only the bottom sheet
/// changes with trips/{id}.status:
///   searching -> found -> onTheWay -> inProgress -> arriving -> completed
/// "completed" opens the rating screen, "cancelled" returns home.
class TripScreen extends StatefulWidget {
  final String tripId;
  const TripScreen({super.key, required this.tripId});
  @override
  State<TripScreen> createState() => _TripScreenState();
}

class _TripScreenState extends State<TripScreen> with SingleTickerProviderStateMixin {
  GoogleMapController? _map;
  RouteResult? _route;
  bool _routeLoading = false;
  TripModel? _trip;
  StreamSubscription<TripModel?>? _sub;
  BitmapDescriptor? _carIcon;

  // Smooth driver movement: the marker glides from the last point to the new one.
  late final AnimationController _anim =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  LatLng? _from, _to;
  double _heading = 0;
  bool _followedOnce = false;

  bool _left = false; // already navigated away (rating / home)
  bool _sosOpen = false;

  @override
  void initState() {
    super.initState();
    _sub = Db.tripStream(widget.tripId).listen(_onTrip);
    MapIcons.car().then((i) {
      if (mounted) setState(() => _carIcon = i);
    });
    if (AppConfig.simulateDriver) {
      TripSimulator.start(widget.tripId);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _anim.dispose();
    super.dispose();
  }

  LatLng? _driverPos() {
    if (_from == null || _to == null) return null;
    return lerpLatLng(_from!, _to!, _anim.value);
  }

  void _onTrip(TripModel? t) {
    if (t == null || !mounted) return;
    _trip = t;
    if (_route == null && !_routeLoading) {
      _routeLoading = true;
      RouteService.route(t.pickup.latLng, t.drop.latLng).then((r) {
        if (!mounted) return;
        setState(() => _route = r);
        _fit();
      });
    }
    if (t.driverLat != null && t.driverLng != null) {
      final np = LatLng(t.driverLat!, t.driverLng!);
      final cur = _driverPos();
      if (cur == null) {
        _from = np;
        _to = np;
      } else if (_to!.latitude != np.latitude || _to!.longitude != np.longitude) {
        _from = cur;
        _to = np;
        if (haversineM(cur, np) > 1) _heading = bearing(cur, np);
        _anim.forward(from: 0);
      }
      if (t.status == TripStatus.onTheWay ||
          t.status == TripStatus.inProgress ||
          t.status == TripStatus.arriving) {
        _follow(np);
      }
    }
    setState(() {});
    _handleTerminal();
  }

  void _handleTerminal() {
    final t = _trip;
    if (t == null || _left || _sosOpen || !mounted) return;
    if (t.status != TripStatus.completed && t.status != TripStatus.cancelled) return;
    _left = true;
    final route = ModalRoute.of(context);
    Navigator.of(context).popUntil((r) => r == route || r.isFirst);
    if (t.status == TripStatus.completed) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => RatingScreen(trip: t)));
    } else {
      Navigator.of(context).popUntil((r) => r.isFirst);
    }
  }

  void _follow(LatLng p) {
    if (!_followedOnce) {
      _followedOnce = true;
      _map?.animateCamera(CameraUpdate.newLatLngZoom(p, 14.8));
    } else {
      _map?.animateCamera(CameraUpdate.newLatLng(p));
    }
  }

  void _fit() {
    final t = _trip;
    if (t == null) return;
    try {
      _map?.animateCamera(CameraUpdate.newLatLngBounds(
          boundsOf(_route?.points ?? [t.pickup.latLng, t.drop.latLng]), 60));
    } catch (_) {}
  }

  String _phase(TripModel t) {
    if (t.status == TripStatus.found) return 'found';
    if (t.status == TripStatus.onTheWay) return 'way';
    if (t.status == TripStatus.inProgress || t.status == TripStatus.arriving) return 'prog';
    return 'search';
  }

  // ---------------- actions ----------------
  Future<void> _cancelRide() async {
    try {
      await Db.updateTrip(widget.tripId, {
        'status': TripStatus.cancelled,
        'cancelledAt': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      if (mounted) showSnack(context, 'Could not cancel. Try again.', error: true);
    }
  }

  Future<void> _pinAction(TripModel t) async {
    if (!t.pinEntered) {
      // In simulator mode: verifies the PIN and confirms arrival
      await Db.updateTrip(t.id, {'pinEntered': true, 'driverArrived': true});
      return;
    }
    await Db.updateTrip(t.id, {
      'status': TripStatus.inProgress,
      'startedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _smsFallback(TripModel t, LatLng pos) async {
    final body = 'SOS from Safro. Trip ${t.id}. Location: https://maps.google.com/?q=${pos.latitude},${pos.longitude}';
    try {
      await launchUrl(Uri.parse('sms:${AppConfig.supportPhone}?body=${Uri.encodeComponent(body)}'));
    } catch (_) {}
  }

  Future<void> _triggerSos(TripModel t) async {
    HapticFeedback.heavyImpact();
    final ref = Db.newSosRef();
    final pos = _driverPos() ?? t.pickup.latLng; // she is in the car
    // Alert reaches the support console. With no data connection the write
    // cannot finish in time, so we fall back to SMS (brief S9).
    ref.set({
      'passengerId': Db.uid,
      'tripId': t.id,
      'status': 'open',
      'lat': pos.latitude,
      'lng': pos.longitude,
      'driverName': t.driver?.name,
      'plate': t.driver?.plate,
      'followers': t.followers,
      'createdAt': FieldValue.serverTimestamp(),
    }).timeout(const Duration(seconds: 4)).catchError((Object _) => _smsFallback(t, pos));
    Db.updateTrip(t.id, {'sosActive': true}).catchError((Object _) {});

    _sosOpen = true;
    final cancelled = await Navigator.of(context).push<bool>(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => SosScreen(alertId: ref.id, followers: t.followers.join(' and ')),
    ));
    _sosOpen = false;
    if (!mounted) return;
    Db.updateTrip(t.id, {'sosActive': false}).catchError((Object _) {});
    if (cancelled == true) _topToast('Alert cancelled. Support has been told you are safe.');
    _handleTerminal();
  }

  void _topToast(String msg) {
    final m = ScaffoldMessenger.of(context);
    m.hideCurrentSnackBar();
    m.showSnackBar(SnackBar(
      content: Text(msg, style: ts(14, w: FontWeight.w600, c: Colors.white)),
      backgroundColor: AppColors.green,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 4),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ));
  }

  // ---------------- build ----------------
  double _mapPad(String phase) =>
      phase == 'way' ? .45 : (phase == 'prog' ? .34 : .36);

  Widget _mapWidget(TripModel t, String phase, double h) => AnimatedBuilder(
        animation: _anim,
        builder: (_, __) {
          final dp = _driverPos();
          return GoogleMap(
            initialCameraPosition: CameraPosition(target: t.pickup.latLng, zoom: 13.5),
            padding: EdgeInsets.only(bottom: h * _mapPad(phase)),
            polylines: {
              if (_route != null)
                Polyline(polylineId: const PolylineId('route'), points: _route!.points, color: AppColors.red, width: 5),
            },
            markers: {
              Marker(
                  markerId: const MarkerId('pickup'),
                  position: t.pickup.latLng,
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)),
              Marker(
                  markerId: const MarkerId('drop'),
                  position: t.drop.latLng,
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed)),
              if (dp != null && _carIcon != null)
                Marker(
                    markerId: const MarkerId('driver'),
                    position: dp,
                    icon: _carIcon!,
                    anchor: const Offset(.5, .5),
                    flat: true,
                    rotation: _heading),
            },
            onMapCreated: (c) {
              _map = c;
              _fit();
            },
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
          );
        },
      );

  Widget _sheet(String phase, List<Widget> children) {
    final cfg = switch (phase) {
      'way' => (.70, .22, .78),
      'prog' => (.34, .14, .40),
      _ => (.38, .12, .38),
    };
    return DraggableScrollableSheet(
      key: ValueKey(phase),
      initialChildSize: cfg.$1,
      minChildSize: cfg.$2,
      maxChildSize: cfg.$3,
      builder: (context, sc) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(.14), blurRadius: 22)],
        ),
        child: ListView(
          controller: sc,
          padding: EdgeInsets.fromLTRB(20, 10, 20, 18 + MediaQuery.of(context).padding.bottom),
          children: [const SheetHandle(), ...children],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = _trip;
    final h = MediaQuery.of(context).size.height;
    if (t == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.red)));
    }
    final phase = _phase(t);
    final d = t.driver;
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Stack(children: [
          Positioned.fill(child: _mapWidget(t, phase, h)),

          // Map labels
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Align(
                alignment: phase == 'way' ? Alignment.topCenter : Alignment.topLeft,
                child: phase == 'way' && t.pinEntered && d != null
                    ? _mapLabel('Check the plate: ${d.plate}', AppColors.ink, Icons.directions_car_rounded)
                    : (phase == 'prog' && t.followers.isNotEmpty
                        ? _mapLabel('${t.followers.join(' and ')} are following', AppColors.green, Icons.visibility_rounded)
                        : const SizedBox.shrink()),
              ),
            ),
          ),

          if (phase == 'search') _sheet(phase, _searching()),
          if (phase == 'found' && d != null) _sheet(phase, _found(d)),
          if (phase == 'way' && d != null) _sheet(phase, _onTheWay(t, d)),
          if (phase == 'prog' && d != null) _sheet(phase, _inProgress(t, d)),
        ]),
      ),
    );
  }

  Widget _mapLabel(String text, Color bg, IconData icon) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(.2), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Flexible(child: Text(text, style: ts(13.5, w: FontWeight.w600, c: Colors.white))),
        ]),
      );

  // ---------- sheet: finding a verified driver ----------
  List<Widget> _searching() => [
        const SizedBox(height: 6),
        Center(
          child: Container(
            width: 86,
            height: 86,
            decoration: const BoxDecoration(color: AppColors.red, shape: BoxShape.circle),
            child: const Icon(Icons.directions_car_filled_rounded, color: Colors.white, size: 46),
          ),
        ),
        const SizedBox(height: 18),
        Center(child: Text('Finding a verified driver', style: ts(23, w: FontWeight.w800))),
        const SizedBox(height: 6),
        Center(child: Text('Asking the nearest women drivers', style: ts(14, c: AppColors.grey))),
        const SizedBox(height: 22),
        BorderButton(label: 'Cancel', onPressed: _cancelRide),
      ];

  // ---------- sheet: driver found ----------
  List<Widget> _found(DriverInfo d) => [
        const Center(child: RippleIcon()),
        Center(child: Text('Driver found', style: ts(25, w: FontWeight.w800))),
        const SizedBox(height: 4),
        Center(child: Text('${d.name} accepted', style: ts(14.5, c: AppColors.grey))),
        const SizedBox(height: 18),
        PrimaryButton(
          label: 'View Driver on the Way',
          onPressed: () {
            Db.updateTrip(widget.tripId, {
              'status': TripStatus.onTheWay,
              'driverArrived': true,
            });
          },
        ),
        const SizedBox(height: 10),
        BorderButton(label: 'Cancel', onPressed: _cancelRide),
      ];

  // ---------- sheet: driver on the way ----------
  List<Widget> _onTheWay(TripModel t, DriverInfo d) {
    final ready = t.pinEntered;
    return [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: Text(
            t.driverArrived ? '${d.firstName} has\narrived' : '${d.firstName} is\non the way',
            style: ts(28, w: FontWeight.w800, h: 1.15),
          ),
        ),
        Pill(t.driverArrived ? 'Here' : '${t.etaMin} min',
            bg: AppColors.redSoft, fg: AppColors.red, size: 14),
      ]),
      const SizedBox(height: 14),
      AppCard(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Avatar(d.name, size: 56, border: AppColors.green),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(d.name, style: ts(17, w: FontWeight.w700)),
              Text('${d.rating} • ${d.trips} trips', style: ts(12.5, c: AppColors.grey)),
              const SizedBox(height: 5),
              const Pill('Verified today', icon: Icons.verified_rounded, size: 11.5),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(d.plate.replaceAll('-', ' - '), style: ts(16, w: FontWeight.w800)),
            Text(d.car, style: ts(12.5, c: AppColors.grey)),
          ]),
        ]),
      ),
      const SizedBox(height: 12),
      AppCard(
        color: AppColors.redSoft,
        borderColor: Colors.transparent,
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('Ride PIN', style: ts(15, w: FontWeight.w800)),
            const SizedBox(width: 8),
            Text('Tell the driver', style: ts(12.5, c: AppColors.grey)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            for (var i = 0; i < 4; i++)
              Expanded(
                child: Container(
                  height: 56,
                  margin: EdgeInsets.only(right: i == 3 ? 0 : 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                  child: Text(t.pin.length > i ? t.pin[i] : '', style: ts(28, w: FontWeight.w800)),
                ),
              ),
          ]),
        ]),
      ),
      const SizedBox(height: 12),
      Row(children: [
        _action(Icons.call_rounded, 'Call', () => showSnack(context, 'Calling ${d.firstName} through Safro. Your number stays hidden.')),
        const SizedBox(width: 10),
        _action(Icons.chat_bubble_rounded, 'Chat', () => _openChat(t.id)),
        const SizedBox(width: 10),
        _action(Icons.ios_share_rounded, 'Share', () {
          Share.share('I am riding with Safro. Driver ${d.name}, ${d.plate} (${d.car}). '
              'Follow my trip: https://safro.app/t/${t.id}');
        }),
      ]),
      const SizedBox(height: 14),
      PrimaryButton(
        label: ready ? 'Start trip with PIN' : 'Driver enters PIN',
        color: ready ? AppColors.green : AppColors.redSoft,
        textColor: ready ? Colors.white : AppColors.red,
        onPressed: () => _pinAction(t),
      ),
      Center(
        child: TextButton(
          onPressed: _cancelRide,
          child: Text('Cancel ride', style: ts(14, w: FontWeight.w600, c: AppColors.grey)),
        ),
      ),
    ];
  }

  Widget _action(IconData icon, String label, VoidCallback onTap) => Expanded(
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 22, color: AppColors.ink),
          label: Text(label, style: ts(15, w: FontWeight.w700)),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 52),
            side: const BorderSide(color: AppColors.ink, width: 1.4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      );

  void _openChat(String tripId) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => ChatSheet(tripId: tripId),
    );
  }

  // ---------- sheet: trip in progress ----------
  List<Widget> _inProgress(TripModel t, DriverInfo d) {
    final arriving = t.status == TripStatus.arriving;
    return [
      Row(children: [
        Expanded(child: Text(arriving ? 'Arriving' : 'On the way', style: ts(28, w: FontWeight.w800))),
        Pill('${t.etaMin} min', bg: AppColors.redSoft, fg: AppColors.red, size: 14),
      ]),
      const SizedBox(height: 14),
      TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: t.progress.clamp(0.0, 1.0)),
        duration: const Duration(milliseconds: 900),
        builder: (_, v, __) => ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
              value: v, minHeight: 8, color: AppColors.green, backgroundColor: AppColors.line),
        ),
      ),
      const SizedBox(height: 16),
      AppCard(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        child: Row(children: [
          Avatar(d.name, size: 52),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${d.name} • ${d.plate}', style: ts(14.5, w: FontWeight.w700)),
              const SizedBox(height: 2),
              Text('to ${t.drop.name}', maxLines: 2, overflow: TextOverflow.ellipsis, style: ts(12.5, c: AppColors.grey)),
            ]),
          ),
          const SizedBox(width: 8),
          SosHoldButton(onTriggered: () => _triggerSos(t)),
        ]),
      ),
      const SizedBox(height: 8),
      Align(
        alignment: Alignment.centerRight,
        child: Text('Hold the button for ${AppConfig.sosHoldSeconds} seconds', style: ts(12.5, c: AppColors.grey)),
      ),
    ];
  }
}

// ======================================================================
// SOS hold button: a ring fills up over 3 seconds, then onTriggered fires.
// ======================================================================
class SosHoldButton extends StatefulWidget {
  final VoidCallback onTriggered;
  const SosHoldButton({super.key, required this.onTriggered});
  @override
  State<SosHoldButton> createState() => _SosHoldButtonState();
}

class _SosHoldButtonState extends State<SosHoldButton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(seconds: AppConfig.sosHoldSeconds))
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        widget.onTriggered();
        _c.reset();
      }
    });

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _release() {
    if (_c.status != AnimationStatus.completed) _c.reverse();
  }

  @override
  Widget build(BuildContext context) => Listener(
        onPointerDown: (_) {
          HapticFeedback.mediumImpact();
          _c.forward();
        },
        onPointerUp: (_) => _release(),
        onPointerCancel: (_) => _release(),
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) => SizedBox(
            width: 82,
            height: 82,
            child: CustomPaint(
              painter: _RingPainter(_c.value),
              child: Center(
                child: Container(
                  width: 62,
                  height: 62,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.red,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: AppColors.red.withOpacity(.45), blurRadius: 14, spreadRadius: 2)],
                  ),
                  child: Text('SOS', style: ts(18, w: FontWeight.w800, c: Colors.white)),
                ),
              ),
            ),
          ),
        ),
      );
}

class _RingPainter extends CustomPainter {
  final double v;
  _RingPainter(this.v);
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(center: size.center(Offset.zero), radius: size.width / 2 - 4);
    canvas.drawCircle(rect.center, rect.width / 2, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..color = AppColors.redSoft);
    if (v > 0) {
      canvas.drawArc(rect, -1.5708, 6.28318 * v, false, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..color = AppColors.redDark);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.v != v;
}

// ======================================================================
// "Driver found": car icon with red water-ripple rings around it.
// ======================================================================
class RippleIcon extends StatefulWidget {
  const RippleIcon({super.key});
  @override
  State<RippleIcon> createState() => _RippleIconState();
}

class _RippleIconState extends State<RippleIcon> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _ring(double v) {
    final size = 86 + v * 84;
    return Opacity(
      opacity: ((1 - v) * .4).clamp(0.0, 1.0),
      child: Container(width: size, height: size, decoration: const BoxDecoration(color: AppColors.red, shape: BoxShape.circle)),
    );
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 172,
        height: 172,
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) => Stack(alignment: Alignment.center, children: [
            for (var i = 0; i < 3; i++) _ring((_c.value + i / 3) % 1.0),
            Container(
              width: 86,
              height: 86,
              decoration: const BoxDecoration(color: AppColors.red, shape: BoxShape.circle),
              child: const Icon(Icons.directions_car_filled_rounded, color: Colors.white, size: 46),
            ),
          ]),
        ),
      );
}

// ======================================================================
// In-app chat with the driver (messages are stored under the trip).
// ======================================================================
class ChatSheet extends StatefulWidget {
  final String tripId;
  const ChatSheet({super.key, required this.tripId});
  @override
  State<ChatSheet> createState() => _ChatSheetState();
}

class _ChatSheetState extends State<ChatSheet> {
  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * .55,
          child: Column(children: [
            const SizedBox(height: 12),
            const SheetHandle(),
            Text('Chat with your driver', style: ts(17, w: FontWeight.w800)),
            Text('Your number is never shown', style: ts(12, c: AppColors.grey)),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: Db.messages(widget.tripId),
                builder: (context, snap) {
                  final msgs = snap.data ?? [];
                  if (msgs.isEmpty) {
                    return Center(child: Text('Say salaam to your driver', style: ts(14, c: AppColors.grey)));
                  }
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      for (final m in msgs)
                        Align(
                          alignment: m['from'] == 'passenger' ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: m['from'] == 'passenger' ? AppColors.red : AppColors.bg,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text('${m['text']}',
                                style: ts(14, c: m['from'] == 'passenger' ? Colors.white : AppColors.ink)),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Row(children: [
                Expanded(
                  child: TextField(
                    controller: _c,
                    decoration: InputDecoration(
                      hintText: 'Message',
                      filled: true,
                      fillColor: AppColors.bg,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  style: IconButton.styleFrom(backgroundColor: AppColors.red),
                  icon: const Icon(Icons.send_rounded, color: Colors.white),
                  onPressed: () {
                    final t = _c.text.trim();
                    if (t.isEmpty) return;
                    Db.sendMessage(widget.tripId, t);
                    _c.clear();
                  },
                ),
              ]),
            ),
          ]),
        ),
      );
}
