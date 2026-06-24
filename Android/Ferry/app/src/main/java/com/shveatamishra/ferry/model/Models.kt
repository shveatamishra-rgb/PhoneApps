package com.shveatamishra.ferry.model

import android.net.Uri

enum class MediaKind { IMAGE, VIDEO }

/** A photo or video resolved from MediaStore, ready to upload as its original bytes. */
data class MediaItem(
    val uri: Uri,
    val displayName: String,
    val sizeBytes: Long,
    val kind: MediaKind,
    val mimeType: String,
    val dateTakenMillis: Long,
)

/** A device folder/album (a MediaStore bucket) with a cover and item count. */
data class Album(
    val bucketId: String,
    val name: String,
    val coverUri: Uri,
    val count: Int,
)

/** A file the iPhone is offering for download (from its /manifest.json). */
data class RemoteFile(
    val name: String,
    val sizeBytes: Long,
    val url: String,
    val isVideo: Boolean,
)
