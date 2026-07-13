package app.bhaktiangan

import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.viewmodel.compose.viewModel

class MainActivity : ComponentActivity() {
    // One-shot deep-link route from a widget tap (e.g. "panchang"), consumed once by the UI.
    private var openRoute by mutableStateOf<String?>(null)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        openRoute = intent?.getStringExtra("open")
        setContent {
            val vm: AppViewModel = viewModel()
            BhaktiRoot(vm, openRoute = openRoute, onRouteConsumed = { openRoute = null })
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        openRoute = intent.getStringExtra("open")
    }
}
