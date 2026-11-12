import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../models/models.dart';
import '../services/db.dart';
import '../widgets/common.dart';
import 'main_shell.dart';
import 'search_place_screen.dart';

/// "Meri Driver" monthly plan (brief P19 / section 8): fixed route, time,
/// weekdays and driver, paid monthly in advance. Stored in plans/{uid}.
class PlansTab extends StatefulWidget {
  const PlansTab({super.key});
  @override
  State<PlansTab> createState() => _PlansTabState();
}

class _PlansTabState extends State<PlansTab> {
  static const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final String _uid = FirebaseAuth.instance.currentUser!.uid;

  List<DriverInfo> _drivers = [];
  DriverInfo? _driver;
  Place _pickup = Places.home;
  Place _drop = Places.university;
  final Set<int> _days = {0, 1, 2, 3, 4, 5};
  int _minutes = 7 * 60 + 30;
  bool _active = false;
  bool _saving = false;
  StreamSubscription<PlanModel?>? _sub;

  @override
  void initState() {
    super.initState();
    _load();
    AppNav.selectedDriver.addListener(_onDriverPicked);
  }

  Future<void> _load() async {
    final d = await DriverRepo.load();
    if (!mounted) return;
    setState(() {
      _drivers = d;
      _driver ??= d.isNotEmpty ? d.first : null;
    });
    _sub = Db.planStream(_uid).listen((p) {
      if (p == null || !mounted) return;
      setState(() {
        _pickup = p.pickup;
        _drop = p.drop;
        _days
          ..clear()
          ..addAll(p.days);
        _minutes = p.minutes;
        _active = p.active;
        final match = _drivers.where((x) => x.id == p.driverId);
        if (match.isNotEmpty) _driver = match.first;
      });
    });
  }

  void _onDriverPicked() {
    final d = AppNav.selectedDriver.value;
    if (d != null && !_active && mounted) setState(() => _driver = d);
  }

  @override
  void dispose() {
    AppNav.selectedDriver.removeListener(_onDriverPicked);
    _sub?.cancel();
    super.dispose();
  }

  int get _price {
    final base = _driver?.monthlyPrice ?? 7500;
    // 7,500 is the price for the default 6 days a week; scale for other counts.
    return ((base * _days.length / 6) / 50).round() * 50;
  }

  Map<String, dynamic> _data(bool active) => {
        'driverId': _driver?.id,
        'driverName': _driver?.name,
        'pickup': _pickup.toMap(),
        'drop': _drop.toMap(),
        'days': (_days.toList()..sort()),
        'minutes': _minutes,
        'price': _price,
        'active': active,
        'payment': 'monthly_in_advance',
      };

