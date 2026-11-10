import 'package:intl/intl.dart';

String initial(String name) {
  final n = name.trim();
  return n.isEmpty ? '?' : n[0].toUpperCase();
}

String money(num n) => NumberFormat('#,###').format(n);

/// "Today, 8:12 AM" / "Yesterday, 5:40 PM" / "Mon 3 Nov, 8:05 AM"
String tripWhen(DateTime d) {
  final now = DateTime.now();
  final t = DateFormat('h:mm a').format(d);
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(d.year, d.month, d.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return 'Today, $t';
  if (diff == 1) return 'Yesterday, $t';
  return '${DateFormat('EEE d MMM').format(d)}, $t';
}

/// 3001212212 -> "+92 300 1212212"
String prettyPhone(String code, String national) =>
    national.length > 3
        ? '$code ${national.substring(0, 3)} ${national.substring(3)}'
        : '$code $national';
