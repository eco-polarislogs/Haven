import 'package:flutter/material.dart';

/// Haven logosu: yumuşak köşeli bir kalkanın içinde sıcak ışıklı bir kapı.
/// Korunma (kalkan) + içeri davet (kapı) + umut (ışık) = sığınak / güvenli alan.
/// Soyut ve cinsiyetsiz. Android uygulama ikonu
/// (res/drawable/ic_launcher_foreground.xml) ile aynı geometriyi çizer.
class HavenLogo extends StatelessWidget {
  const HavenLogo({
    super.key,
    this.size = 96,
    this.color = Colors.white,
    this.doorColor = const Color(0xFF3B4A7A),
    this.lightColor = const Color(0xFFF4B860),
  });

  final double size;
  final Color color;
  final Color doorColor;
  final Color lightColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _ShieldPainter(color, doorColor, lightColor)),
    );
  }
}

class _ShieldPainter extends CustomPainter {
  _ShieldPainter(this.color, this.door, this.light);

  final Color color;
  final Color door;
  final Color light;

  @override
  void paint(Canvas canvas, Size size) {
    // İkonun dolu kısmı x 32..77, y 27..81; ortalayıp büyütüyoruz.
    final s = size.width / 56;
    canvas.translate(-26.5 * s, -26 * s);
    canvas.scale(s);

    final shield = Path()
      ..moveTo(54, 27)
      ..cubicTo(61, 31.5, 68.5, 33.5, 76, 33.5)
      ..cubicTo(77, 52, 71, 69, 54, 81)
      ..cubicTo(37, 69, 31, 52, 32, 33.5)
      ..cubicTo(39.5, 33.5, 47, 31.5, 54, 27)
      ..close();
    // yumuşak gölge
    canvas.drawShadow(shield, Colors.black.withValues(alpha: 0.35), 2, false);
    canvas.drawPath(shield, Paint()..color = color);

    Path arch(double left, double right, double top, double bottom) {
      final r = (right - left) / 2;
      return Path()
        ..moveTo(left, bottom)
        ..lineTo(left, top)
        ..arcToPoint(Offset(right, top), radius: Radius.circular(r))
        ..lineTo(right, bottom)
        ..close();
    }

    canvas.drawPath(arch(45.5, 62.5, 54, 69), Paint()..color = door);
    canvas.drawPath(arch(49, 59, 54.5, 69), Paint()..color = light);
  }

  @override
  bool shouldRepaint(covariant _ShieldPainter old) =>
      old.color != color || old.door != door || old.light != light;
}
