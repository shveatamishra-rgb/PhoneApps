package com.shveatamishra.gallerytransfer.ui

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
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
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.GridItemSpan
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.Send
import androidx.compose.material.icons.filled.Brightness6
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.PhotoLibrary
import androidx.compose.material.icons.filled.PlayCircle
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
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
import com.shveatamishra.gallerytransfer.TransferViewModel
import com.shveatamishra.gallerytransfer.model.Album
import com.shveatamishra.gallerytransfer.model.MediaItem
import com.shveatamishra.gallerytransfer.model.MediaKind
import com.shveatamishra.gallerytransfer.ui.theme.ThemeMode

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
        if (message.isNotBlank() && !message.startsWith("Loading") && !message.startsWith("Uploading")) {
            snackbarHostState.showSnackbar(message)
        }
    }

    val inAlbum = viewModel.currentAlbum != null

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(viewModel.currentAlbum?.name ?: "Ferry") },
                navigationIcon = {
                    if (inAlbum) {
                        IconButton(onClick = { viewModel.closeAlbum() }) {
                            Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                        }
                    }
                },
                actions = { ThemeMenu(viewModel) },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.surface,
                    titleContentColor = MaterialTheme.colorScheme.primary,
                    navigationIconContentColor = MaterialTheme.colorScheme.primary,
                ),
            )
        },
        bottomBar = {
            if (viewModel.selected.isNotEmpty() || viewModel.isBusy) {
                SendBar(viewModel)
            }
        },
        snackbarHost = { SnackbarHost(snackbarHostState) },
    ) { padding ->
        Box(
            Modifier
                .padding(padding)
                .fillMaxSize()
        ) {
            when {
                !hasPermissions -> PermissionGate { permissionLauncher.launch(permissions) }
                inAlbum -> PhotoGrid(viewModel)
                else -> AlbumList(viewModel)
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
                "Your folders",
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
    LazyVerticalGrid(
        columns = GridCells.Adaptive(112.dp),
        contentPadding = androidx.compose.foundation.layout.PaddingValues(2.dp),
        horizontalArrangement = Arrangement.spacedBy(2.dp),
        verticalArrangement = Arrangement.spacedBy(2.dp),
        modifier = Modifier.fillMaxSize(),
    ) {
        items(viewModel.albumItems, key = { it.uri.toString() }) { item ->
            PhotoCell(
                item = item,
                selected = viewModel.isSelected(item.uri),
                onToggle = { viewModel.toggle(item) },
            )
        }
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
                "Open Ferry on the iPhone, start the receiver, then enter the address and PIN it shows. (QR scan is coming next.)",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
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
        Row(
            Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 12.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Column(Modifier.weight(1f)) {
                if (viewModel.isBusy) {
                    Text(
                        viewModel.status.ifBlank { "Working…" },
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
            "Ferry needs access to your photos and videos so it can send them — with location and filenames intact.",
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
