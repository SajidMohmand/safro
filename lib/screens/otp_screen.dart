import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../services/auth_service.dart';
import '../widgets/common.dart';

class OtpScreen extends StatefulWidget {
  final String phone; // +923001212211
  final String display; // +92 300 1212211
  final String verificationId;
  const OtpScreen({super.key, required this.phone, required this.display, required this.verificationId});
  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  static const _len = AppConfig.otpLength;
  late String _vid = widget.verificationId;
  String _code = '';
  int _secs = 30;
  Timer? _timer;
  bool _loading = false;
  StreamSubscription<User?>? _authSub;

  @override
  void initState() {
    super.initState();
    _startTimer();
    // If Android reads the SMS automatically, we get signed in without typing:
    // close this screen and let AuthGate show the app.
    _authSub = FirebaseAuth.instance.authStateChanges().listen((u) {
      if (u != null && mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _secs = 30;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secs <= 1) {
        t.cancel();
      }
      if (mounted) setState(() => _secs = _secs > 0 ? _secs - 1 : 0);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _authSub?.cancel();
    super.dispose();
  }

  void _key(String k) {
    HapticFeedback.selectionClick();
    setState(() {
      if (k == 'del') {
        if (_code.isNotEmpty) _code = _code.substring(0, _code.length - 1);
      } else if (_code.length < _len) {
        _code += k;
      }
    });
  }

  Future<void> _verify() async {
    setState(() => _loading = true);
    try {
      await AuthService.verify(_vid, _code);
      // authStateChanges listener closes this screen.
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _code = '';
      });
      showSnack(context,
          e.code == 'invalid-verification-code' ? 'That code is not right. Try again.' : (e.message ?? e.code),
          error: true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      showSnack(context, e.toString(), error: true);
    }
  }

  Future<void> _resend() async {
    _startTimer();
    setState(() => _code = '');
    await AuthService.sendCode(
      phone: widget.phone,
      onCodeSent: (vid) {
        _vid = vid;
        if (mounted) showSnack(context, 'New code sent');
      },
      onError: (m) {
        if (mounted) showSnack(context, m, error: true);
      },
    );
  }

  Widget _box(int i, double w) {
    final filled = i < _code.length;
    final active = i == _code.length;
    return Container(
      width: w,
      height: 74,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: filled ? AppColors.redSoft : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: active ? AppColors.red : (filled ? AppColors.red.withOpacity(.4) : AppColors.line), width: active ? 2.2 : 1.6),
      ),
      child: Text(filled ? _code[i] : '', style: ts(_len <= 4 ? 36 : 28, w: FontWeight.w800)),
    );
  }

  Widget _padKey(String label, {IconData? icon, required VoidCallback? onTap}) => Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: SizedBox(
            height: 58,
            child: Center(
              child: icon != null
                  ? Icon(icon, size: 28, color: AppColors.ink)
                  : Text(label, style: ts(28, w: FontWeight.w600)),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    const gap = 10.0;
    final boxW = (w - 48 - gap * (_len - 1)) / _len;
    final rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
    ];
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            IconButton(
              padding: EdgeInsets.zero,
              alignment: Alignment.centerLeft,
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 24),
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: 10),
            Text('Enter the code', style: ts(36, w: FontWeight.w800, ls: -.5)),
            const SizedBox(height: 10),
            Text.rich(TextSpan(style: ts(15, c: AppColors.grey), children: [
              const TextSpan(text: 'Sent to '),
              TextSpan(text: widget.display, style: ts(15, w: FontWeight.w700)),
            ])),
            const SizedBox(height: 28),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              for (var i = 0; i < _len; i++) _box(i, boxW),
            ]),
            const SizedBox(height: 22),
            Center(
              child: _secs > 0
                  ? Text('Resend code in 0:${_secs.toString().padLeft(2, '0')}', style: ts(14, c: AppColors.grey))
                  : TextButton(
                      onPressed: _resend,
                      child: Text('Resend code', style: ts(15, w: FontWeight.w700, c: AppColors.red))),
            ),
            const Spacer(),
            for (final r in rows)
              Row(children: [for (final k in r) _padKey(k, onTap: () => _key(k))]),
            Row(children: [
              const Expanded(child: SizedBox(height: 58)),
              _padKey('0', onTap: () => _key('0')),
              _padKey('', icon: Icons.backspace_outlined, onTap: () => _key('del')),
            ]),
            const SizedBox(height: 14),
            PrimaryButton(label: 'Verify', loading: _loading, onPressed: _code.length == _len ? _verify : null),
          ]),
        ),
      ),
    );
  }
}
