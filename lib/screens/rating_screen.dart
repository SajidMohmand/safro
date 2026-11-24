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
  int _stars = 0;
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

      if (widget.trip.driver != null && widget.trip.driver!.id.isNotEmpty) {
        await Db.recordDriverReview(
          driverId: widget.trip.driver!.id,
          rating: _stars,
          tags: _tags.toList(),
        );
      }
    } catch (_) {}
    if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  // ignore: unused_element
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
          color: sel ? const Color(0xFF2A163F) : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: sel ? const Color(0xFF2A163F) : const Color(0xFFD8D2C9),
            width: 1.5,
          ),
        ),
        child: Text(
          t,
          style: ts(
            15,
            w: FontWeight.w700,
            c: sel ? Colors.white : const Color(0xFF271937),
          ),
        ),
      ),
    );
  }

  Widget _line(String l, String r) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(children: [
          Expanded(child: Text(l, style: ts(15, c: AppColors.grey))),
          Text(r, style: ts(15, w: FontWeight.w700, c: AppColors.ink)),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final t = widget.trip;
    final who = t.followers.isEmpty ? null : t.followers.join(' and ');
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F3EE),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
            child: Column(children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 110,
                      height: 110,
                      decoration: const BoxDecoration(color: Color(0xFF117770), shape: BoxShape.circle),
                      child: const Icon(Icons.check_rounded, color: Colors.white, size: 56),
                    ),
                    const SizedBox(height: 18),
                    Text('Safely arrived', style: ts(30, w: FontWeight.w700, ls: -.5)),
                    const SizedBox(height: 14),
                    if (who != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCEEED),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.ios_share_rounded, size: 18, color: Color(0xFF117770)),
                          const SizedBox(width: 8),
                          Text(
                            '$who were told',
                            style: ts(13.5, w: FontWeight.w800, c: const Color(0xFF117770)),
                          ),
                        ]),
                      ),
                    const SizedBox(height: 20),
                    AppCard(
                      color: Colors.white,
                      borderColor: const Color(0xFFEBE5DD),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                      child: Column(children: [
                        _line('Fare', 'PKR ${money(t.fare)}'),
                        const Divider(height: 1, thickness: 1, color: Color(0xFFEFEAE2)),
                        _line('Paid', t.payment),
                        const Divider(height: 1, thickness: 1, color: Color(0xFFEFEAE2)),
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
                            child: Icon(
                              i <= _stars ? Icons.star_rounded : Icons.star_outline_rounded,
                              size: 46,
                              color: i <= _stars ? AppColors.yellow : const Color(0xFFC5BCD1),
                            ),
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
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      _tag('Safe driving'),
                    ]),
                    // const SizedBox(height: 10),
                    // TextButton(
                    //   onPressed: _report,
                    //   child: Text('Report a problem', style: ts(14, w: FontWeight.w600, c: AppColors.grey)),
                    // ),
                  ]),
                ),
              ),
              PrimaryButton(
                label: 'Done',
                color: const Color(0xFFC93824),
                textColor: Colors.white,
                loading: _saving,
                onPressed: _done,
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
