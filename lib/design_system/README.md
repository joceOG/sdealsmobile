# 🎨 Soutrali Deals Design System

Design system complet basé sur **Material Design 3**, **iOS HIG** et **WCAG 2.1 AA**.

## 📦 Installation

```dart
import 'package:sdealsmobile/design_system/design_system.dart';
```

## 🎯 Structure

```
lib/design_system/
├── design_system.dart      # Export central
├── colors.dart             # 40+ color tokens
├── typography.dart         # 12 text styles
├── spacing.dart            # 9 spacing values (4px grid)
├── animations.dart         # Durations + curves
└── widgets/
    ├── sd_appbar.dart      # AppBar 56px standard
    ├── sd_button.dart      # 4 button types
    ├── sd_input.dart       # Form inputs
    └── sd_card.dart        # Card components
```

## 🚀 Usage rapide

### Typography

```dart
Text('Titre', style: SDTypography.titleLarge)
Text('Corps', style: SDTypography.bodyMedium)
```

**Styles disponibles:**
- `displayLarge` (32px), `displayMedium` (28px), `displaySmall` (24px)
- `titleLarge` (20px), `titleMedium` (18px), `titleSmall` (16px)
- `bodyLarge` (16px), `bodyMedium` (14px), `bodySmall` (12px)
- `labelLarge` (16px), `labelMedium` (14px), `labelSmall` (12px)
- `priceDisplay` (24px), `priceMedium` (18px)

### Colors

```dart
Container(color: SDColors.primary500)
Text('Hello', style: TextStyle(color: SDColors.neutral900))
```

**Palette:**
- **Primary**: `primary50` → `primary900` (vert Soutrali)
- **Secondary**: `secondary100` → `secondary600` (orange accent)
- **Neutral**: `neutral50` → `neutral900` (gris)
- **Semantic**: `success`, `error`, `warning`, `info`

### Spacing

```dart
Padding(padding: EdgeInsets.all(SDSpacing.sm))  // 16px
SizedBox(height: SDSpacing.md)                  // 24px
SDSpacing.defaultGap                            // SizedBox 16x16
```

**Scale (4px grid):**
- `xxxs` (4px), `xxs` (8px), `xs` (12px)
- `sm` (16px) ✅ DEFAULT
- `md` (24px), `lg` (32px), `xl` (48px), `xxl` (64px), `xxxl` (80px)

### Animations

```dart
AnimatedContainer(
  duration: SDAnimations.medium,
  curve: SDAnimations.emphasized,
)
```

**Durations:**
- `ultraShort` (100ms), `short` (200ms), `medium` (300ms), `long` (400ms)

**Curves:**
- `emphasized`, `decelerated`, `accelerated`, `standard`

## 🧩 Widgets

### SDAppBar

```dart
Scaffold(
  appBar: SDAppBar(
    title: 'Ma Page',
    showSearch: true,
    onSearch: () => context.go('/search'),
  ),
)
```

### SDButton

```dart
SDButton(
  text: 'Ajouter',
  icon: Icons.add,
  type: SDButtonType.primary,
  size: SDButtonSize.large,
  onPressed: () => handleAdd(),
)
```

**Types:** `primary`, `secondary`, `outlined`, `text`  
**Sizes:** `large` (56px), `medium` (48px), `small` (40px)

### SDInput

```dart
SDInput(
  label: 'Email',
  hint: 'exemple@email.com',
  keyboardType: TextInputType.emailAddress,
  validator: (value) => value?.isEmpty == true ? 'Requis' : null,
)
```

### SDCard

```dart
SDCard(
  onTap: () => navigateToDetails(),
  child: Column(
    children: [
      Text('Titre', style: SDTypography.titleMedium),
      Text('Description'),
    ],
  ),
)
```

## ✅ Standards respectés

- ✅ Material Design 3 (Google)
- ✅ iOS Human Interface Guidelines (Apple)
- ✅ WCAG 2.1 Level AA (Accessibilité)
- ✅ Flutter Best Practices

## 📚 Documentation complète

Voir: `C:\Users\DELL\.gemini\antigravity\brain\...\DESIGN_SYSTEM_COMPLET.md`
