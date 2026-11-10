import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../models/models.dart';
import '../services/db.dart';
import '../widgets/common.dart';

class RatingScreen extends StatefulWidget {
  final TripModel trip;
  const RatingScreen({super.key, required this.trip});
  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  int _stars = 5;
  final Set<String> _tags = {};
  bool _saving = false;

  Future<void> _done() async {
    setState(() => _saving = true);
    try {
      await Db.updateTrip(widget.trip.id, {
        'rating': _stars,
        'tags': _tags.toList(),
        'ratedAt': DateTime.now().toIso8601String(),
      }).timeout(const Duration(seconds: 8));
    } catch (_) {}
    if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  Future<void> _report() async {
    final c = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Report a problem', style: ts(18, w: FontWeight.w700)),
        content: TextField(controller: c, maxLines: 4, decoration: const InputDecoration(hintText: 'Tell us what happened')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, c.text.trim()),
              child: const Text('Send', style: TextStyle(color: AppColors.red))),
        ],
      ),
    );
    if (text == null || text.isEmpty) return;
    try {
      final n = await Db.createTicket(widget.trip.id, text);
      if (mounted) showSnack(context, 'Thank you. Ticket $n created.');
    } catch (_) {
      if (mounted) showSnack(context, 'Could not send. Try again.', error: true);
    }
  }

  Widget _tag(String t) {
    final sel = _tags.contains(t);
    return GestureDetector(
      onTap: () => setState(() => sel ? _tags.remove(t) : _tags.add(t)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
        decoration: BoxDecoration(
          color: sel ? AppColors.redSoft : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: sel ? AppColors.red : AppColors.line, width: 1.6),
        ),
        child: Text(t, style: ts(15, w: FontWeight.w600, c: sel ? AppColors.red : AppColors.ink)),
      ),
    );
  }

  Widget _line(String l, String r) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(children: [
          Expanded(child: Text(l, style: ts(15, c: AppColors.grey))),
          Text(r, style: ts(15, w: FontWeight.w700)),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final t = widget.trip;
    final who = t.followers.isEmpty ? null : t.followers.join(' and ');
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
            child: Column(children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 92,
                      height: 92,
                      decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle),
                      child: const Icon(Icons.check_rounded, color: Colors.white, size: 56),
                    ),
                    const SizedBox(height: 18),
                    Text('Safely arrived', style: ts(30, w: FontWeight.w800, ls: -.5)),
                    const SizedBox(height: 14),
                    if (who != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                        decoration: BoxDecoration(color: AppColors.greenSoft, borderRadius: BorderRadius.circular(30)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.ios_share_rounded, size: 18, color: AppColors.green),
                          const SizedBox(width: 8),
                          Text('$who were told', style: ts(13.5, w: FontWeight.w600, c: AppColors.green)),
                        ]),
                      ),
                    const SizedBox(height: 20),
                    AppCard(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      child: Column(children: [
                        _line('Fare', 'PKR ${money(t.fare)}'),
                        _line('Paid', t.payment),
                        _line('Receipt', t.receiptNo),
                      ]),
                    ),
                    const SizedBox(height: 22),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      for (var i = 1; i <= 5; i++)
                        GestureDetector(
                          onTap: () => setState(() => _stars = i),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(i <= _stars ? Icons.star_rounded : Icons.star_outline_rounded,
                                size: 46, color: AppColors.yellow),
                          ),
                        ),
                    ]),
                    const SizedBox(height: 22),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      _tag('Polite'),
                      const SizedBox(width: 10),
                      _tag('Clean car'),
                    ]),
                    const SizedBox(height: 10),
                    Row(mainAxisAlignment: MainAxisAlignment.start, children: [_tag('Safe driving')]),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: _report,
                      child: Text('Report a problem', style: ts(14, w: FontWeight.w600, c: AppColors.grey)),
                    ),
                  ]),
                ),
              ),
              PrimaryButton(label: 'Done', loading: _saving, onPressed: _done),
            ]),
          ),
        ),
      ),
    );
  }
}
