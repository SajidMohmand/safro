import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../services/db.dart';
import 'enter_mobile_screen.dart';
import 'main_shell.dart';
import 'profile_setup_screen.dart';

/// Signed out -> mobile screen. Signed in without a name -> profile setup.
/// Signed in with a name -> the app.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const _Loader();
          final u = snap.data;
          if (u == null) return const EnterMobileScreen();
          return ProfileGate(key: ValueKey(u.uid), user: u);
        },
      );
}

class ProfileGate extends StatefulWidget {
  final User user;
  const ProfileGate({super.key, required this.user});
  @override
  State<ProfileGate> createState() => _ProfileGateState();
}

class _ProfileGateState extends State<ProfileGate> {
  late Future<void> _init = Db.ensureUser(widget.user);

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
        future: _init,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const _Loader();
          if (snap.hasError) {
            return Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('Could not load your account.\nCheck your connection and Firestore rules.',
                        textAlign: TextAlign.center, style: ts(15, c: AppColors.grey)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                        onPressed: () => setState(() => _init = Db.ensureUser(widget.user)),
                        child: const Text('Try again')),
                  ]),
                ),
              ),
            );
          }
          return StreamBuilder<UserProfile?>(
            stream: Db.userStream(widget.user.uid),
            builder: (context, s) {
              final p = s.data;
              if (p == null) return const _Loader();
              if (p.name.trim().isEmpty) return ProfileSetupScreen(uid: p.uid);
              return MainShell(profile: p);
            },
          );
        },
      );
}

class _Loader extends StatelessWidget {
  const _Loader();
  @override
  Widget build(BuildContext context) => const Scaffold(
      body: Center(child: CircularProgressIndicator(color: AppColors.red)));
}
