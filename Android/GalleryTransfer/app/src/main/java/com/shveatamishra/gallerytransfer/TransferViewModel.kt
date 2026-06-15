package com.shveatamishra.gallerytransfer

import android.app.Application
import android.content.Context
import android.net.Uri
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.shveatamishra.gallerytransfer.media.MediaRepository
import com.shveatamishra.gallerytransfer.model.MediaItem
import com.shveatamishra.gallerytransfer.net.TransferClient
import com.shveatamishra.gallerytransfer.ui.theme.ThemeMode
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.IOException

class TransferViewModel(app: Application) : AndroidViewModel(app) {

    private val prefs = app.getSharedPreferences("gallery_transfer", Context.MODE_PRIVATE)
    private val media = MediaRepository(app)

    var host by mutableStateOf(prefs.getString("host", "") ?: "")
        private set
    var pin by mutableStateOf(prefs.getString("pin", "") ?: "")
        private set
    var themeMode by mutableStateOf(loadThemeMode())
        private set

    var items by mutableStateOf<List<MediaItem>>(emptyList())
        private set
    var selected by mutableStateOf<Set<Uri>>(emptySet())
        private set
    var status by mutableStateOf("")
        private set
    var isBusy by mutableStateOf(false)
        private set

    val selectedItems: List<MediaItem> get() = items.filter { selected.contains(it.uri) }
    val selectedBytes: Long get() = selectedItems.sumOf { it.sizeBytes }

    fun setHost(value: String) {
        host = value
        prefs.edit().putString("host", value).apply()
    }

    fun setPin(value: String) {
        pin = value
        prefs.edit().putString("pin", value).apply()
    }

    fun setThemeMode(mode: ThemeMode) {
        themeMode = mode
        prefs.edit().putString("theme", mode.name).apply()
    }

    fun toggle(uri: Uri) {
        selected = if (selected.contains(uri)) selected - uri else selected + uri
    }

    fun clearSelection() {
        selected = emptySet()
    }

    fun loadMedia() {
        viewModelScope.launch {
            isBusy = true
            status = "Loading recent media…"
            val loaded = withContext(Dispatchers.IO) { media.recentMedia() }
            items = loaded
            selected = emptySet()
            status = if (loaded.isEmpty()) "No photos or videos found." else "${loaded.size} recent items."
            isBusy = false
        }
    }

    fun sendSelected() {
        val targets = selectedItems
        when {
            host.isBlank() || pin.isBlank() -> {
                status = "Enter the iPhone address and PIN first."
                return
            }
            targets.isEmpty() -> {
                status = "Select at least one item to send."
                return
            }
        }

        viewModelScope.launch {
            isBusy = true
            val client = TransferClient(normalizedHost(host), pin)
            var ok = 0
            var failed = 0
            for ((index, item) in targets.withIndex()) {
                status = "Uploading ${index + 1} of ${targets.size}: ${item.displayName}"
                val outcome = withContext(Dispatchers.IO) {
                    client.upload(
                        filename = item.displayName,
                        mimeType = item.mimeType,
                        contentLength = item.sizeBytes,
                        openStream = {
                            media.openOriginalStream(item.uri)
                                ?: throw IOException("Could not read ${item.displayName}")
                        },
                    )
                }
                if (outcome.ok) ok++ else failed++
            }
            status = buildString {
                append("Done. ")
                append("$ok sent")
                if (failed > 0) append(", $failed failed")
                append(".")
            }
            selected = emptySet()
            isBusy = false
        }
    }

    private fun loadThemeMode(): ThemeMode =
        runCatching { ThemeMode.valueOf(prefs.getString("theme", ThemeMode.SYSTEM.name)!!) }
            .getOrDefault(ThemeMode.SYSTEM)

    private fun normalizedHost(value: String): String {
        val trimmed = value.trim()
        return if (trimmed.startsWith("http://") || trimmed.startsWith("https://")) {
            trimmed
        } else {
            "http://$trimmed"
        }
    }
}
