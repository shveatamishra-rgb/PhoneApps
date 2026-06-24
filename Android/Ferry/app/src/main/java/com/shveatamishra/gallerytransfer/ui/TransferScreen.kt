package com.shveatamishra.gallerytransfer.ui

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.GridItemSpan
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.Send
import androidx.compose.material.icons.filled.AddCircleOutline
import androidx.compose.material.icons.filled.Brightness6
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Download
import androidx.compose.material.icons.filled.Photo
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.Videocam
import androidx.compose.material.icons.filled.PhotoLibrary
import androidx.compose.material.icons.filled.PlayCircle
import androidx.compose.material.icons.filled.QrCodeScanner
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Checkbox
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Surface
import androidx.compose.material3.Tab
import androidx.compose.material3.TabRow
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.core.content.ContextCompat
import coil.compose.AsyncImage
import com.google.mlkit.vision.barcode.common.Barcode
import com.google.mlkit.vision.codescanner.GmsBarcodeScannerOptions
import com.google.mlkit.vision.codescanner.GmsBarcodeScanning
import com.shveatamishra.gallerytransfer.TransferMode
import com.shveatamishra.gallerytransfer.TransferViewModel
import com.shveatamishra.gallerytransfer.model.Album
import com.shveatamishra.gallerytransfer.model.MediaItem
import com.shveatamishra.gallerytransfer.model.MediaKind
import com.shveatamishra.gallerytransfer.model.RemoteFile
import com.shveatamishra.gallerytransfer.ui.theme.ThemeMode
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TransferScreen(viewModel: TransferViewModel) {
    val context = LocalContext.current
    val permissions = remember { requiredPermissions() }
    var hasPermissions by remember { mutableStateOf(hasAll(context, permissions)) }
    val snackbarHostState = remember { SnackbarHostState() }

    val permissionLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestMultiplePermissions()
    ) {
        hasPermissions = hasAll(context, permissions)
        if (hasPermissions) viewModel.loadAlbums()
    }

    LaunchedEffect(Unit) {
        if (hasPermissions && viewModel.albums.isEmpty()) viewModel.loadAlbums()
    }

    LaunchedEffect(viewModel.status) {
        val message = viewModel.status
        if (message.isNotBlank() &&
            !message.startsWith("Loading") &&
            !message.startsWith("Uploading") &&
            !message.startsWith("Downloading") &&
            !message.startsWith("Looking")
        ) {
            snackbarHostState.showSnackbar(message)
        }
    }

    val inAlbum = viewModel.currentAlbum != null
    val sending = viewModel.mode == TransferMode.SEND

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(if (sending && inAlbum) viewModel.currentAlbum?.name ?: "Ferry" else "Ferry") },
                navigationIcon = {
                    if (sending && inAlbum) {
                        IconButton(onClick = { viewModel.closeAlbum() }) {
                            Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                        }
                    }
                },
                actions = {
                    ThemeMenu(viewModel)
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.surface,
                    titleContentColor = MaterialTheme.colorScheme.primary,
                    navigationIconContentColor = MaterialTheme.colorScheme.primary,
                ),
            )
        },
        bottomBar = {
            if (sending && (viewModel.selected.isNotEmpty() || viewModel.isBusy)) {
                SendBar(viewModel)
            } else if (!sending && (viewModel.selectedRemote.isNotEmpty() || viewModel.isBusy)) {
                DownloadBar(viewModel)
            }
        },
        snackbarHost = { SnackbarHost(snackbarHostState) },
    ) { padding ->
        Column(
            Modifier
                .padding(padding)
                .fillMaxSize()
        ) {
            TabRow(
                selectedTabIndex = if (sending) 0 else 1,
                containerColor = MaterialTheme.colorScheme.surface,
                contentColor = MaterialTheme.colorScheme.primary,
            ) {
                Tab(selected = sending, onClick = { viewModel.updateMode(TransferMode.SEND) }, text = { Text("Send") })
                Tab(selected = !sending, onClick = { viewModel.updateMode(TransferMode.RECEIVE) }, text = { Text("Receive") })
            }
            Box(Modifier.weight(1f).fillMaxWidth()) {
                if (sending) {
                    when {
                        !hasPermissions -> PermissionGate { permissionLauncher.launch(permissions) }
                        inAlbum -> PhotoGrid(viewModel)
                        else -> AlbumList(viewModel)
                    }
                } else {
                    ReceiveScreen(viewModel)
                }
            }
        }
    }
}

