import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';

/// Base URL du site web (pages légales hébergées).
String legalBaseUrl() {
  final fromEnv = dotenv.env['LEGAL_BASE_URL']?.trim();
  if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv.replaceAll(RegExp(r'/+$'), '');
  return 'https://soutralideals-web-app.onrender.com';
}

class LegalUrls {
  static String get cgu => '${legalBaseUrl()}/cgu';
  static String get confidentialite => '${legalBaseUrl()}/confidentialite';
  static String get cookies => '${legalBaseUrl()}/cookies';
  static String get mentions => '${legalBaseUrl()}/mentions-legales';
}

Future<void> openLegalUrl(BuildContext context, String url) async {
  final uri = Uri.parse(url);
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Impossible d\'ouvrir le lien : $url')),
    );
  }
}
