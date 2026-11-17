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
  static const _codes = [
    '+92',
    '+971',
    '+966',
    '+44',
    '+1',
  ];
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
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final isSmallScreen = screenWidth < 360 || screenHeight < 650;

    final horizontalPadding = isSmallScreen ? 16.0 : 24.0;
    final inputFontSize = screenWidth < 360 ? 19.0 : (screenWidth < 400 ? 21.0 : 22.0);
    final inputLetterSpacing = screenWidth < 360 ? 0.6 : 1.0;
    final inputHeight = isSmallScreen ? 58.0 : 62.0;

    return Scaffold(
      backgroundColor: AppColors.creamBg,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.translucent,
          child: Padding(
            padding: EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, 20),
            child: Column(children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      width: isSmallScreen ? 68 : 80,
                      height: isSmallScreen ? 68 : 80,
                      decoration: BoxDecoration(
                        color: AppColors.red,
                        borderRadius: BorderRadius.circular(isSmallScreen ? 18 : 22),
                      ),
                      child: Center(
                        child: Icon(Icons.verified_user_outlined,
                            color: Colors.white, size: isSmallScreen ? 38 : 45),
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 20 : 26),
                    Text('Enter your\nmobile number',
                        style: ts(isSmallScreen ? 28 : 34, w: FontWeight.w800, h: 1.15, ls: -.5)),
                    SizedBox(height: isSmallScreen ? 24 : 32),
                    MediaQuery.withClampedTextScaling(
                      maxScaleFactor: 1.2,
                      child: Container(
                        height: inputHeight,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.line, width: 1.5),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Row(children: [
                          Container(
                            height: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            color: AppColors.lilacBg,
                            child: Center(
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _code,
                                  icon: const Icon(Icons.keyboard_arrow_down_rounded,
                                      size: 18, color: AppColors.ink),
                                  style: ts(16, w: FontWeight.w700, c: AppColors.ink),
                                  dropdownColor: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  isDense: true,
                                  items: _codes
                                      .map((code) => DropdownMenuItem(
                                            value: code,
                                            child: Text(code,
                                                style: ts(15, w: FontWeight.w600, c: AppColors.ink)),
                                          ))
                                      .toList(),
                                  onChanged: (v) => setState(() => _code = v ?? '+92'),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              child: TextField(
                                controller: _ctrl,
                                autofocus: true,
                                keyboardType: TextInputType.phone,
                                textAlignVertical: TextAlignVertical.center,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(12),
                                ],
                                onChanged: (_) => setState(() {}),
                                style: ts(inputFontSize, w: FontWeight.w600, ls: inputLetterSpacing),
                                cursorColor: AppColors.red,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: '3001212211',
                                  hintStyle: ts(inputFontSize,
                                      w: FontWeight.w500,
                                      c: const Color(0xFFD1D5DB),
                                      ls: inputLetterSpacing),
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                          ),
                        ]),
                      ),
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
      ),
    );
  }
}
