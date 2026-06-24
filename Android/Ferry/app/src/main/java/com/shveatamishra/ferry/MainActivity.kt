package com.shveatamishra.ferry

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.viewModels
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Surface
import androidx.compose.ui.Modifier
import com.shveatamishra.ferry.ui.TransferScreen
import com.shveatamishra.ferry.ui.theme.FerryTheme

class MainActivity : ComponentActivity() {

    private val viewModel: TransferViewModel by viewModels()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            FerryTheme(themeMode = viewModel.themeMode) {
                Surface(modifier = Modifier.fillMaxSize()) {
                    TransferScreen(viewModel)
                }
            }
        }
    }
}
