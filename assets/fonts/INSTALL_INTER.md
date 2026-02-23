# 📥 Installation de la Font Inter

## Option 1: Téléchargement automatique (Recommandé)

### Via Google Fonts
1. Visitez: https://fonts.google.com/specimen/Inter
2. Cliquez sur "Download family"
3. Extrayez le fichier ZIP
4. Copiez ces fichiers dans `assets/fonts/`:
   - `Inter-Regular.ttf` (weight 400)
   - `Inter-SemiBold.ttf` (weight 600)  
   - `Inter-Bold.ttf` (weight 700)

## Option 2: Téléchargement direct

Téléchargez depuis le repo officiel:
```
https://github.com/rsms/inter/releases/latest
```

Fichiers nécessaires (dans le dossier `static`):
- `Inter-Regular.ttf`
- `Inter-SemiBold.ttf`
- `Inter-Bold.ttf`

## Option 3: Via terminal (Windows)

```powershell
# Dans assets/fonts/
curl -L -o Inter.zip https://github.com/rsms/inter/releases/download/v4.0/Inter-4.0.zip
tar -xf Inter.zip
copy "Inter Desktop\Inter-Regular.ttf" .
copy "Inter Desktop\Inter-SemiBold.ttf" .
copy "Inter Desktop\Inter-Bold.ttf" .
```

## ✅ Vérification

Après téléchargement, vous devez avoir:
```
assets/fonts/
├── Inter-Regular.ttf
├── Inter-SemiBold.ttf
└── Inter-Bold.ttf
```

## 🔄 Alternative: Utiliser Roboto (déjà inclus dans Flutter)

Si vous voulez éviter le téléchargement, vous pouvez utiliser Roboto qui est déjà disponible:

1. Modifiez `lib/design_system/typography.dart`:
   ```dart
   static const String fontFamily = 'Roboto'; // au lieu de 'Inter'
   ```

2. Ignorez la section fonts dans pubspec.yaml

**Note**: Inter est recommandé pour un design plus moderne et lisible.
