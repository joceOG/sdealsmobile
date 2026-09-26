import 'package:flutter/material.dart';
import 'package:sdealsmobile/design_system/design_system.dart';

/// Pictogrammes client Métiers et Freelance. Un seul tracé, deux tailles.
class ClientUniversePictogram extends StatelessWidget {
  const ClientUniversePictogram.metiers({
    super.key,
    this.size = 46,
  }) : kind = ClientUniverseKind.metiers;

  const ClientUniversePictogram.freelance({
    super.key,
    this.size = 46,
  }) : kind = ClientUniverseKind.freelance;

  final ClientUniverseKind kind;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size.square(size),
        painter: kind == ClientUniverseKind.metiers
            ? const _MetiersPainter()
            : const _FreelancePainter(),
      ),
    );
  }
}

enum ClientUniverseKind { metiers, freelance }

class _MetiersPainter extends CustomPainter {
  const _MetiersPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide / 48;
    canvas.save();
    canvas.scale(s);

    final fill = Paint()..color = SDColors.primary500;
    final pale = Paint()..color = SDColors.primary100;
    final stroke = Paint()
      ..color = SDColors.primary800
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.translate(24, 24);

    canvas.save();
    canvas.rotate(-0.72);
    _drawScrewdriver(canvas, fill, pale, stroke);
    canvas.restore();

    canvas.save();
    canvas.rotate(0.72);
    _drawWrench(canvas, fill, pale, stroke);
    canvas.restore();

    canvas.restore();
  }

  void _drawScrewdriver(Canvas canvas, Paint fill, Paint pale, Paint stroke) {
    final handle = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-4.2, -18.5, 8.4, 11),
      const Radius.circular(2.4),
    );
    canvas.drawRRect(handle, pale);
    canvas.drawRRect(handle, stroke);
    canvas.drawLine(const Offset(0, -7.5), const Offset(0, 10), stroke);
    final tip = Path()
      ..moveTo(-2.4, 9.2)
      ..lineTo(0, 16.5)
      ..lineTo(2.4, 9.2)
      ..close();
    canvas.drawPath(tip, fill);
    canvas.drawPath(tip, stroke);
  }

  void _drawWrench(Canvas canvas, Paint fill, Paint pale, Paint stroke) {
    final jaw = Path()
      ..moveTo(-5.2, -16.5)
      ..lineTo(5.2, -16.5)
      ..lineTo(5.2, -8.2)
      ..lineTo(2.1, -8.2)
      ..lineTo(2.1, -12.4)
      ..lineTo(-2.1, -12.4)
      ..lineTo(-2.1, -8.2)
      ..lineTo(-5.2, -8.2)
      ..close();
    canvas.drawPath(jaw, fill);
    canvas.drawPath(jaw, stroke);
    final handle = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-3.1, -8.2, 6.2, 22),
      const Radius.circular(2.2),
    );
    canvas.drawRRect(handle, pale);
    canvas.drawRRect(handle, stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FreelancePainter extends CustomPainter {
  const _FreelancePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide / 48;
    canvas.save();
    canvas.scale(s);

    final pale = Paint()..color = SDColors.primary50;
    final fill = Paint()..color = SDColors.primary500;
    final stroke = Paint()
      ..color = SDColors.primary800
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final screen = RRect.fromRectAndRadius(
      const Rect.fromLTWH(8, 5, 32, 22),
      const Radius.circular(3),
    );
    canvas.drawRRect(screen, pale);
    canvas.drawRRect(screen, stroke);

    final base = RRect.fromRectAndRadius(
      const Rect.fromLTWH(4, 29, 40, 7),
      const Radius.circular(2),
    );
    canvas.drawRRect(base, fill);
    canvas.drawRRect(base, stroke);

    final hinge = Paint()
      ..color = SDColors.primary800
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(18, 32.5), const Offset(30, 32.5), hinge);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
