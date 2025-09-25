import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CustomMarkerService {
  static const double _markerSize = 100.0;

  // Couleurs adaptées à l'écosystème SOUTRALI DEALS
  static const Color _userColor = Colors.blue; // Utilisateur

  // Couleurs par type d'activité (selon votre écosystème)
  static const Color _domicileColor = Colors.green; // Services à domicile
  static const Color _reparationColor =
      Colors.orange; // Réparations & Maintenance
  static const Color _transportColor = Colors.red; // Transport & Livraison
  static const Color _artisanatColor = Colors.purple; // Artisanat & Création
  static const Color _professionnelColor =
      Colors.grey; // Services Professionnels
  static const Color _artColor = Colors.yellow; // Arts & Divertissement
  static const Color _agricultureColor =
      Colors.greenAccent; // Agriculture & Environnement
  static const Color _alimentaireColor = Colors.brown; // Services Alimentaires
  static const Color _commerceColor = Colors.blueGrey; // Commerce de Détail

  // Couleurs de statut
  static const Color _verifiedProviderColor =
      Colors.amber; // Prestataire vérifié (couleur SOUTRALI)
  static const Color _urgentProviderColor = Colors.red; // Urgent

  /// Créer un marqueur personnalisé avec forme humaine
  static Future<BitmapDescriptor> createHumanMarker({
    required String text,
    required Color backgroundColor,
    required Color textColor,
    IconData? icon,
    bool isVerified = false,
    bool isUrgent = false,
  }) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..color = backgroundColor;
    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Dessiner le corps humain (forme ovale)
    final Rect bodyRect = Rect.fromLTWH(_markerSize * 0.2, _markerSize * 0.3,
        _markerSize * 0.6, _markerSize * 0.5);
    canvas.drawOval(bodyRect, paint);

    // Dessiner la tête (cercle)
    final Rect headRect = Rect.fromLTWH(_markerSize * 0.3, _markerSize * 0.1,
        _markerSize * 0.4, _markerSize * 0.3);
    canvas.drawOval(headRect, paint);

    // Dessiner les bras (lignes)
    final Paint armPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = 8.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Bras gauche
    canvas.drawLine(
      Offset(_markerSize * 0.15, _markerSize * 0.4),
      Offset(_markerSize * 0.05, _markerSize * 0.6),
      armPaint,
    );

    // Bras droit
    canvas.drawLine(
      Offset(_markerSize * 0.85, _markerSize * 0.4),
      Offset(_markerSize * 0.95, _markerSize * 0.6),
      armPaint,
    );

    // Dessiner les jambes (lignes)
    final Paint legPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = 8.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Jambe gauche
    canvas.drawLine(
      Offset(_markerSize * 0.4, _markerSize * 0.8),
      Offset(_markerSize * 0.35, _markerSize * 0.95),
      legPaint,
    );

    // Jambe droite
    canvas.drawLine(
      Offset(_markerSize * 0.6, _markerSize * 0.8),
      Offset(_markerSize * 0.65, _markerSize * 0.95),
      legPaint,
    );

    // Ajouter un badge de vérification si nécessaire
    if (isVerified) {
      final Paint badgePaint = Paint()..color = Colors.orange;
      final Rect badgeRect = Rect.fromLTWH(_markerSize * 0.7,
          _markerSize * 0.05, _markerSize * 0.25, _markerSize * 0.25);
      canvas.drawOval(badgeRect, badgePaint);

      // Icône de vérification
      final Paint checkPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(_markerSize * 0.75, _markerSize * 0.15),
        Offset(_markerSize * 0.8, _markerSize * 0.2),
        checkPaint,
      );
      canvas.drawLine(
        Offset(_markerSize * 0.8, _markerSize * 0.2),
        Offset(_markerSize * 0.9, _markerSize * 0.1),
        checkPaint,
      );
    }

    // Ajouter un badge d'urgence si nécessaire
    if (isUrgent) {
      final Paint urgentPaint = Paint()..color = Colors.red;
      final Rect urgentRect = Rect.fromLTWH(_markerSize * 0.05,
          _markerSize * 0.05, _markerSize * 0.25, _markerSize * 0.25);
      canvas.drawOval(urgentRect, urgentPaint);

      // Icône d'urgence
      final Paint urgentIconPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      // Dessiner un point d'exclamation
      canvas.drawLine(
        Offset(_markerSize * 0.15, _markerSize * 0.1),
        Offset(_markerSize * 0.15, _markerSize * 0.2),
        urgentIconPaint,
      );
      canvas.drawLine(
        Offset(_markerSize * 0.15, _markerSize * 0.25),
        Offset(_markerSize * 0.15, _markerSize * 0.25),
        urgentIconPaint,
      );
    }

    // Ajouter l'icône si fournie
    if (icon != null) {
      // Dessiner l'icône au centre du corps
      _drawIcon(canvas, icon, _markerSize * 0.5, _markerSize * 0.5, textColor);
    }

    // Ajouter le texte
    textPainter.text = TextSpan(
      text: text,
      style: TextStyle(
        color: textColor,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (_markerSize - textPainter.width) / 2,
        _markerSize * 0.05,
      ),
    );

    final ui.Picture picture = pictureRecorder.endRecording();
    final ui.Image image = await picture.toImage(
      _markerSize.toInt(),
      _markerSize.toInt(),
    );
    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    final Uint8List uint8List = byteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(uint8List);
  }

  /// Dessiner une icône simple
  static void _drawIcon(
      Canvas canvas, IconData icon, double x, double y, Color color) {
    final Paint iconPaint = Paint()
      ..color = color
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Dessiner une icône simple selon le type
    switch (icon) {
      case Icons.person:
        // Dessiner un visage simple
        canvas.drawCircle(Offset(x, y - 5), 8, iconPaint);
        canvas.drawCircle(Offset(x - 3, y - 7), 1, iconPaint);
        canvas.drawCircle(Offset(x + 3, y - 7), 1, iconPaint);
        canvas.drawArc(
          Rect.fromCenter(center: Offset(x, y - 3), width: 6, height: 3),
          0,
          3.14,
          false,
          iconPaint,
        );
        break;
      case Icons.work:
        // Dessiner un marteau
        canvas.drawLine(Offset(x - 5, y - 5), Offset(x + 5, y + 5), iconPaint);
        canvas.drawLine(Offset(x - 3, y - 3), Offset(x - 1, y - 1), iconPaint);
        break;
      case Icons.local_hospital:
        // Dessiner une croix médicale
        canvas.drawLine(Offset(x, y - 8), Offset(x, y + 8), iconPaint);
        canvas.drawLine(Offset(x - 8, y), Offset(x + 8, y), iconPaint);
        break;
      default:
        // Icône par défaut (cercle)
        canvas.drawCircle(Offset(x, y), 5, iconPaint);
        break;
    }
  }

  /// Créer un marqueur pour l'utilisateur
  static Future<BitmapDescriptor> createUserMarker() async {
    return createHumanMarker(
      text: 'Moi',
      backgroundColor: _userColor,
      textColor: Colors.white,
      icon: Icons.person,
    );
  }

  /// Créer un marqueur pour un prestataire
  static Future<BitmapDescriptor> createProviderMarker({
    required String name,
    required bool isVerified,
    required bool isUrgent,
    IconData? icon,
  }) async {
    Color backgroundColor = _domicileColor; // Par défaut
    if (isUrgent) {
      backgroundColor = _urgentProviderColor;
    } else if (isVerified) {
      backgroundColor = _verifiedProviderColor;
    }

    return createHumanMarker(
      text: name.length > 8 ? '${name.substring(0, 8)}...' : name,
      backgroundColor: backgroundColor,
      textColor: Colors.white,
      icon: icon ?? Icons.work,
      isVerified: isVerified,
      isUrgent: isUrgent,
    );
  }

  /// Créer un marqueur pour un service médical
  static Future<BitmapDescriptor> createMedicalMarker({
    required String name,
    required bool isVerified,
    required bool isUrgent,
  }) async {
    return createProviderMarker(
      name: name,
      isVerified: isVerified,
      isUrgent: isUrgent,
      icon: Icons.local_hospital,
    );
  }

  /// Créer un marqueur pour un service de réparation
  static Future<BitmapDescriptor> createRepairMarker({
    required String name,
    required bool isVerified,
    required bool isUrgent,
  }) async {
    return createProviderMarker(
      name: name,
      isVerified: isVerified,
      isUrgent: isUrgent,
      icon: Icons.build,
    );
  }

  /// Déterminer la couleur selon la catégorie de service
  static Color getColorByCategory(String category, String service) {
    // Services à domicile
    if (category.toLowerCase().contains('domicile') ||
        service.toLowerCase().contains('domicile') ||
        service.toLowerCase().contains('coiffeur') ||
        service.toLowerCase().contains('cuisinier') ||
        service.toLowerCase().contains('garde') ||
        service.toLowerCase().contains('nettoyage') ||
        service.toLowerCase().contains('esthétique') ||
        service.toLowerCase().contains('baby-sitter') ||
        service.toLowerCase().contains('aide-ménagère')) {
      return _domicileColor;
    }

    // Réparations & Maintenance
    if (category.toLowerCase().contains('réparation') ||
        category.toLowerCase().contains('maintenance') ||
        service.toLowerCase().contains('réparateur') ||
        service.toLowerCase().contains('plombier') ||
        service.toLowerCase().contains('électricien') ||
        service.toLowerCase().contains('technicien')) {
      return _reparationColor;
    }

    // Transport & Livraison
    if (category.toLowerCase().contains('transport') ||
        service.toLowerCase().contains('taxi') ||
        service.toLowerCase().contains('livreur') ||
        service.toLowerCase().contains('chauffeur') ||
        service.toLowerCase().contains('déménagement') ||
        service.toLowerCase().contains('moto-taxi')) {
      return _transportColor;
    }

    // Artisanat & Création
    if (category.toLowerCase().contains('artisanat') ||
        service.toLowerCase().contains('artisan') ||
        service.toLowerCase().contains('tailleur') ||
        service.toLowerCase().contains('menuisier') ||
        service.toLowerCase().contains('cordonnier') ||
        service.toLowerCase().contains('charpentier') ||
        service.toLowerCase().contains('bijoux') ||
        service.toLowerCase().contains('couturier')) {
      return _artisanatColor;
    }

    // Services Professionnels
    if (category.toLowerCase().contains('professionnel') ||
        service.toLowerCase().contains('consultant') ||
        service.toLowerCase().contains('formateur') ||
        service.toLowerCase().contains('coach') ||
        service.toLowerCase().contains('expert') ||
        service.toLowerCase().contains('conseiller')) {
      return _professionnelColor;
    }

    // Arts & Divertissement
    if (category.toLowerCase().contains('art') ||
        category.toLowerCase().contains('divertissement') ||
        service.toLowerCase().contains('musicien') ||
        service.toLowerCase().contains('artiste') ||
        service.toLowerCase().contains('organisateur') ||
        service.toLowerCase().contains('photographe') ||
        service.toLowerCase().contains('graphiste')) {
      return _artColor;
    }

    // Agriculture & Environnement
    if (category.toLowerCase().contains('agriculture') ||
        category.toLowerCase().contains('environnement') ||
        service.toLowerCase().contains('agriculteur') ||
        service.toLowerCase().contains('jardinier') ||
        service.toLowerCase().contains('éleveur') ||
        service.toLowerCase().contains('bio')) {
      return _agricultureColor;
    }

    // Services Alimentaires
    if (category.toLowerCase().contains('alimentaire') ||
        service.toLowerCase().contains('traiteur') ||
        service.toLowerCase().contains('boulanger') ||
        service.toLowerCase().contains('pâtissier') ||
        service.toLowerCase().contains('cuisine') ||
        service.toLowerCase().contains('restaurant')) {
      return _alimentaireColor;
    }

    // Commerce de Détail
    if (category.toLowerCase().contains('commerce') ||
        service.toLowerCase().contains('vendeur') ||
        service.toLowerCase().contains('distributeur') ||
        service.toLowerCase().contains('revendeur') ||
        service.toLowerCase().contains('commerçant')) {
      return _commerceColor;
    }

    // Par défaut : vert (services généraux)
    return _domicileColor;
  }

  /// Créer un marqueur avec couleur intelligente selon la catégorie
  static Future<BitmapDescriptor> createSmartProviderMarker({
    required String name,
    required String category,
    required String service,
    required bool isVerified,
    required bool isUrgent,
  }) async {
    // Déterminer l'icône selon le service
    IconData? serviceIcon;
    if (service.toLowerCase().contains('médical') ||
        service.toLowerCase().contains('santé') ||
        service.toLowerCase().contains('docteur')) {
      serviceIcon = Icons.local_hospital;
    } else if (service.toLowerCase().contains('réparation') ||
        service.toLowerCase().contains('plomberie') ||
        service.toLowerCase().contains('électricité')) {
      serviceIcon = Icons.build;
    } else if (service.toLowerCase().contains('transport') ||
        service.toLowerCase().contains('taxi') ||
        service.toLowerCase().contains('livreur')) {
      serviceIcon = Icons.directions_car;
    } else if (service.toLowerCase().contains('artisan') ||
        service.toLowerCase().contains('tailleur') ||
        service.toLowerCase().contains('menuisier')) {
      serviceIcon = Icons.handyman;
    } else if (service.toLowerCase().contains('musicien') ||
        service.toLowerCase().contains('artiste') ||
        service.toLowerCase().contains('photographe')) {
      serviceIcon = Icons.palette;
    } else {
      serviceIcon = Icons.work;
    }

    // Utiliser la couleur intelligente
    final backgroundColor = getColorByCategory(category, service);

    return createHumanMarker(
      text: name.length > 8 ? '${name.substring(0, 8)}...' : name,
      backgroundColor: backgroundColor,
      textColor: Colors.white,
      icon: serviceIcon,
      isVerified: isVerified,
      isUrgent: isUrgent,
    );
  }

  /// Créer un marqueur avec bulle de prix pour les prestataires
  static Future<BitmapDescriptor> createProviderWithPriceMarker({
    required String name,
    required String category,
    required String service,
    required String price,
    required bool isVerified,
    required bool isUrgent,
  }) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final double markerSize = _markerSize;
    final double bubbleWidth = 120.0;
    final double bubbleHeight = 40.0;
    final double totalHeight = markerSize + bubbleHeight + 10;

    // Dessiner la bulle de prix (vert foncé)
    final Paint bubblePaint = Paint()..color = Colors.green.shade800;
    final RRect bubbleRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        (markerSize - bubbleWidth) / 2,
        0,
        bubbleWidth,
        bubbleHeight,
      ),
      const Radius.circular(20),
    );
    canvas.drawRRect(bubbleRect, bubblePaint);

    // Bordure de la bulle
    final Paint borderPaint = Paint()
      ..color = Colors.green.shade900
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(bubbleRect, borderPaint);

    // Déterminer l'icône selon le service
    IconData? serviceIcon;
    if (service.toLowerCase().contains('médical') ||
        service.toLowerCase().contains('santé') ||
        service.toLowerCase().contains('docteur')) {
      serviceIcon = Icons.local_hospital;
    } else if (service.toLowerCase().contains('réparation') ||
        service.toLowerCase().contains('plomberie') ||
        service.toLowerCase().contains('électricité')) {
      serviceIcon = Icons.build;
    } else if (service.toLowerCase().contains('transport') ||
        service.toLowerCase().contains('taxi') ||
        service.toLowerCase().contains('livreur')) {
      serviceIcon = Icons.directions_car;
    } else if (service.toLowerCase().contains('artisan') ||
        service.toLowerCase().contains('tailleur') ||
        service.toLowerCase().contains('menuisier')) {
      serviceIcon = Icons.handyman;
    } else if (service.toLowerCase().contains('musicien') ||
        service.toLowerCase().contains('artiste') ||
        service.toLowerCase().contains('photographe')) {
      serviceIcon = Icons.palette;
    } else {
      serviceIcon = Icons.work;
    }

    // Dessiner l'icône dans la bulle
    if (serviceIcon != null) {
      final TextPainter iconPainter =
          TextPainter(textDirection: TextDirection.ltr);
      iconPainter.text = TextSpan(
        text: String.fromCharCode(serviceIcon.codePoint),
        style: TextStyle(
          fontSize: 16,
          fontFamily: serviceIcon.fontFamily,
          color: Colors.white,
        ),
      );
      iconPainter.layout();
      iconPainter.paint(
        canvas,
        Offset(
          bubbleWidth / 2 - iconPainter.width / 2 - 25,
          bubbleHeight / 2 - iconPainter.height / 2,
        ),
      );
    }

    // Dessiner le prix dans la bulle
    final TextPainter pricePainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    pricePainter.text = TextSpan(
      text: price,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
    pricePainter.layout();
    pricePainter.paint(
      canvas,
      Offset(
        bubbleWidth / 2 - pricePainter.width / 2 + 10,
        bubbleHeight / 2 - pricePainter.height / 2,
      ),
    );

    // Dessiner le marqueur principal (forme humaine)
    final double markerY = bubbleHeight + 10;
    final Color backgroundColor = getColorByCategory(category, service);
    final Paint markerPaint = Paint()..color = backgroundColor;
    final double radius = markerSize / 2;

    // Corps (forme humaine simplifiée)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
            0, markerY + markerSize * 0.2, markerSize, markerSize * 0.7),
        const Radius.circular(15),
      ),
      markerPaint,
    );

    // Tête
    canvas.drawCircle(
      Offset(radius, markerY + markerSize * 0.25),
      radius * 0.4,
      markerPaint,
    );

    // Bras
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(markerSize * 0.1, markerY + markerSize * 0.4,
            markerSize * 0.8, markerSize * 0.15),
        const Radius.circular(5),
      ),
      markerPaint,
    );

    // Jambes
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(markerSize * 0.2, markerY + markerSize * 0.75,
            markerSize * 0.25, markerSize * 0.25),
        const Radius.circular(5),
      ),
      markerPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(markerSize * 0.55, markerY + markerSize * 0.75,
            markerSize * 0.25, markerSize * 0.25),
        const Radius.circular(5),
      ),
      markerPaint,
    );

    // Badge vérifié
    if (isVerified) {
      final Paint verifiedPaint = Paint()..color = Colors.orange;
      final TextPainter verifiedTextPainter = TextPainter(
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      verifiedTextPainter.text = const TextSpan(
        text: '✓',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      );
      verifiedTextPainter.layout();
      canvas.drawCircle(
        Offset(markerSize * 0.85, markerY + markerSize * 0.15),
        12,
        verifiedPaint,
      );
      verifiedTextPainter.paint(
        canvas,
        Offset(
          markerSize * 0.85 - verifiedTextPainter.width / 2,
          markerY + markerSize * 0.15 - verifiedTextPainter.height / 2,
        ),
      );
    }

    // Badge urgent
    if (isUrgent) {
      final Paint urgentPaint = Paint()..color = Colors.red;
      final TextPainter urgentTextPainter = TextPainter(
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      urgentTextPainter.text = const TextSpan(
        text: '!',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      );
      urgentTextPainter.layout();
      canvas.drawCircle(
        Offset(markerSize * 0.15, markerY + markerSize * 0.15),
        12,
        urgentPaint,
      );
      urgentTextPainter.paint(
        canvas,
        Offset(
          markerSize * 0.15 - urgentTextPainter.width / 2,
          markerY + markerSize * 0.15 - urgentTextPainter.height / 2,
        ),
      );
    }

    // Nom du prestataire
    final TextPainter namePainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: 1,
      ellipsis: '...',
    );
    namePainter.text = TextSpan(
      text: name,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    );
    namePainter.layout(maxWidth: markerSize * 0.8);
    namePainter.paint(
      canvas,
      Offset(
        radius - namePainter.width / 2,
        markerY + markerSize * 0.75 - namePainter.height / 2,
      ),
    );

    final ui.Image image = await pictureRecorder.endRecording().toImage(
          markerSize.toInt(),
          totalHeight.toInt(),
        );
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List uint8List = byteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(uint8List);
  }
}
