package com.shveatamishra.ferry.media

import android.content.ContentResolver
import android.content.ContentUris
import android.content.ContentValues
import android.content.Context
import android.content.res.AssetFileDescriptor
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.provider.MediaStore
import androidx.exifinterface.media.ExifInterface
import com.shveatamishra.ferry.model.Album
import com.shveatamishra.ferry.model.MediaItem
import com.shveatamishra.ferry.model.MediaKind
import com.shveatamishra.ferry.model.RemoteFile
import com.shveatamishra.ferry.net.TransferClient
import java.io.IOException
import java.io.InputStream
import java.text.SimpleDateFormat
import java.util.Locale
import java.util.TimeZone

/** A reopenable source of an item's original bytes plus the exact length to send. */
data class OriginalSource(val length: Long, val open: () -> InputStream)

/** Location/date read from an item's original, to send alongside the upload so the
 *  iPhone gets them even when the file's own metadata is awkward to parse there. */
data class MediaMeta(val latitude: Double?, val longitude: Double?, val dateMillis: Long?)

/**
 * Reads photos/videos from the device's shared media store. Unlike a browser upload,
 * this can open the *unredacted* original (GPS EXIF intact) via setRequireOriginal,
 * and it knows each item's real DISPLAY_NAME.
 */
class MediaRepository(private val context: Context) {

    private val resolver: ContentResolver get() = context.contentResolver

