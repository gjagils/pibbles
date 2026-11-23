package app.pibbles.android

import android.app.Application
import android.os.Bundle
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.appcompat.app.AppCompatActivity
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.SideEffect
import androidx.compose.runtime.saveable.rememberSaveableStateHolder
import androidx.core.content.res.ResourcesCompat
import pibbles.ui.RootView
import skip.foundation.ProcessInfo
import skip.ui.ColorScheme
import skip.ui.ComposeContext
import skip.ui.PresentationRoot
import skip.ui.UIApplication

class PibblesApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        ProcessInfo.launch(applicationContext)
        // Load Poppins and Inter off the main thread (as Hoeveelishet does with Montserrat):
        // SkipUI would otherwise load them on first use, on the main thread.
        Thread {
            for (font in listOf(R.font.poppins_semibold, R.font.poppins_bold, R.font.inter)) {
                ResourcesCompat.getFont(applicationContext, font)
            }
        }.start()
    }
}

// Thin host: all screens come from Packages/PibblesUI via Skip. Light or dark follows
// the system setting, as on iOS.
class MainActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        UIApplication.launch(this)
        enableEdgeToEdge()
        setContent {
            val stateHolder = rememberSaveableStateHolder()
            stateHolder.SaveableStateProvider(true) {
                val dark = isSystemInDarkTheme()
                PresentationRoot(defaultColorScheme = if (dark) ColorScheme.dark else ColorScheme.light, context = ComposeContext()) { context ->
                    Box(modifier = context.modifier.fillMaxSize()) {
                        RootView().Compose(context = context.content())
                    }
                }
                SideEffect { stateHolder.removeState(true) }
            }
        }
    }
}
