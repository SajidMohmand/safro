import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/db.dart';
import '../widgets/common.dart';

class SafetyTab extends StatelessWidget {
  final UserProfile profile;
  const SafetyTab({super.key, required this.profile});

  Future<void> _addContact(BuildContext context, int count) async {
    if (count >= 3) {
      showSnack(context, 'You can add up to 3 trusted contacts.', error: true);
      return;
    }
    final name = TextEditingController();
    final phone = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SheetHandle(),
          Text('Add trusted contact', style: ts(20, w: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('They get a link to follow your trip. No app needed.', style: ts(13, c: AppColors.grey)),
          const SizedBox(height: 16),
          TextField(
              controller: name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Name (e.g. Ammi)', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(
              controller: phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Mobile number', prefixText: '+92 ', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Save contact',
            onPressed: () async {
              if (name.text.trim().isEmpty) return;
              await Db.addContact(profile.uid, name.text.trim(), phone.text.trim());
              if (ctx.mounted) Navigator.pop(ctx);
            },
          ),
        ]),
      ),
    );
  }

  Widget _statusRow(IconData icon, String title, String sub,
          {Widget? trailing, Color? iconColor}) =>
      Row(children: [
        Container(
          width: 30,
          alignment: Alignment.centerLeft,
          child: Icon(icon, color: iconColor ?? const Color(0xFF2B2145), size: 26),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: ts(16, w: FontWeight.w700, c: const Color(0xFF2B2145))),
            const SizedBox(height: 2),
            Text(sub, style: ts(12.5, c: AppColors.grey, h: 1.4)),
          ]),
        ),
        if (trailing != null) trailing,
      ]);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8F3EE),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          children: [
            Text('Safety', style: ts(30, w: FontWeight.w800, ls: -.5, c: const Color(0xFF2B2145))),
            const SizedBox(height: 18),

            // Trusted contacts
            StreamBuilder<List<Contact>>(
              stream: Db.contacts(profile.uid),
              builder: (context, snap) {
                final list = snap.data ?? [];
                return AppCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Trusted contacts', style: ts(16, w: FontWeight.w700, c: AppColors.grey)),
                    const SizedBox(height: 12),
                    for (final c in list)
                      InkWell(
                        onLongPress: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: Text('Remove ${c.name}?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
                                TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('Remove', style: TextStyle(color: AppColors.red))),
                              ],
                            ),
                          );
                          if (ok == true) await Db.removeContact(profile.uid, c.id);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          child: Row(children: [
                            Avatar(
                              c.name,
                              size: 44,
                              bg: const Color(0xFFE8DCF1),
                              fg: const Color(0xFF2B1E3F),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                c.name,
                                style: ts(16, w: FontWeight.w700, c: const Color(0xFF2B2145)),
                              ),
                            ),
                            const Pill(
                              'Follows trips',
                              bg: Color(0xFFDCEFEB),
                              fg: Color(0xFF117770),
                              weight: FontWeight.w700,
                            ),
                          ]),
                        ),
                      ),
                    const SizedBox(height: 10),
                    BorderButton(
                      label: 'Add Contact',
                      textColor: const Color(0xFF2B1E3F),
                      borderColor: const Color(0xFF2B1E3F),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      onPressed: () => _addContact(context, list.length),
                    ),
                    const SizedBox(height: 4),
                    Center(child: Text('Long-press a contact to remove', style: ts(11.5, c: AppColors.grey))),
                  ]),
                );
              },
            ),
            const SizedBox(height: 14),

            // Share every trip
            AppCard(
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Share every trip\nautomatically',
                        style: ts(16, w: FontWeight.w700, h: 1.3, c: const Color(0xFF2B2145))),
                    const SizedBox(height: 4),
                    Text('Contact get a link, no app needed', style: ts(12.5, c: AppColors.grey)),
                  ]),
                ),
                Switch.adaptive(
                  value: profile.shareEveryTrip,
                  thumbColor: WidgetStateProperty.all(Colors.white),
                  activeColor: Colors.white,
                  activeTrackColor: const Color(0xFF117770),
                  trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
                  onChanged: (v) => Db.setShareEvery(profile.uid, v),
                ),
              ]),
            ),
            const SizedBox(height: 14),

            AppCard(
              child: _statusRow(
                Icons.lock_outline_rounded,
                'Ride PIN',
                'New code every trip.\nAlways on.',
                trailing: const Pill(
                  'On',
                  bg: Color(0xFFDCEFEB),
                  fg: Color(0xFF117770),
                  weight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 14),
            AppCard(
              child: _statusRow(
                Icons.call_outlined,
                'Masked calls',
                'Your number is never shown',
                trailing: const Pill(
                  'On',
                  bg: Color(0xFFDCEFEB),
                  fg: Color(0xFF117770),
                  weight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // SOS
            AppCard(
              color: const Color(0xFFF8E6E2),
              borderColor: Colors.transparent,
              onTap: () => showSnack(context, 'During a trip, hold the SOS button for 3 seconds.'),
              child: _statusRow(
                Icons.verified_user_outlined,
                'SOS',
                'Reaches a real person in our support team.',
                iconColor: Colors.red,
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: TextButton(
                onPressed: AuthService.signOut,
                child: Text('Log out', style: ts(14, w: FontWeight.w600, c: AppColors.grey)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
