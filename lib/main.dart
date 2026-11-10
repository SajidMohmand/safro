import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  bool firebaseReady = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseReady = true;
  } catch (e) {
    debugPrint('Firebase.initializeApp() could not load config: $e');
  }

  runApp(SafroApp(firebaseReady: firebaseReady));
}

class SafroApp extends StatefulWidget {
  final bool firebaseReady;
  const SafroApp({super.key, this.firebaseReady = true});

  @override
  State<SafroApp> createState() => _SafroAppState();
}

class _SafroAppState extends State<SafroApp> {
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  late bool _firebaseReady = widget.firebaseReady;
  bool _retrying = false;

  Future<void> _retryInit() async {
    setState(() => _retrying = true);
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      setState(() {
        _firebaseReady = true;
        _retrying = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _retrying = false);
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('Firebase error: $e'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Safro',
        scaffoldMessengerKey: _scaffoldMessengerKey,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: _firebaseReady
            ? const SplashScreen()
            : _FirebaseSetupScreen(
                onRetry: _retryInit,
                retrying: _retrying,
              ),
      );
}

class _FirebaseSetupScreen extends StatelessWidget {
  final Future<void> Function() onRetry;
  final bool retrying;

  const _FirebaseSetupScreen({
    required this.onRetry,
    required this.retrying,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.redSoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.cloud_off_rounded, color: AppColors.red, size: 28),
              ),
              const SizedBox(height: 20),
              Text('Firebase Setup Required', style: ts(22, w: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(
                'Safro requires Firebase for Phone Authentication and Firestore. The app could not find google-services.json in android/app.',
                style: ts(13.5, c: AppColors.grey, h: 1.5),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  children: [
                    _step(
                      '1',
                      'Create or select a Firebase Project',
                      'Go to console.firebase.google.com and add an Android app with package name:\ncom.safro.safro',
                    ),
                    const SizedBox(height: 14),
                    _step(
                      '2',
                      'Download google-services.json',
                      'Place the file into:\nandroid/app/google-services.json',
                    ),
                    const SizedBox(height: 14),
                    _step(
                      '3',
                      'Enable Google Services Gradle Plugin',
                      'In android/app/build.gradle.kts plugins block, add:\nid("com.google.gms.google-services")',
                    ),
                    const SizedBox(height: 14),
                    _step(
                      '4',
                      'Rebuild and run',
                      'Stop the running app and run "flutter run".',
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: retrying ? null : onRetry,
                  child: retrying
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text('Retry Connection', style: ts(15, w: FontWeight.w600, c: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _step(String num, String title, String desc) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 13,
              backgroundColor: AppColors.red,
              child: Text(num, style: ts(11, w: FontWeight.w700, c: Colors.white)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: ts(14, w: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(desc, style: ts(12, c: AppColors.grey, h: 1.4)),
                ],
              ),
            ),
          ],
        ),
      );
}
