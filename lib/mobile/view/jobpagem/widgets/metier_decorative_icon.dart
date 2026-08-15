import 'package:flutter/material.dart';
import '../../../../design_system/design_system.dart';

/// Petite illustration métier (bas droite carte « Service demandé »).
/// Choisit une icône selon le nom du service / métier.
class MetierDecorativeIcon extends StatelessWidget {
  final String serviceName;
  final double size;

  const MetierDecorativeIcon({
    super.key,
    required this.serviceName,
    this.size = 56,
  });

  static _MetierKind _kindFor(String raw) {
    final s = raw.toLowerCase();
    if (s.contains('peint') || s.contains('enduit')) {
      return _MetierKind.peinture;
    }
    if (s.contains('plomb') || s.contains('robinet') || s.contains('canalisation')) {
      return _MetierKind.plomberie;
    }
    if (s.contains('élect') ||
        s.contains('electr') ||
        s.contains('courant') ||
        s.contains('câbl') ||
        s.contains('cabl')) {
      return _MetierKind.electricite;
    }
    if (s.contains('carrel') || s.contains('faïence') || s.contains('faience')) {
      return _MetierKind.carrelage;
    }
    if (s.contains('ménag') ||
        s.contains('menag') ||
        s.contains('netto') ||
        s.contains('servante') ||
        s.contains('femme de ménage') ||
        s.contains('cleaning')) {
      return _MetierKind.menage;
    }
    if (s.contains('jardin') ||
        s.contains('paysag') ||
        s.contains('tonte') ||
        s.contains('espace vert')) {
      return _MetierKind.jardinage;
    }
    if (s.contains('maçonn') ||
        s.contains('maconn') ||
        s.contains('béton') ||
        s.contains('beton') ||
        s.contains('brique')) {
      return _MetierKind.maconnerie;
    }
    if (s.contains('climat') ||
        s.contains('froid') ||
        s.contains('clim') ||
        s.contains('réfrig') ||
        s.contains('refriger')) {
      return _MetierKind.climatisation;
    }
    if (s.contains('coiff') || s.contains('barb') || s.contains('salon')) {
      return _MetierKind.beaute;
    }
    if (s.contains('mécan') ||
        s.contains('mecan') ||
        s.contains('auto') ||
        s.contains('voiture') ||
        s.contains('garage')) {
      return _MetierKind.mecanique;
    }
    if (s.contains('soud') || s.contains('ferronn') || s.contains('métal') || s.contains('metal')) {
      return _MetierKind.soudure;
    }
    if (s.contains('menuis') || s.contains('bois') || s.contains('ébén') || s.contains('eben')) {
      return _MetierKind.menuiserie;
    }
    if (s.contains('déménag') || s.contains('demenag') || s.contains('transport')) {
      return _MetierKind.demenagement;
    }
    if (s.contains('sécur') || s.contains('secur') || s.contains('gardien')) {
      return _MetierKind.securite;
    }
    if (s.contains('inform') ||
        s.contains('dévelop') ||
        s.contains('develop') ||
        s.contains('web') ||
        s.contains('freelance')) {
      return _MetierKind.digital;
    }
    return _MetierKind.autre;
  }

  @override
  Widget build(BuildContext context) {
    final kind = _kindFor(serviceName);
    if (kind == _MetierKind.peinture) {
      return SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _PaintRollerPainter()),
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: Icon(
        _iconFor(kind),
        size: size * 0.72,
        color: SDColors.primary600.withValues(alpha: 0.85),
      ),
    );
  }

  static IconData _iconFor(_MetierKind kind) {
    switch (kind) {
      case _MetierKind.peinture:
        return Icons.format_paint_rounded;
      case _MetierKind.plomberie:
        return Icons.plumbing_rounded;
      case _MetierKind.electricite:
        return Icons.electrical_services_rounded;
      case _MetierKind.carrelage:
        return Icons.grid_view_rounded;
      case _MetierKind.menage:
        return Icons.cleaning_services_rounded;
      case _MetierKind.jardinage:
        return Icons.yard_rounded;
      case _MetierKind.maconnerie:
        return Icons.foundation_rounded;
      case _MetierKind.climatisation:
        return Icons.ac_unit_rounded;
      case _MetierKind.beaute:
        return Icons.content_cut_rounded;
      case _MetierKind.mecanique:
        return Icons.car_repair_rounded;
      case _MetierKind.soudure:
        return Icons.whatshot_rounded;
      case _MetierKind.menuiserie:
        return Icons.carpenter_rounded;
      case _MetierKind.demenagement:
        return Icons.local_shipping_rounded;
      case _MetierKind.securite:
        return Icons.security_rounded;
      case _MetierKind.digital:
        return Icons.laptop_mac_rounded;
      case _MetierKind.autre:
        return Icons.handyman_rounded;
    }
  }
}

enum _MetierKind {
  peinture,
  plomberie,
  electricite,
  carrelage,
  menage,
  jardinage,
  maconnerie,
  climatisation,
  beaute,
  mecanique,
  soudure,
  menuiserie,
  demenagement,
  securite,
  digital,
  autre,
}

/// Rouleau peinture (maquette) — manche jaune, manchon + trace verts.
class _PaintRollerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final green = const Color(0xFF2E7D32);
    final greenLight = const Color(0xFF66BB6A);
    final yellow = const Color(0xFFF9A825);
    final yellowDark = const Color(0xFFF57F17);

    // Trace de peinture
    final trail = Path()
      ..moveTo(w * 0.08, h * 0.72)
      ..quadraticBezierTo(w * 0.22, h * 0.62, w * 0.38, h * 0.68)
      ..quadraticBezierTo(w * 0.52, h * 0.74, w * 0.62, h * 0.70)
      ..lineTo(w * 0.62, h * 0.82)
      ..quadraticBezierTo(w * 0.45, h * 0.88, w * 0.28, h * 0.84)
      ..quadraticBezierTo(w * 0.12, h * 0.80, w * 0.08, h * 0.72)
      ..close();
    canvas.drawPath(
      trail,
      Paint()..color = greenLight.withValues(alpha: 0.55),
    );

    // Manchon (rouleau)
    final rollerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.18, h * 0.18, w * 0.52, h * 0.28),
      Radius.circular(w * 0.08),
    );
    canvas.drawRRect(rollerRect, Paint()..color = green);
    canvas.drawRRect(
      rollerRect,
      Paint()
        ..color = greenLight.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Axe / cadre du rouleau
    final frame = Paint()
      ..color = const Color(0xFF455A64)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(w * 0.70, h * 0.32),
      Offset(w * 0.78, h * 0.32),
      frame,
    );
    canvas.drawLine(
      Offset(w * 0.78, h * 0.32),
      Offset(w * 0.78, h * 0.55),
      frame,
    );

    // Manche jaune
    final handleRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.72, h * 0.52, w * 0.12, h * 0.38),
      Radius.circular(w * 0.04),
    );
    canvas.drawRRect(
      handleRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [yellow, yellowDark],
        ).createShader(handleRect.outerRect),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
