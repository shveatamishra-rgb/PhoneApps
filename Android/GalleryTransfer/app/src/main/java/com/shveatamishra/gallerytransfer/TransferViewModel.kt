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
import com.shveatamishra.gallerytransfer.model.Album
import com.shveatamishra.gallerytransfer.model.MediaItem
import com.shveatamishra.gallerytransfer.net.TransferClient
import com.shveatamishra.gallerytransfer.ui.theme.ThemeMode
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class TransferViewModel(app: Application) : AndroidViewModel(app) {

    private val prefs = app.getSharedPreferences("gallery_transfer", Context.MODE_PRIVATE)
    private val media = MediaRepository(app)

    var host by mutableStateOf(prefs.getString("host", "") ?: "")
        private set
    var pin by mutableStateOf(prefs.getString("pin", "") ?: "")
        private set
    var themeMode by mutableStateOf(loadThemeMode())
        private set

    var albums by mutableStateOf<List<Album>>(emptyList())
        private set
    var currentAlbum by mutableStateOf<Album?>(null)
        private set
    var albumItems by mutableStateOf<List<MediaItem>>(emptyList())
        private set
    var selected by mutableStateOf<Map<Uri, MediaItem>>(emptyMap())
        private set
    var status by mutableStateOf("")
        private set
    var isBusy by mutableStateOf(false)
        private set

    val selectedItems: List<MediaItem> get() = selected.values.toList()
    val selectedBytes: Long get() = selectedItems.sumOf { it.sizeBytes }

    fun isSelected(uri: Uri): Boolean = selected.containsKey(uri)

    fun updateHost(value: String) {
        host = value
        prefs.edit().putString("host", value).apply()
    }

    fun updatePin(value: String) {
        pin = value
        prefs.edit().putString("pin", value).apply()
    }

    fun updateThemeMode(mode: ThemeMode) {
        themeMode = mode
        prefs.edit().putString("theme", mode.name).apply()
    }

    fun toggle(item: MediaItem) {
        selected = if (selected.containsKey(item.uri)) {
            selected - item.uri
        } else {
            selected + (item.uri to item)
        }
    }

    fun clearSelection() {
        selected = emptyMap()
    }

    fun loadAlbums() {
        viewModelScope.launch {
            isBusy = true
            status = "Loading folders…"
            val loaded = withContext(Dispatchers.IO) { media.albums() }
            albums = loaded
            status = if (loaded.isEmpty()) "No photos or videos found." else ""
            isBusy = false
        }
    }

    fun openAlbum(album: Album) {
        currentAlbum = album
        albumItems = emptyList()
        viewModelScope.launch {
            isBusy = true
            val loaded = withContext(Dispatchers.IO) { media.mediaInBucket(album.bucketId) }
            albumItems = loaded
            isBusy = false
        }
    }

    fun closeAlbum() {
        currentAlbum = null
        albumItems = emptyList()
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
            var lastError: String? = null
            for ((index, item) in targets.withIndex()) {
                status = "Uploading ${index + 1} of ${targets.size}: ${item.displayName}"
                val outcome = withContext(Dispatchers.IO) {
                    val source = media.originalSource(item.uri)
                    client.upload(
                        filename = item.displayName,
                        mimeType = item.mimeType,
                        contentLength = source.length,
                        openStream = source.open,
                    )
                }
                if (outcome.ok) {
                    ok++
                } else {
                    failed++
                    lastError = outcome.message
                }
            }
            status = buildString {
                append("Done. $ok sent")
                if (failed > 0) append(", $failed failed")
                append(".")
                if (failed > 0 && lastError != null) append(" — $lastError")
            }
            selected = emptyMap()
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
