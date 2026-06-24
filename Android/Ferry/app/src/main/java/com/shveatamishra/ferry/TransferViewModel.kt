package com.shveatamishra.ferry

import android.app.Application
import android.content.Context
import android.net.Uri
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.shveatamishra.ferry.media.MediaRepository
import com.shveatamishra.ferry.model.Album
import com.shveatamishra.ferry.model.MediaItem
import com.shveatamishra.ferry.model.RemoteFile
import com.shveatamishra.ferry.net.TransferClient
import com.shveatamishra.ferry.ui.theme.ThemeMode
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

enum class TransferMode { SEND, RECEIVE }

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
    var sentCount by mutableStateOf(0)
        private set
    var totalToSend by mutableStateOf(0)
        private set
    var uploadFraction by mutableStateOf(0.0)
        private set

    // Receive (iPhone -> Android) state
    var mode by mutableStateOf(TransferMode.SEND)
        private set
    var remoteFiles by mutableStateOf<List<RemoteFile>>(emptyList())
        private set
    var selectedRemote by mutableStateOf<Set<String>>(emptySet())
        private set
    var downloadedCount by mutableStateOf(0)
        private set
    var totalToDownload by mutableStateOf(0)
        private set
    var downloadFraction by mutableStateOf(0.0)
        private set

    val selectedItems: List<MediaItem> get() = selected.values.toList()
    val selectedBytes: Long get() = selectedItems.sumOf { it.sizeBytes }

    val selectedRemoteFiles: List<RemoteFile> get() = remoteFiles.filter { selectedRemote.contains(it.url) }
    val selectedRemoteBytes: Long get() = selectedRemoteFiles.sumOf { it.sizeBytes }
    val overallDownloadProgress: Float
        get() = if (totalToDownload == 0) 0f else ((downloadedCount + downloadFraction) / totalToDownload).toFloat()

    /** Overall send progress across files, including the current file's byte fraction. */
    val overallProgress: Float
        get() = if (totalToSend == 0) 0f else ((sentCount + uploadFraction) / totalToSend).toFloat()

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

    /** Select (or clear) every item taken on one date. */
    fun toggleDateSelection(items: List<MediaItem>) {
        val allSelected = items.all { selected.containsKey(it.uri) }
        selected = if (allSelected) {
            val uris = items.map { it.uri }.toSet()
            selected.filterKeys { it !in uris }
        } else {
            selected + items.associateBy { it.uri }
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

    fun updateMode(value: TransferMode) {
        mode = value
    }

    fun isRemoteSelected(url: String): Boolean = selectedRemote.contains(url)

    fun toggleRemote(file: RemoteFile) {
        selectedRemote = if (selectedRemote.contains(file.url)) {
            selectedRemote - file.url
        } else {
            selectedRemote + file.url
        }
    }

    fun selectAllRemote() {
        selectedRemote = remoteFiles.map { it.url }.toSet()
    }

    fun clearRemote() {
        selectedRemote = emptySet()
    }

    fun loadManifest() {
        if (host.isBlank() || pin.isBlank()) {
            status = "Enter the iPhone address and PIN first."
            return
        }
        viewModelScope.launch {
            isBusy = true
            status = "Looking for files on the iPhone..."
            val files = withContext(Dispatchers.IO) {
                TransferClient(normalizedHost(host), pin).fetchManifest()
            }
            remoteFiles = files
            selectedRemote = emptySet()
            status = if (files.isEmpty()) {
                "Nothing offered yet. On the iPhone, choose photos/videos to send, then refresh."
            } else {
                "${files.size} file${if (files.size == 1) "" else "s"} available."
            }
            isBusy = false
        }
    }

    fun downloadSelected() {
        val targets = selectedRemoteFiles
        if (targets.isEmpty()) {
            status = "Select at least one file to download."
            return
        }
        viewModelScope.launch {
            isBusy = true
            totalToDownload = targets.size
            downloadedCount = 0
            val client = TransferClient(normalizedHost(host), pin)
            var ok = 0
            var failed = 0
            for ((index, file) in targets.withIndex()) {
                status = "Downloading ${index + 1} of ${targets.size}: ${file.name}"
                downloadFraction = 0.0
                val saved = withContext(Dispatchers.IO) {
                    media.saveIncoming(file, client) { sent, total ->
                        if (total > 0) {
                            val fraction = sent.toDouble() / total
                            if (fraction >= 1.0 || fraction - downloadFraction >= 0.01) {
                                downloadFraction = fraction
                            }
                        }
                    }
                }
                if (saved) ok++ else failed++
                downloadedCount = index + 1
                downloadFraction = 0.0
            }
            status = buildString {
                append("Done. $ok saved to the gallery")
                if (failed > 0) append(", $failed failed")
                append(".")
            }
            selectedRemote = emptySet()
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
            totalToSend = targets.size
            sentCount = 0
            val client = TransferClient(normalizedHost(host), pin)
            var ok = 0
            var failed = 0
            var lastError: String? = null
            for ((index, item) in targets.withIndex()) {
                status = "Uploading ${index + 1} of ${targets.size}: ${item.displayName}"
                uploadFraction = 0.0
                val outcome = withContext(Dispatchers.IO) {
                    val source = media.originalSource(item.uri)
                    val meta = media.extractMeta(item.uri, item.kind)
                    client.upload(
                        filename = item.displayName,
                        mimeType = item.mimeType,
                        contentLength = source.length,
                        latitude = meta.latitude,
                        longitude = meta.longitude,
                        dateMillis = meta.dateMillis,
                        onProgress = { sent, total ->
                            if (total > 0) {
                                val fraction = sent.toDouble() / total
                                // throttle to ~1% steps to avoid recomposition spam
                                if (fraction >= 1.0 || fraction - uploadFraction >= 0.01) {
                                    uploadFraction = fraction
                                }
                            }
                        },
                        openStream = source.open,
                    )
                }
                if (outcome.ok) {
                    ok++
                } else {
                    failed++
                    lastError = outcome.message
                }
                sentCount = index + 1
                uploadFraction = 0.0
            }
            status = buildString {
                append("Done. $ok sent")
                if (failed > 0) append(", $failed failed")
                append(".")
                if (failed > 0 && lastError != null) append(" - $lastError")
            }
            selected = emptyMap()
            isBusy = false
        }
    }

    private fun loadThemeMode(): ThemeMode =
        runCatching { ThemeMode.valueOf(prefs.getString("theme", ThemeMode.DARK.name)!!) }
            .getOrDefault(ThemeMode.DARK)

    private fun normalizedHost(value: String): String {
        // Tolerate a full URL being pasted (or scanned): keep only host:port.
        val hostPort = value.trim()
            .removePrefix("https://")
            .removePrefix("http://")
            .substringBefore("/")
        return "http://$hostPort"
    }
}
