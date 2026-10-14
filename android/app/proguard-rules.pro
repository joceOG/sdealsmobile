# R8 release. Ne pas garder io.flutter.** / Firebase / Maps en bloc :
# ces keep annulent l'obscurcissement DEX exigé par Play.

-keepattributes Signature,InnerClasses,EnclosingMethod,*Annotation*
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

-dontwarn io.flutter.embedding.**
-dontwarn com.google.android.play.core.**
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

-keepclasseswithmembernames class * {
    native <methods>;
}

-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Android 15 : ces setters sont obsolètes. Les retirer du DEX
# (Flutter, sqflite, AccessibilityBridge) pour le contrôle Play.
-assumenosideeffects class android.view.Window {
    public void setStatusBarColor(int);
    public void setNavigationBarColor(int);
    public void setNavigationBarDividerColor(int);
}
