import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import 'auth_gate.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2400), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => const AuthGate(),
        transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
      ));
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: CurvedAnimation(parent: _c, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: Tween(begin: .9, end: 1.0).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutBack)),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  color: AppColors.red,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [BoxShadow(color: AppColors.red.withOpacity(.3), blurRadius: 28, offset: const Offset(0, 12))],
                ),
                child: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 58),
              ),
              const SizedBox(height: 26),
              Text(AppConfig.appName, style: ts(54, w: FontWeight.w800, ls: -1.5, h: 1.1)),
              const SizedBox(height: 8),
              Text(AppConfig.tagline, style: ts(15, c: AppColors.grey)),
            ]),
          ),
        ),
      ),
    );
  }
}
