package com.shveatamishra.gallerytransfer

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.viewModels
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Surface
import androidx.compose.ui.Modifier
import com.shveatamishra.gallerytransfer.ui.TransferScreen
import com.shveatamishra.gallerytransfer.ui.theme.GalleryTransferTheme

class MainActivity : ComponentActivity() {

    private val viewModel: TransferViewModel by viewModels()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            GalleryTransferTheme(themeMode = viewModel.themeMode) {
                Surface(modifier = Modifier.fillMaxSize()) {
                    TransferScreen(viewModel)
                }
            }
        }
    }
}
