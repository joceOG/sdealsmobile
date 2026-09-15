# Matrice fichiers / tests — Phase 10B

**App :** sdealsmobile (`com.sdealsmobile.app`)  
**Branche / commit départ :** `jordan` / `dc5e68d`  
**Version cible :** 1.2.3+9  
**AAB 1.2.2+8 :** présent `build/app/outputs/bundle/release/app-release.aab` (~96,7 Mo)  
**Keystore :** `android/key.properties` présent (non lu)  
**Git préexistant non suivi :** `.cursor/`, `docs/`  
**Backend :** inchangé au départ (mods locaux deletion uniquement, pas de deploy)

| Lot | Fichiers cibles | Tests |
|---|---|---|
| 1 Logs | `serviceProviderRegistrationPageBlocM.dart`, `freelancePageBlocM.dart`, `notification_service.dart`, `api_client.dart` (prints sensibles), Crashlytics | `test/security/no_sensitive_logs_test.dart` |
| 2 Stockage | `utilisateur.dart`, `authCubit.dart`, `AndroidManifest.xml` | `test/security/auth_storage_test.dart` |
| 3 Config | `pubspec.yaml`, `main.dart`, `.env.example` | smoke config release |
| 4 Suppression | backend controller/routes/model ; web `suppression-compte` ; mobile profil + legal_urls + api | backend memory tests ; widget smoke |
| 5 P1 | profil, help, provider_popup, vendor, navigation, fetchPrestataires | widgets / unit pagination |
| 6 Qualité | `widget_test.dart` → smoke ; analyze ; AAB 1.2.3+9 | full suite |