  Future<void> _toggle() async {
    if (_active) {
      final stop = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Pause your plan?', style: ts(18, w: FontWeight.w700)),
          content: Text('Your driver will no longer be booked for these days.', style: ts(14, c: AppColors.grey)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep plan')),
            TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Pause', style: TextStyle(color: AppColors.red))),
          ],
        ),
      );
      if (stop == true) await Db.savePlan(_uid, _data(false));
      return;
    }
    if (_days.isEmpty) {
      showSnack(context, 'Pick at least one day', error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      await Db.savePlan(_uid, _data(true));
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    }
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _pickPlace(bool pickup) async {
    if (_active) return;
    final p = await Navigator.push<Place>(
        context, MaterialPageRoute(builder: (_) => SearchPlaceScreen(hint: pickup ? 'Pickup' : 'Drop')));
    if (p != null) setState(() => pickup ? _pickup = p : _drop = p);
  }

  Future<void> _pickDriver() async {
    if (_active) return;
    final d = await showModalBottomSheet<DriverInfo>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 12),
          const SheetHandle(),
          for (final d in _drivers)
            ListTile(
              leading: Avatar(d.name),
              title: Text(d.name, style: ts(16, w: FontWeight.w700, c: AppColors.planTextDark)),
              subtitle: Text('${d.rating} • ${d.trips} trips • ${d.car}', style: ts(12.5, c: AppColors.grey)),
              onTap: () => Navigator.pop(context, d),
            ),
          const SizedBox(height: 10),
        ]),
      ),
    );
    if (d != null) setState(() => _driver = d);
  }

  Future<void> _pickTime() async {
    if (_active) return;
    final t = await showTimePicker(
        context: context, initialTime: TimeOfDay(hour: _minutes ~/ 60, minute: _minutes % 60));
    if (t != null) setState(() => _minutes = t.hour * 60 + t.minute);
  }

  void _step(int delta) {
    if (_active) return;
    setState(() => _minutes = (_minutes + delta + 1440) % 1440);
  }

  @override
  Widget build(BuildContext context) {
    final name = _driver?.name ?? '...';
    final time = TimeOfDay(hour: _minutes ~/ 60, minute: _minutes % 60).format(context);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        children: [
          Text('Meri Driver', style: ts(30, w: FontWeight.w800, ls: -.5, c: AppColors.planTextDark)),
          const SizedBox(height: 18),

          // Fixed driver
          AppCard(
            onTap: _pickDriver,
            color: AppColors.planCardDark,
            borderColor: Colors.transparent,
            child: Row(children: [
              Avatar(name, size: 54, bg: Colors.white, fg: AppColors.planCardDark),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name, style: ts(18, w: FontWeight.w700, c: Colors.white)),
                  Text('Your fixed driver', style: ts(13, c: Colors.white.withOpacity(0.75))),
                ]),
              ),
              if (!_active) const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70),
            ]),
          ),
          const SizedBox(height: 14),

          // Route
          PickupDropCard(
            pickup: _pickup.name,
            drop: _drop.name,
            onPickupTap: () => _pickPlace(true),
            onDropTap: () => _pickPlace(false),
            pickupCircleColor: AppColors.planCardDark,
            textColor: AppColors.planTextDark,
          ),
          const SizedBox(height: 14),

          // Days + time
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Days', style: ts(15, w: FontWeight.w700, c: AppColors.planTextDark)),
              const SizedBox(height: 12),
              Row(children: [
                for (var i = 0; i < 7; i++)
                  Expanded(
                    child: GestureDetector(
                      onTap: _active
                          ? null
                          : () => setState(() => _days.contains(i) ? _days.remove(i) : _days.add(i)),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        height: 44,
                        margin: const EdgeInsets.symmetric(horizontal: 2.5),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _days.contains(i) ? AppColors.planSelectedDay : AppColors.planUnselectedDay,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: _days.contains(i) ? AppColors.planSelectedDay : Colors.transparent,
                              width: 1.4),
                        ),
                        child: Text(_dayNames[i],
                            style: ts(11.5,
                                w: FontWeight.w700,
                                c: _days.contains(i) ? Colors.white : AppColors.planTextDark)),
                      ),
                    ),
                  ),
              ]),
              const SizedBox(height: 20),
              Text('Pickup time', style: ts(15, w: FontWeight.w700, c: AppColors.grey)),
              const SizedBox(height: 10),
              Row(children: [
                _circleBtn(Icons.remove_rounded, () => _step(-15)),
                Expanded(
                  child: GestureDetector(
                    onTap: _pickTime,
                    child: Center(child: Text(time, style: ts(30, w: FontWeight.w800, c: AppColors.planTextDark))),
                  ),
                ),
                _circleBtn(Icons.add_rounded, () => _step(15)),
              ]),
            ]),
          ),
          const SizedBox(height: 14),

          // Price
          AppCard(
            child: Row(children: [
              Expanded(child: Text('Per month paid in\nadvance', style: ts(15, w: FontWeight.w600, h: 1.35, c: AppColors.planTextDark))),
              Text('PKR\n${money(_price)}', textAlign: TextAlign.right, style: ts(20, w: FontWeight.w800, h: 1.2, c: AppColors.planTextDark)),
            ]),
          ),
          const SizedBox(height: 22),

          PrimaryButton(
            label: _active ? 'Plan active' : 'Start plan',
            color: _active ? AppColors.planActiveBtn : AppColors.red,
            loading: _saving,
            onPressed: _driver == null ? null : _toggle,
          ),
        ],
      ),
    );
  }

  Widget _circleBtn(IconData i, VoidCallback onTap) => InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.line, width: 1.6)),
          child: Icon(i, size: 24, color: AppColors.planTextDark),
        ),
      );
}
