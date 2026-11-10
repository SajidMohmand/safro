import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../services/auth_service.dart';
import '../widgets/common.dart';
import 'otp_screen.dart';

class EnterMobileScreen extends StatefulWidget {
  const EnterMobileScreen({super.key});
  @override
  State<EnterMobileScreen> createState() => _EnterMobileScreenState();
}

class _EnterMobileScreenState extends State<EnterMobileScreen> {
  static const _codes = {
    '+92': '🇵🇰 +92',
    '+971': '🇦🇪 +971',
    '+966': '🇸🇦 +966',
    '+44': '🇬🇧 +44',
    '+1': '🇺🇸 +1',
  };
  String _code = '+92';
  final _ctrl = TextEditingController();
  bool _loading = false;

  String get _digits {
    var d = _ctrl.text.replaceAll(RegExp(r'\D'), '');
    if (_code == '+92' && d.startsWith('0')) d = d.substring(1);
    return d;
  }

  bool get _valid {
    final n = _digits;
    if (_code == '+92') return RegExp(r'^3\d{9}$').hasMatch(n); // e.g. 3001212211
    return n.length >= 7 && n.length <= 12;
  }

  Future<void> _send() async {
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    final national = _digits;
    try {
      await AuthService.sendCode(
        phone: '$_code$national',
        onCodeSent: (vid) {
          if (!mounted) return;
          setState(() => _loading = false);
          Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => OtpScreen(
                  phone: '$_code$national',
                  display: prettyPhone(_code, national),
                  verificationId: vid)));
        },
        onError: (m) {
          if (!mounted) return;
          setState(() => _loading = false);
          showSnack(context, m, error: true);
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        showSnack(context, e.toString(), error: true);
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
          child: Column(children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(color: AppColors.redSoft, borderRadius: BorderRadius.circular(18)),
                    child: const Icon(Icons.phone_iphone_rounded, color: AppColors.red, size: 30),
                  ),
                  const SizedBox(height: 26),
                  Text('Enter your\nmobile number', style: ts(36, w: FontWeight.w800, h: 1.15, ls: -.5)),
                  const SizedBox(height: 34),
                  Container(
                    height: 70,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.line, width: 1.6),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(children: [
                      DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _code,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded),
                          style: ts(20, w: FontWeight.w700),
                          items: _codes.entries
                              .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                              .toList(),
                          onChanged: (v) => setState(() => _code = v ?? '+92'),
                        ),
                      ),
                      Container(width: 1.5, height: 32, color: AppColors.line, margin: const EdgeInsets.symmetric(horizontal: 12)),
                      Expanded(
                        child: TextField(
                          controller: _ctrl,
                          autofocus: true,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(12),
                          ],
                          onChanged: (_) => setState(() {}),
                          style: ts(28, w: FontWeight.w700, ls: 1.5),
                          cursorColor: AppColors.red,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: '3001212211',
                            hintStyle: ts(28, w: FontWeight.w600, c: const Color(0xFFD1D5DB), ls: 1.5),
                          ),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    "We'll send a ${AppConfig.otpLength}-digit code by SMS. Safro is for women aged 18 and over.",
                    style: ts(14, c: AppColors.grey, h: 1.5),
                  ),
                ]),
              ),
            ),
            PrimaryButton(label: 'Send code', loading: _loading, onPressed: _valid ? _send : null),
          ]),
        ),
      ),
    );
  }
}
