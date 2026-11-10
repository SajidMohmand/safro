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

  Widget _statusRow(IconData icon, String title, String sub, {Color? iconBg}) => Row(children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(color: iconBg ?? AppColors.redSoft, shape: BoxShape.circle),
          child: Icon(icon, color: AppColors.red, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: ts(16, w: FontWeight.w700)),
            Text(sub, style: ts(12.5, c: AppColors.grey, h: 1.4)),
          ]),
        ),
        const Pill('On'),
      ]);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        children: [
          Text('Safety', style: ts(30, w: FontWeight.w800, ls: -.5)),
          const SizedBox(height: 18),

          // Trusted contacts
          StreamBuilder<List<Contact>>(
            stream: Db.contacts(profile.uid),
            builder: (context, snap) {
              final list = snap.data ?? [];
              return AppCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Trusted contacts', style: ts(16, w: FontWeight.w700)),
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
                          Avatar(c.name, size: 44),
                          const SizedBox(width: 12),
                          Expanded(child: Text(c.name, style: ts(16, w: FontWeight.w600))),
                          const Pill('Follows trips'),
                        ]),
                      ),
                    ),
                  const SizedBox(height: 10),
                  BorderButton(label: 'Add Contact', onPressed: () => _addContact(context, list.length)),
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
                  Text('Share every trip\nautomatically', style: ts(16, w: FontWeight.w700, h: 1.3)),
                  const SizedBox(height: 4),
                  Text('Contact get a link, no app needed', style: ts(12.5, c: AppColors.grey)),
                ]),
              ),
              Switch.adaptive(
                value: profile.shareEveryTrip,
                activeColor: AppColors.green,
                onChanged: (v) => Db.setShareEvery(profile.uid, v),
              ),
            ]),
          ),
          const SizedBox(height: 14),

          AppCard(child: _statusRow(Icons.lock_rounded, 'Ride PIN', 'New code every trip.\nAlways on.')),
          const SizedBox(height: 14),
          AppCard(child: _statusRow(Icons.phone_in_talk_rounded, 'Masked calls', 'Your number is never shown')),
          const SizedBox(height: 14),

          // SOS
          AppCard(
            color: AppColors.redSoft,
            borderColor: AppColors.red.withOpacity(.35),
            onTap: () => showSnack(context, 'During a trip, hold the SOS button for 3 seconds.'),
            child: Row(children: [
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(color: AppColors.red, shape: BoxShape.circle),
                child: const Icon(Icons.sos_rounded, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('SOS', style: ts(16, w: FontWeight.w800, c: AppColors.redDark)),
                  Text('Reaches a real person in our support team.', style: ts(12.5, c: AppColors.redDark, h: 1.4)),
                ]),
              ),
            ]),
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
    );
  }
}
