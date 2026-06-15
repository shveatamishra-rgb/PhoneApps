package com.shveatamishra.gallerytransfer.model

import android.net.Uri

enum class MediaKind { IMAGE, VIDEO }

/** A photo or video resolved from MediaStore, ready to upload as its original bytes. */
data class MediaItem(
    val uri: Uri,
    val displayName: String,
    val sizeBytes: Long,
    val kind: MediaKind,
    val mimeType: String,
)
