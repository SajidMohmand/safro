import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../core/theme.dart';
import '../core/utils.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final Color textColor;
  final bool loading;
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = AppColors.red,
    this.textColor = Colors.white,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 58,
        child: ElevatedButton(
          onPressed: loading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: textColor,
            disabledBackgroundColor: color.withOpacity(.35),
            disabledForegroundColor: textColor.withOpacity(.85),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            textStyle: ts(17, w: FontWeight.w700),
          ),
          child: loading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.6, color: Colors.white))
              : Text(label),
        ),
      );
}

/// White button with a border (Cancel, Book again, Add Contact ...)
class BorderButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color borderColor;
  final Color? textColor;
  final double radius;
  final double height;
  const BorderButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.borderColor = AppColors.ink,
    this.textColor,
    this.radius = 16,
    this.height = 56,
  });

  @override
  Widget build(BuildContext context) {
    final fg = textColor ?? borderColor;
    return SizedBox(
      width: double.infinity,
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: fg,
          side: BorderSide(color: borderColor, width: 1.6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
          textStyle: ts(17, w: FontWeight.w700, c: fg),
        ),
        child: Text(label, style: ts(17, w: FontWeight.w700, c: fg)),
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  final Widget child;
  final Color color;
  final Color borderColor;
  final double borderWidth;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  const AppCard({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.borderColor = AppColors.line,
    this.borderWidth = 1.3,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
        color: color,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Ink(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: borderColor == Colors.transparent
                  ? null
                  : Border.all(color: borderColor, width: borderWidth),
            ),
            child: child,
          ),
        ),
      );
}

class Avatar extends StatelessWidget {
  final String name;
  final double size;
  final Color? border;
  final Color bg;
  final Color fg;
  const Avatar(this.name,
      {super.key,
      this.size = 48,
      this.border,
      this.bg = AppColors.redSoft,
      this.fg = AppColors.red});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bg,
          border: border == null ? null : Border.all(color: border!, width: 2),
        ),
        child: Text(initial(name), style: ts(size * .42, w: FontWeight.w700, c: fg)),
      );
}

class Pill extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;
  final IconData? icon;
  final double size;
  const Pill(this.text,
      {super.key,
      this.bg = AppColors.greenSoft,
      this.fg = AppColors.green,
      this.icon,
      this.size = 12.5});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(30)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, size: size + 3, color: fg), const SizedBox(width: 5)],
          Text(text, style: ts(size, w: FontWeight.w600, c: fg)),
        ]),
      );
}

class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});
  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          width: 42,
          height: 5,
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(5)),
        ),
      );
}

/// Pickup (circle bullet) -> drop (green rectangle bullet).
class PickupDropCard extends StatelessWidget {
  final String pickup, drop;
  final VoidCallback? onPickupTap, onDropTap;
  final bool showLabels;
  final Color? pickupCircleColor;
  final Color? textColor;
  const PickupDropCard(
      {super.key,
      required this.pickup,
      required this.drop,
      this.onPickupTap,
      this.onDropTap,
      this.showLabels = false,
      this.pickupCircleColor,
      this.textColor});

  Widget _row(Widget bullet, String text, String label, VoidCallback? tap) => InkWell(
        onTap: tap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(children: [
            SizedBox(width: 16, child: Center(child: bullet)),
            const SizedBox(width: 14),
            Expanded(
                child: Text(text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ts(16, w: FontWeight.w600, c: textColor ?? AppColors.ink))),
            if (showLabels) Text(label, style: ts(12, c: AppColors.grey)),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) => AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(children: [
          _row(
              Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: pickupCircleColor ?? AppColors.ink, width: 3.2))),
              pickup,
              'Pickup',
              onPickupTap),
          Align(
              alignment: Alignment.centerLeft,
              child: Container(
                  margin: const EdgeInsets.only(left: 7, top: 2, bottom: 2),
                  width: 2,
                  height: 14,
                  color: AppColors.line)),
          _row(
              Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                      color: AppColors.green, borderRadius: BorderRadius.circular(3))),
              drop,
              'Drop',
              onDropTap),
        ]),
      );
}

class MapIcons {
  static BitmapDescriptor? _car;

  /// Round red marker with a white car glyph, drawn in code (no image asset).
  static Future<BitmapDescriptor> car() async {
    if (_car != null) return _car!;
    const size = 120.0;
    final rec = ui.PictureRecorder();
    final canvas = Canvas(rec);
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2, Paint()..color = Colors.white);
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2 - 7, Paint()..color = AppColors.red);
    const icon = Icons.directions_car_filled_rounded;
    final tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
            fontSize: size * .5,
            fontFamily: icon.fontFamily,
            package: icon.fontPackage,
            color: Colors.white),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset((size - tp.width) / 2, (size - tp.height) / 2));
    final img = await rec.endRecording().toImage(size.toInt(), size.toInt());
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    _car = BitmapDescriptor.bytes(data!.buffer.asUint8List(), width: 38, height: 38);
    return _car!;
  }
}

void showSnack(BuildContext context, String msg, {bool error = false}) {
  final m = ScaffoldMessenger.of(context);
  m.hideCurrentSnackBar();
  m.showSnackBar(SnackBar(
    content: Text(msg, style: ts(14, c: Colors.white)),
    backgroundColor: error ? AppColors.redDark : AppColors.ink,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  ));
}
