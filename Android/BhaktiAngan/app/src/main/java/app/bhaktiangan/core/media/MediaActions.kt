package app.bhaktiangan.core.media

import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import android.os.Build
import android.provider.MediaStore

/** Shares the darshan text (deity + mantra + blessing) via the system chooser. */
fun shareDarshanText(context: Context, text: String) {
    val send = Intent(Intent.ACTION_SEND).apply {
        type = "text/plain"
        putExtra(Intent.EXTRA_TEXT, text)
    }
    context.startActivity(Intent.createChooser(send, null).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
}

/**
 * Saves a bundled darshan image to the Pictures/Bhakti Angan album via MediaStore.
 * No storage permission needed on API 29+. Returns true on success.
 */
fun saveDarshanWallpaper(context: Context, imageName: String): Boolean {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return false
    val resId = context.resources.getIdentifier(imageName, "drawable", context.packageName)
    if (resId == 0) return false
    val bitmap = BitmapFactory.decodeResource(context.resources, resId) ?: return false

    val values = ContentValues().apply {
        put(MediaStore.Images.Media.DISPLAY_NAME, "$imageName.jpg")
        put(MediaStore.Images.Media.MIME_TYPE, "image/jpeg")
        put(MediaStore.Images.Media.RELATIVE_PATH, "Pictures/Bhakti Angan")
        put(MediaStore.Images.Media.IS_PENDING, 1)
    }
    val resolver = context.contentResolver
    val uri = resolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values) ?: return false
    return try {
        resolver.openOutputStream(uri)?.use { out ->
            bitmap.compress(android.graphics.Bitmap.CompressFormat.JPEG, 95, out)
        }
        values.clear()
        values.put(MediaStore.Images.Media.IS_PENDING, 0)
        resolver.update(uri, values, null, null)
        true
    } catch (e: Exception) {
        false
    }
}
