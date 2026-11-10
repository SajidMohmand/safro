import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../services/db.dart';
import '../widgets/common.dart';

/// One-time step after the first sign-in: name + women-only / 18+ confirmation
/// and acceptance of the terms (stored with a time stamp, brief section 10).
class ProfileSetupScreen extends StatefulWidget {
  final String uid;
  const ProfileSetupScreen({super.key, required this.uid});
  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _name = TextEditingController();
  bool _ok = false;
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await Db.setName(widget.uid, _name.text);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        showSnack(context, e.toString(), error: true);
      }
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final can = _name.text.trim().length >= 2 && _ok;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Salaam!\nWhat is your name?', style: ts(34, w: FontWeight.w800, h: 1.15, ls: -.5)),
                  const SizedBox(height: 10),
                  Text('Your driver will see your first name only.', style: ts(14.5, c: AppColors.grey)),
                  const SizedBox(height: 28),
                  TextField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    onChanged: (_) => setState(() {}),
                    style: ts(22, w: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: 'Your name',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.red, width: 2)),
                    ),
                  ),
                  const SizedBox(height: 22),
                  InkWell(
                    onTap: () => setState(() => _ok = !_ok),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Checkbox(
                          value: _ok,
                          activeColor: AppColors.red,
                          onChanged: (v) => setState(() => _ok = v ?? false)),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                              'I am a woman aged 18 or over, and I accept the Terms and Privacy Policy.',
                              style: ts(13.5, c: AppColors.grey, h: 1.45)),
                        ),
                      ),
                    ]),
                  ),
                ]),
              ),
            ),
            PrimaryButton(label: 'Continue', loading: _saving, onPressed: can ? _save : null),
          ]),
        ),
      ),
    );
  }
}