@Composable
private fun ReceiveScreen(viewModel: TransferViewModel) {
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(12.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        item { ConnectionCard(viewModel) }
        item {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Button(onClick = { viewModel.loadManifest() }, enabled = !viewModel.isBusy) {
                    Icon(Icons.Filled.Refresh, contentDescription = null, modifier = Modifier.size(18.dp))
                    Spacer(Modifier.width(8.dp))
                    Text("Load from iPhone")
                }
                Spacer(Modifier.weight(1f))
                if (viewModel.remoteFiles.isNotEmpty()) {
                    val allSelected = viewModel.selectedRemote.size == viewModel.remoteFiles.size
                    TextButton(onClick = { if (allSelected) viewModel.clearRemote() else viewModel.selectAllRemote() }) {
                        Text(if (allSelected) "Clear" else "Select all")
                    }
                }
            }
        }
        if (viewModel.remoteFiles.isEmpty()) {
            item {
                Text(
                    "On the iPhone, open Ferry, choose photos or videos to send, then tap Load. They download straight into your gallery.",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
        } else {
            items(viewModel.remoteFiles, key = { it.url }) { file ->
                RemoteFileRow(file, viewModel.isRemoteSelected(file.url)) { viewModel.toggleRemote(file) }
            }
        }
    }
}

@Composable
private fun RemoteFileRow(file: RemoteFile, selected: Boolean, onToggle: () -> Unit) {
    Card(
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        modifier = Modifier
            .fillMaxWidth()
            .clickable { onToggle() },
    ) {
        Row(
            Modifier
                .fillMaxWidth()
                .padding(12.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Icon(
                if (file.isVideo) Icons.Filled.Videocam else Icons.Filled.Photo,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.secondary,
                modifier = Modifier.size(22.dp),
            )
            Spacer(Modifier.width(12.dp))
            Column(Modifier.weight(1f)) {
                Text(
                    file.name,
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = FontWeight.Medium,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
                Text(
                    formatBytes(file.sizeBytes),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
            Checkbox(checked = selected, onCheckedChange = { onToggle() })
        }
    }
}

@Composable
private fun DownloadBar(viewModel: TransferViewModel) {
    Surface(color = MaterialTheme.colorScheme.surface, tonalElevation = 3.dp) {
        Column(Modifier.navigationBarsPadding()) {
            if (viewModel.isBusy && viewModel.totalToDownload > 0) {
                LinearProgressIndicator(
                    progress = { viewModel.overallDownloadProgress },
                    modifier = Modifier.fillMaxWidth(),
                    color = MaterialTheme.colorScheme.primary,
                )
            }
            Row(
                Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 12.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Column(Modifier.weight(1f)) {
                    if (viewModel.isBusy) {
                        Text(
                            viewModel.status.ifBlank { "Working..." },
                            maxLines = 2,
                            overflow = TextOverflow.Ellipsis,
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurface,
                        )
                    } else {
                        Text(
                            "${viewModel.selectedRemote.size} selected",
                            fontWeight = FontWeight.SemiBold,
                            color = MaterialTheme.colorScheme.secondary,
                        )
                        Text(
                            formatBytes(viewModel.selectedRemoteBytes),
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                        )
                    }
                }
                Spacer(Modifier.width(12.dp))
                Button(
                    onClick = { viewModel.downloadSelected() },
                    enabled = !viewModel.isBusy && viewModel.selectedRemote.isNotEmpty(),
                ) {
                    Icon(Icons.Filled.Download, contentDescription = null, modifier = Modifier.size(18.dp))
                    Spacer(Modifier.width(8.dp))
                    Text("Download")
                }
            }
        }
    }
}

@Composable
private fun AlbumList(viewModel: TransferViewModel) {
    LazyVerticalGrid(
        columns = GridCells.Fixed(2),
        contentPadding = androidx.compose.foundation.layout.PaddingValues(12.dp),
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
        modifier = Modifier.fillMaxSize(),
    ) {
        item(span = { GridItemSpan(maxLineSpan) }) { ConnectionCard(viewModel) }
        item(span = { GridItemSpan(maxLineSpan) }) {
            Text(
                "Gallery Folders",
                style = MaterialTheme.typography.titleMedium,
                color = MaterialTheme.colorScheme.onBackground,
            )
        }
        items(viewModel.albums, key = { it.bucketId }) { album ->
            AlbumCard(album) { viewModel.openAlbum(album) }
        }
    }
}

@Composable
private fun AlbumCard(album: Album, onClick: () -> Unit) {
    Column(Modifier.clickable { onClick() }) {
        Box(
            Modifier
                .fillMaxWidth()
                .aspectRatio(1f)
                .clip(RoundedCornerShape(14.dp))
                .background(MaterialTheme.colorScheme.surfaceVariant)
        ) {
            AsyncImage(
                model = album.coverUri,
                contentDescription = album.name,
                contentScale = ContentScale.Crop,
                modifier = Modifier.fillMaxSize(),
            )
        }
        Spacer(Modifier.height(6.dp))
        Text(
            album.name,
            style = MaterialTheme.typography.bodyMedium,
            fontWeight = FontWeight.Medium,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
        )
        Text(
            "${album.count} item${if (album.count == 1) "" else "s"}",
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
    }
}

@Composable
private fun PhotoGrid(viewModel: TransferViewModel) {
    val groups = remember(viewModel.albumItems) {
        viewModel.albumItems.groupBy { dayLabel(it.dateTakenMillis) }.toList()
    }
    LazyVerticalGrid(
        columns = GridCells.Adaptive(112.dp),
        contentPadding = androidx.compose.foundation.layout.PaddingValues(2.dp),
        horizontalArrangement = Arrangement.spacedBy(2.dp),
        verticalArrangement = Arrangement.spacedBy(2.dp),
        modifier = Modifier.fillMaxSize(),
    ) {
        groups.forEach { (label, items) ->
            item(span = { GridItemSpan(maxLineSpan) }, key = "header-$label") {
                DateHeader(
                    label = label,
                    count = items.size,
                    allSelected = items.all { viewModel.isSelected(it.uri) },
                    onToggle = { viewModel.toggleDateSelection(items) },
                )
            }
            items(items, key = { it.uri.toString() }) { item ->
                PhotoCell(
                    item = item,
                    selected = viewModel.isSelected(item.uri),
                    onToggle = { viewModel.toggle(item) },
                )
            }
        }
    }
}

@Composable
private fun DateHeader(label: String, count: Int, allSelected: Boolean, onToggle: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(start = 6.dp, end = 4.dp, top = 12.dp, bottom = 2.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Column(Modifier.weight(1f)) {
            Text(
                label,
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.SemiBold,
                color = MaterialTheme.colorScheme.onBackground,
            )
            Text(
                "$count item${if (count == 1) "" else "s"}",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
        TextButton(onClick = onToggle) {
            Icon(
                if (allSelected) Icons.Filled.CheckCircle else Icons.Filled.AddCircleOutline,
                contentDescription = null,
                modifier = Modifier.size(18.dp),
            )
            Spacer(Modifier.width(6.dp))
            Text(if (allSelected) "Clear" else "Select all")
        }
    }
}

private fun dayLabel(millis: Long): String {
    if (millis <= 0) return "Unknown date"
    val day = Calendar.getInstance().apply { timeInMillis = millis }
    val today = Calendar.getInstance()
    val yesterday = Calendar.getInstance().apply { add(Calendar.DAY_OF_YEAR, -1) }
    fun sameDay(a: Calendar, b: Calendar) =
        a.get(Calendar.YEAR) == b.get(Calendar.YEAR) && a.get(Calendar.DAY_OF_YEAR) == b.get(Calendar.DAY_OF_YEAR)
    return when {
        sameDay(day, today) -> "Today"
        sameDay(day, yesterday) -> "Yesterday"
        else -> SimpleDateFormat("MMMM d, yyyy", Locale.getDefault()).format(Date(millis))
    }
}

@Composable
private fun PhotoCell(item: MediaItem, selected: Boolean, onToggle: () -> Unit) {
    Box(
        Modifier
            .aspectRatio(1f)
            .fillMaxWidth()
            .clickable { onToggle() }
    ) {
        AsyncImage(
            model = item.uri,
            contentDescription = item.displayName,
            contentScale = ContentScale.Crop,
            modifier = Modifier.fillMaxSize(),
        )
        if (item.kind == MediaKind.VIDEO) {
            Icon(
                Icons.Filled.PlayCircle,
                contentDescription = "Video",
                tint = Color.White.copy(alpha = 0.92f),
                modifier = Modifier
                    .align(Alignment.Center)
                    .size(30.dp),
            )
        }
        if (selected) {
            Box(
                Modifier
                    .fillMaxSize()
                    .background(MaterialTheme.colorScheme.primary.copy(alpha = 0.40f))
            )
            Icon(
                Icons.Filled.CheckCircle,
                contentDescription = "Selected",
                tint = Color.White,
                modifier = Modifier
                    .align(Alignment.TopEnd)
                    .padding(4.dp)
                    .size(22.dp),
            )
        }
    }
}

@Composable
private fun ConnectionCard(viewModel: TransferViewModel) {
    val context = LocalContext.current
    Card(colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)) {
        Column(
            Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            Text(
                "iPhone connection",
                style = MaterialTheme.typography.titleMedium,
                color = MaterialTheme.colorScheme.primary,
            )
            Text(
                "Start the receiver in Ferry on the iPhone, then scan its QR code - or type the address and PIN it shows.",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
            Button(
                onClick = {
                    scanConnection(context) { host, pin ->
                        viewModel.updateHost(host)
                        if (pin != null) viewModel.updatePin(pin)
                    }
                },
                modifier = Modifier.fillMaxWidth(),
            ) {
                Icon(Icons.Filled.QrCodeScanner, contentDescription = null, modifier = Modifier.size(18.dp))
                Spacer(Modifier.width(8.dp))
                Text("Scan QR code")
            }
            OutlinedTextField(
                value = viewModel.host,
                onValueChange = viewModel::updateHost,
                label = { Text("Address") },
                placeholder = { Text("192.168.1.20:8899") },
                singleLine = true,
                modifier = Modifier.fillMaxWidth(),
            )
            OutlinedTextField(
                value = viewModel.pin,
                onValueChange = viewModel::updatePin,
                label = { Text("PIN") },
                placeholder = { Text("6-digit PIN") },
                singleLine = true,
                modifier = Modifier.fillMaxWidth(),
            )
        }
    }
}

@Composable
private fun SendBar(viewModel: TransferViewModel) {
    Surface(color = MaterialTheme.colorScheme.surface, tonalElevation = 3.dp) {
        // navigationBarsPadding keeps the controls above the system gesture/nav bar,
        // while the Surface colour still fills behind it.
        Column(Modifier.navigationBarsPadding()) {
            if (viewModel.isBusy && viewModel.totalToSend > 0) {
                LinearProgressIndicator(
                    progress = { viewModel.overallProgress },
                    modifier = Modifier.fillMaxWidth(),
                    color = MaterialTheme.colorScheme.primary,
                )
            }
            Row(
                Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 12.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Column(Modifier.weight(1f)) {
                    if (viewModel.isBusy) {
                        Text(
                            viewModel.status.ifBlank { "Working..." },
                            maxLines = 2,
                            overflow = TextOverflow.Ellipsis,
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurface,
                        )
                    } else {
                        Text(
                            "${viewModel.selected.size} selected",
                            fontWeight = FontWeight.SemiBold,
                            color = MaterialTheme.colorScheme.secondary,
                        )
                        Text(
                            formatBytes(viewModel.selectedBytes),
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                        )
                    }
                }
                Spacer(Modifier.width(12.dp))
                Button(
                    onClick = { viewModel.sendSelected() },
                    enabled = !viewModel.isBusy && viewModel.selected.isNotEmpty(),
                ) {
                    Icon(Icons.AutoMirrored.Filled.Send, contentDescription = null, modifier = Modifier.size(18.dp))
                    Spacer(Modifier.width(8.dp))
                    Text("Send")
                }
            }
        }
    }
}

@Composable
private fun PermissionGate(onGrant: () -> Unit) {
    Column(
        Modifier
            .fillMaxSize()
            .padding(24.dp),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Icon(
            Icons.Filled.PhotoLibrary,
            contentDescription = null,
            tint = MaterialTheme.colorScheme.primary,
            modifier = Modifier.size(48.dp),
        )
        Spacer(Modifier.height(12.dp))
        Text(
            "Ferry needs access to your photos and videos so it can send them - with location and filenames intact.",
            textAlign = TextAlign.Center,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
        Spacer(Modifier.height(16.dp))
        Button(onClick = onGrant) { Text("Grant access") }
    }
}

@Composable
private fun ThemeMenu(viewModel: TransferViewModel) {
    var expanded by remember { mutableStateOf(false) }
    IconButton(onClick = { expanded = true }) {
        Icon(
            Icons.Filled.Brightness6,
            contentDescription = "Appearance",
            tint = MaterialTheme.colorScheme.primary,
        )
    }
    DropdownMenu(expanded = expanded, onDismissRequest = { expanded = false }) {
        ThemeMode.values().forEach { mode ->
            DropdownMenuItem(
                text = { Text(mode.label()) },
                onClick = {
                    viewModel.updateThemeMode(mode)
                    expanded = false
                },
            )
        }
    }
}

private fun ThemeMode.label(): String = when (this) {
    ThemeMode.SYSTEM -> "System"
    ThemeMode.LIGHT -> "Light"
    ThemeMode.DARK -> "Dark"
}

private fun scanConnection(context: Context, onResult: (String, String?) -> Unit) {
    val options = GmsBarcodeScannerOptions.Builder()
        .setBarcodeFormats(Barcode.FORMAT_QR_CODE)
        .build()
    GmsBarcodeScanning.getClient(context, options).startScan()
        .addOnSuccessListener { barcode ->
            val raw = barcode.rawValue ?: return@addOnSuccessListener
            val uri = Uri.parse(raw)
            val host = uri.host ?: return@addOnSuccessListener
            val port = if (uri.port > 0) uri.port else 8899
            onResult("$host:$port", uri.getQueryParameter("pin"))
        }
}

private fun requiredPermissions(): Array<String> =
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
        arrayOf(
            Manifest.permission.READ_MEDIA_IMAGES,
            Manifest.permission.READ_MEDIA_VIDEO,
            Manifest.permission.ACCESS_MEDIA_LOCATION,
        )
    } else {
        arrayOf(
            Manifest.permission.READ_EXTERNAL_STORAGE,
            Manifest.permission.ACCESS_MEDIA_LOCATION,
        )
    }

private fun hasAll(context: Context, permissions: Array<String>): Boolean =
    permissions.all {
        ContextCompat.checkSelfPermission(context, it) == PackageManager.PERMISSION_GRANTED
    }

private fun formatBytes(bytes: Long): String {
    if (bytes <= 0) return "0 B"
    val units = arrayOf("B", "KB", "MB", "GB", "TB")
    var value = bytes.toDouble()
    var index = 0
    while (value >= 1024 && index < units.size - 1) {
        value /= 1024
        index++
    }
    return if (index == 0) "${value.toInt()} ${units[index]}" else String.format("%.1f %s", value, units[index])
}
