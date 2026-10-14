package com.sdealsmobile.app

import android.os.Build
import android.os.Bundle
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsControllerCompat
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        WindowCompat.setDecorFitsSystemWindows(window, false)
        super.onCreate(savedInstanceState)
        applyLightSystemBars()
    }

    override fun onPostResume() {
        super.onPostResume()
        applyLightSystemBars()
    }

    // Appelé UNIQUEMENT quand Flutter a déjà tout dépilé (aucune route ni
    // PopScope ne consomme le retour) et demande de quitter. Les sous-écrans
    // se dépilent donc normalement, avant d'arriver ici.
    //
    // Par défaut (FlutterActivity, qui n'est pas une ComponentActivity) :
    // activity.finish() → moteur détruit → la réouverture est un démarrage à
    // froid complet. Sur Android 13+ (API 33+), quand Flutter ne gère pas le
    // retour, le système déplace lui-même la tâche en arrière-plan ; sur
    // Android 11 et moins le retour finit l'activité ; Android 12/12L
    // (API 31-32) passe par onBackPressed surchargé par Flutter → finish().
    // On aligne ces cas sur le comportement « application en arrière-plan »,
    // mais seulement dans les conditions où c'est correct :
    //  - activité RACINE de sa tâche (lancement depuis le lanceur, une
    //    notification ou un lien ouvert dans une nouvelle tâche) ;
    //  - activité NON racine (ouverte par-dessus une autre application, dans
    //    sa tâche) : on laisse le défaut finish() pour revenir à l'appelant,
    //    sans envoyer toute sa tâche en arrière-plan ;
    //  - si moveTaskToBack échoue (false) → comportement par défaut.
    override fun popSystemNavigator(): Boolean {
        if (!isTaskRoot) return false
        return moveTaskToBack(true)
    }

    // Bord à bord sans setStatusBarColor / setNavigationBarColor /
    // setNavigationBarDividerColor (obsolètes depuis Android 15).
    // Les icônes restent sombres ; le fond de fenêtre est blanc.
    private fun applyLightSystemBars() {
        WindowCompat.setDecorFitsSystemWindows(window, false)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            window.isNavigationBarContrastEnforced = false
            window.isStatusBarContrastEnforced = false
        }

        val controller = WindowInsetsControllerCompat(window, window.decorView)
        controller.isAppearanceLightStatusBars = true
        controller.isAppearanceLightNavigationBars = true
    }
}
