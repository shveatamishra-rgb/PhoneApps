package com.shveatamishra.gallerytransfer.media

import android.content.ContentResolver
import android.content.ContentUris
import android.content.Context
import android.net.Uri
import android.provider.MediaStore
import com.shveatamishra.gallerytransfer.model.MediaItem
import com.shveatamishra.gallerytransfer.model.MediaKind
import java.io.InputStream

/**
 * Reads photos/videos from the device's shared media store. Unlike a browser upload,
 * this can open the *unredacted* original (GPS EXIF intact) via setRequireOriginal,
 * and it knows each item's real DISPLAY_NAME.
 */
class MediaRepository(private val context: Context) {

    private val resolver: ContentResolver get() = context.contentResolver

    fun recentMedia(limit: Int = 200): List<MediaItem> {
        val collection = MediaStore.Files.getContentUri(MediaStore.VOLUME_EXTERNAL)
        val projection = arrayOf(
            MediaStore.Files.FileColumns._ID,
            MediaStore.Files.FileColumns.DISPLAY_NAME,
            MediaStore.Files.FileColumns.SIZE,
            MediaStore.Files.FileColumns.MIME_TYPE,
            MediaStore.Files.FileColumns.MEDIA_TYPE,
        )
        val selection = "${MediaStore.Files.FileColumns.MEDIA_TYPE} IN (?, ?)"
        val selectionArgs = arrayOf(
            MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE.toString(),
            MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO.toString(),
        )
        val sortOrder = "${MediaStore.Files.FileColumns.DATE_ADDED} DESC"

        val result = ArrayList<MediaItem>()
        resolver.query(collection, projection, selection, selectionArgs, sortOrder)?.use { cursor ->
            val idCol = cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns._ID)
            val nameCol = cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.DISPLAY_NAME)
            val sizeCol = cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.SIZE)
            val mimeCol = cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.MIME_TYPE)
            val typeCol = cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.MEDIA_TYPE)

            while (cursor.moveToNext() && result.size < limit) {
                val id = cursor.getLong(idCol)
                val isVideo =
                    cursor.getInt(typeCol) == MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO
                val base = if (isVideo) {
                    MediaStore.Video.Media.EXTERNAL_CONTENT_URI
                } else {
                    MediaStore.Images.Media.EXTERNAL_CONTENT_URI
                }
                result += MediaItem(
                    uri = ContentUris.withAppendedId(base, id),
                    displayName = cursor.getString(nameCol) ?: "media_$id",
                    sizeBytes = cursor.getLong(sizeCol),
                    kind = if (isVideo) MediaKind.VIDEO else MediaKind.IMAGE,
                    mimeType = cursor.getString(mimeCol)
                        ?: if (isVideo) "video/mp4" else "image/jpeg",
                )
            }
        }
        return result
    }

    /**
     * Opens the original file. Requires ACCESS_MEDIA_LOCATION for GPS to survive; if it
     * isn't granted we fall back to the redacted copy so the transfer still works.
     */
    fun openOriginalStream(uri: Uri): InputStream? {
        return try {
            resolver.openInputStream(MediaStore.setRequireOriginal(uri))
        } catch (_: Exception) {
            try {
                resolver.openInputStream(uri)
            } catch (_: Exception) {
                null
            }
        }
    }
}
