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

  Widget _box(int i, double w, double h) {
    final filled = i < _code.length;
    final active = i == _code.length;
    return Container(
      width: w,
      height: h,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: active
              ? AppColors.verifyRed
              : (filled ? AppColors.verifyRed.withOpacity(.5) : AppColors.line),
          width: active ? 2.0 : 1.5,
        ),
      ),
      child: Text(
        filled ? _code[i] : '',
        style: ts(24, w: FontWeight.w700, c: AppColors.numberDark),
      ),
    );
  }

  Widget _padKey(String label,
          {IconData? icon, required VoidCallback? onTap, required double height}) =>
      Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Material(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.line, width: 1.5),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: SizedBox(
                height: height,
                child: Center(
                  child: icon != null
                      ? Icon(icon, size: 24, color: AppColors.numberDark)
                      : Text(label, style: ts(24, w: FontWeight.w700, c: AppColors.numberDark)),
                ),
              ),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final isSmallScreen = screenHeight < 680 || screenWidth < 360;

    final horizontalPadding = isSmallScreen ? 16.0 : 24.0;
    final gap = isSmallScreen ? 8.0 : 10.0;
    final availableWidth = screenWidth - (horizontalPadding * 2);
    final boxW = (availableWidth - (gap * (_len - 1))) / _len;
    final boxH = isSmallScreen ? 56.0 : 64.0;
    final keyHeight = isSmallScreen ? 48.0 : 54.0;

    final rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
    ];

    return Scaffold(
      backgroundColor: AppColors.creamBg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(horizontalPadding, 8, horizontalPadding, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          alignment: Alignment.centerLeft,
                          icon: const Icon(Icons.arrow_back_ios_new_rounded,
                              size: 24, color: AppColors.numberDark),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        SizedBox(height: isSmallScreen ? 6 : 10),
                        Text('Enter the code',
                            style: ts(isSmallScreen ? 30 : 36,
                                w: FontWeight.w800, ls: -.5, c: AppColors.numberDark)),
                        const SizedBox(height: 8),
                        Text.rich(TextSpan(style: ts(15, c: AppColors.grey), children: [
                          const TextSpan(text: 'Sent to '),
                          TextSpan(
                              text: widget.display,
                              style: ts(15, w: FontWeight.w700, c: AppColors.numberDark)),
                        ])),
                        SizedBox(height: isSmallScreen ? 20 : 28),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (var i = 0; i < _len; i++) ...[
                              _box(i, boxW, boxH),
                              if (i < _len - 1) SizedBox(width: gap),
                            ],
                          ],
                        ),
                        SizedBox(height: isSmallScreen ? 16 : 22),
                        Center(
                          child: _secs > 0
                              ? Text('Resend code in 0:${_secs.toString().padLeft(2, '0')}',
                                  style: ts(14, c: AppColors.grey))
                              : TextButton(
                                  onPressed: _resend,
                                  child: Text('Resend code',
                                      style: ts(15, w: FontWeight.w700, c: AppColors.verifyRed))),
                        ),
                        const Spacer(),
                        for (final r in rows)
                          Row(children: [
                            for (final k in r)
                              _padKey(k, height: keyHeight, onTap: () => _key(k)),
                          ]),
                        Row(children: [
                          const Expanded(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                              child: SizedBox(),
                            ),
                          ),
                          _padKey('0', height: keyHeight, onTap: () => _key('0')),
                          _padKey('',
                              height: keyHeight,
                              icon: Icons.backspace_outlined,
                              onTap: () => _key('del')),
                        ]),
                        SizedBox(height: isSmallScreen ? 10 : 14),
                        PrimaryButton(
                          label: 'Verify',
                          color: AppColors.verifyRed,
                          loading: _loading,
                          onPressed: _code.length == _len ? _verify : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