    /** Device folders (MediaStore buckets) that contain photos/videos, most-recently-active first. */
    fun albums(): List<Album> {
        val collection = MediaStore.Files.getContentUri(MediaStore.VOLUME_EXTERNAL)
        val projection = arrayOf(
            MediaStore.Files.FileColumns._ID,
            MediaStore.Files.FileColumns.BUCKET_ID,
            MediaStore.Files.FileColumns.BUCKET_DISPLAY_NAME,
            MediaStore.Files.FileColumns.MEDIA_TYPE,
        )
        val selection = "${MediaStore.Files.FileColumns.MEDIA_TYPE} IN (?, ?)"
        val selectionArgs = arrayOf(
            MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE.toString(),
            MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO.toString(),
        )
        val sortOrder = "${MediaStore.Files.FileColumns.DATE_ADDED} DESC"

        // Aggregate manually: insertion order (date desc) keeps the cover = newest item.
        val covers = LinkedHashMap<String, Uri>()
        val names = HashMap<String, String>()
        val counts = HashMap<String, Int>()

        resolver.query(collection, projection, selection, selectionArgs, sortOrder)?.use { cursor ->
            val idCol = cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns._ID)
            val bucketCol = cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.BUCKET_ID)
            val nameCol = cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.BUCKET_DISPLAY_NAME)
            val typeCol = cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.MEDIA_TYPE)

            while (cursor.moveToNext()) {
                val bucketId = cursor.getString(bucketCol) ?: continue
                counts[bucketId] = (counts[bucketId] ?: 0) + 1
                if (!covers.containsKey(bucketId)) {
                    val id = cursor.getLong(idCol)
                    val isVideo =
                        cursor.getInt(typeCol) == MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO
                    val base = if (isVideo) {
                        MediaStore.Video.Media.EXTERNAL_CONTENT_URI
                    } else {
                        MediaStore.Images.Media.EXTERNAL_CONTENT_URI
                    }
                    covers[bucketId] = ContentUris.withAppendedId(base, id)
                    names[bucketId] = cursor.getString(nameCol) ?: "Unknown"
                }
            }
        }

        return covers.map { (bucketId, cover) ->
            Album(
                bucketId = bucketId,
                name = names[bucketId] ?: "Unknown",
                coverUri = cover,
                count = counts[bucketId] ?: 0,
            )
        }
    }

    /** Photos/videos inside one folder, newest first. */
    fun mediaInBucket(bucketId: String, limit: Int = 5000): List<MediaItem> {
        val collection = MediaStore.Files.getContentUri(MediaStore.VOLUME_EXTERNAL)
        val projection = arrayOf(
            MediaStore.Files.FileColumns._ID,
            MediaStore.Files.FileColumns.DISPLAY_NAME,
            MediaStore.Files.FileColumns.SIZE,
            MediaStore.Files.FileColumns.MIME_TYPE,
            MediaStore.Files.FileColumns.MEDIA_TYPE,
            MediaStore.Files.FileColumns.DATE_TAKEN,
            MediaStore.Files.FileColumns.DATE_ADDED,
        )
        val selection = "${MediaStore.Files.FileColumns.BUCKET_ID} = ? AND " +
            "${MediaStore.Files.FileColumns.MEDIA_TYPE} IN (?, ?)"
        val selectionArgs = arrayOf(
            bucketId,
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
            val takenCol = cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.DATE_TAKEN)
            val addedCol = cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.DATE_ADDED)

            while (cursor.moveToNext() && result.size < limit) {
                val id = cursor.getLong(idCol)
                val isVideo =
                    cursor.getInt(typeCol) == MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO
                val base = if (isVideo) {
                    MediaStore.Video.Media.EXTERNAL_CONTENT_URI
                } else {
                    MediaStore.Images.Media.EXTERNAL_CONTENT_URI
                }
                val taken = cursor.getLong(takenCol)
                val dateMillis = if (taken > 0) taken else cursor.getLong(addedCol) * 1000L
                result += MediaItem(
                    uri = ContentUris.withAppendedId(base, id),
                    displayName = cursor.getString(nameCol) ?: "media_$id",
                    sizeBytes = cursor.getLong(sizeCol),
                    kind = if (isVideo) MediaKind.VIDEO else MediaKind.IMAGE,
                    mimeType = cursor.getString(mimeCol)
                        ?: if (isVideo) "video/mp4" else "image/jpeg",
                    dateTakenMillis = dateMillis,
                )
            }
        }
        return result
    }

    /**
     * Resolves the original file (GPS intact via setRequireOriginal when
     * ACCESS_MEDIA_LOCATION is granted, else the redacted copy) together with its exact
     * byte length, so the upload's Content-Length matches the bytes actually sent. A
     * length of -1 tells the uploader to stream chunked instead of declaring a length.
     */
    fun originalSource(uri: Uri): OriginalSource {
        val target = try {
            MediaStore.setRequireOriginal(uri)
        } catch (_: Exception) {
            uri
        }

        val length = try {
            resolver.openAssetFileDescriptor(target, "r")?.use { afd ->
                if (afd.length == AssetFileDescriptor.UNKNOWN_LENGTH) -1L else afd.length
            } ?: -1L
        } catch (_: Exception) {
            -1L
        }

        return OriginalSource(length) {
            resolver.openInputStream(target) ?: throw IOException("Could not open media stream")
        }
    }

    /** Reads GPS + capture date from the unredacted original (needs ACCESS_MEDIA_LOCATION). */
    fun extractMeta(uri: Uri, kind: MediaKind): MediaMeta {
        val target = try {
            MediaStore.setRequireOriginal(uri)
        } catch (_: Exception) {
            uri
        }
        return when (kind) {
            MediaKind.IMAGE -> extractImageMeta(target)
            MediaKind.VIDEO -> extractVideoMeta(target)
        }
    }

    private fun extractImageMeta(uri: Uri): MediaMeta {
        return try {
            resolver.openInputStream(uri)?.use { stream ->
                val exif = ExifInterface(stream)
                val latLong = exif.latLong
                MediaMeta(
                    latitude = latLong?.getOrNull(0),
                    longitude = latLong?.getOrNull(1),
                    dateMillis = exif.dateTimeOriginal ?: exif.dateTime,
                )
            } ?: MediaMeta(null, null, null)
        } catch (_: Exception) {
            MediaMeta(null, null, null)
        }
    }

    private fun extractVideoMeta(uri: Uri): MediaMeta {
        val retriever = MediaMetadataRetriever()
        return try {
            retriever.setDataSource(context, uri)
            val (lat, lng) = parseIso6709(
                retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_LOCATION)
            )
            MediaMeta(
                latitude = lat,
                longitude = lng,
                dateMillis = parseVideoDate(retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DATE)),
            )
        } catch (_: Exception) {
            MediaMeta(null, null, null)
        } finally {
            try {
                retriever.release()
            } catch (_: Exception) {
            }
        }
    }

    private fun parseIso6709(value: String?): Pair<Double?, Double?> {
        if (value.isNullOrBlank()) return null to null
        val numbers = Regex("[+-]\\d+(?:\\.\\d+)?")
            .findAll(value)
            .mapNotNull { it.value.toDoubleOrNull() }
            .toList()
        return if (numbers.size >= 2) numbers[0] to numbers[1] else null to null
    }

    private fun parseVideoDate(value: String?): Long? {
        if (value.isNullOrBlank()) return null
        val patterns = listOf("yyyyMMdd'T'HHmmss.SSS'Z'", "yyyyMMdd'T'HHmmss'Z'", "yyyy-MM-dd'T'HH:mm:ss'Z'")
        for (pattern in patterns) {
            try {
                val formatter = SimpleDateFormat(pattern, Locale.US)
                formatter.timeZone = TimeZone.getTimeZone("UTC")
                return formatter.parse(value)?.time
            } catch (_: Exception) {
            }
        }
        return null
    }

    /** Downloads one offered file straight into the gallery (Pictures/Ferry or Movies/Ferry). */
    fun saveIncoming(file: RemoteFile, client: TransferClient, onProgress: (Long, Long) -> Unit): Boolean {
        val collection = if (file.isVideo) {
            MediaStore.Video.Media.EXTERNAL_CONTENT_URI
        } else {
            MediaStore.Images.Media.EXTERNAL_CONTENT_URI
        }
        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, file.name)
            put(MediaStore.MediaColumns.MIME_TYPE, mimeFor(file.name, file.isVideo))
            put(MediaStore.MediaColumns.RELATIVE_PATH, if (file.isVideo) "Movies/Ferry" else "Pictures/Ferry")
            put(MediaStore.MediaColumns.IS_PENDING, 1)
        }
        val uri = resolver.insert(collection, values) ?: return false
        return try {
            val ok = resolver.openOutputStream(uri)?.use { out ->
                client.download(file.url, out, onProgress)
            } ?: false
            if (ok) {
                resolver.update(
                    uri,
                    ContentValues().apply { put(MediaStore.MediaColumns.IS_PENDING, 0) },
                    null,
                    null,
                )
                true
            } else {
                resolver.delete(uri, null, null)
                false
            }
        } catch (e: Exception) {
            resolver.delete(uri, null, null)
            false
        }
    }

    private fun mimeFor(name: String, isVideo: Boolean): String {
        val ext = name.substringAfterLast('.', "").lowercase()
        return android.webkit.MimeTypeMap.getSingleton().getMimeTypeFromExtension(ext)
            ?: if (isVideo) "video/mp4" else "image/jpeg"
    }
}
