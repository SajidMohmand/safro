import 'dart:async';
import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../services/db.dart';

/// Full red screen shown after the SOS button is held for 3 seconds.
/// Pops with `true` when the passenger cancels ("I am safe").
class SosScreen extends StatefulWidget {
  final String alertId;
  final String followers; // "Ammi and Sara"
  const SosScreen({super.key, required this.alertId, required this.followers});
  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> {
  int _secs = 1;
  Timer? _t;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _secs++);
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  Future<void> _cancel() async {
    setState(() => _busy = true);
    try {
      await Db.cancelSos(widget.alertId).timeout(const Duration(seconds: 5));
    } catch (_) {}
    if (mounted) Navigator.pop(context, true);
  }

  Widget _row(IconData icon, String text) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(color: Colors.white.withOpacity(.18), borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(width: 14),
          Expanded(child: Text(text, style: ts(15, w: FontWeight.w600, c: Colors.white))),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final mm = (_secs ~/ 60).toString();
    final ss = (_secs % 60).toString().padLeft(2, '0');
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.redDark,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 92,
                height: 92,
                decoration: const BoxDecoration(color: AppColors.milk, shape: BoxShape.circle),
                child: const Icon(Icons.sos_rounded, size: 52, color: AppColors.redDark),
              ),
              const SizedBox(height: 22),
              Text('SOS sent', style: ts(44, w: FontWeight.w800, c: Colors.white, ls: -1)),
              const Spacer(),
              _row(Icons.check_circle_rounded, 'Support team alerted'),
              _row(Icons.check_circle_rounded,
                  widget.followers.isEmpty ? 'Your live location was sent' : '${widget.followers} have your live location'),
              _row(Icons.call_rounded, 'An agent is calling you  $mm:$ss'),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _busy ? null : _cancel,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.milk,
                    foregroundColor: AppColors.redDark,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    textStyle: ts(17, w: FontWeight.w800),
                  ),
                  child: const Text('I am safe, cancel alert'),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
