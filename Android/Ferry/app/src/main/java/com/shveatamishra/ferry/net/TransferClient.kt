package com.shveatamishra.ferry.net

import android.net.Uri
import com.shveatamishra.ferry.model.RemoteFile
import okhttp3.HttpUrl.Companion.toHttpUrlOrNull
import okhttp3.MediaType.Companion.toMediaTypeOrNull
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody
import okio.Buffer
import okio.BufferedSink
import okio.ForwardingSink
import okio.buffer
import okio.source
import org.json.JSONObject
import java.io.InputStream
import java.io.OutputStream
import java.util.concurrent.TimeUnit

/**
 * Talks to the iPhone app's local server. Uploads post the original bytes to
 * `/upload?filename=&pin=` with an `X-Original-Filename` header, matching what the
 * served web page does - so the same PIN-protected endpoint handles both.
 */
class TransferClient(baseUrl: String, private val pin: String) {

    private val base = baseUrl.toHttpUrlOrNull()

    private val client = OkHttpClient.Builder()
        .connectTimeout(15, TimeUnit.SECONDS)
        .writeTimeout(0, TimeUnit.SECONDS) // large videos: don't time out the upload
        .readTimeout(60, TimeUnit.SECONDS)
        .build()

    data class UploadOutcome(val ok: Boolean, val message: String)

    fun upload(
        filename: String,
        mimeType: String,
        contentLength: Long,
        latitude: Double?,
        longitude: Double?,
        dateMillis: Long?,
        onProgress: (sent: Long, total: Long) -> Unit,
        openStream: () -> InputStream,
    ): UploadOutcome {
        val root = base ?: return UploadOutcome(false, "Invalid iPhone address.")
        val url = root.newBuilder()
            .addPathSegment("upload")
            .addQueryParameter("filename", filename)
            .addQueryParameter("pin", pin)
            .build()

        val body = object : RequestBody() {
            override fun contentType() =
                mimeType.ifBlank { "application/octet-stream" }.toMediaTypeOrNull()

            override fun contentLength() = contentLength

            override fun writeTo(sink: BufferedSink) {
                var written = 0L
                val counting = object : ForwardingSink(sink) {
                    override fun write(source: Buffer, byteCount: Long) {
                        super.write(source, byteCount)
                        written += byteCount
                        onProgress(written, contentLength)
                    }
                }
                val buffered = counting.buffer()
                openStream().source().use { buffered.writeAll(it) }
                buffered.flush()
            }
        }

        val requestBuilder = Request.Builder()
            .url(url)
            .header("X-Original-Filename", Uri.encode(filename))
        latitude?.let { requestBuilder.header("X-Media-Latitude", it.toString()) }
        longitude?.let { requestBuilder.header("X-Media-Longitude", it.toString()) }
        dateMillis?.let { requestBuilder.header("X-Media-Date", it.toString()) }
        val request = requestBuilder.post(body).build()

        return try {
            client.newCall(request).execute().use { response ->
                when {
                    response.code == 401 -> UploadOutcome(false, "PIN rejected by iPhone.")
                    response.isSuccessful -> UploadOutcome(true, "Saved to iPhone Photos.")
                    else -> {
                        val text = response.body?.string().orEmpty()
                        UploadOutcome(false, "Failed (${response.code}). $text")
                    }
                }
            }
        } catch (e: java.net.UnknownHostException) {
            UploadOutcome(false, "Couldn't find the iPhone on this network. Check both phones share the same Wi-Fi and the address matches what Ferry shows (a numeric address like 192.168.x.x, not iphone.local).")
        } catch (e: java.net.ConnectException) {
            UploadOutcome(false, "Connection refused - make sure the receiver is started in Ferry on the iPhone.")
        } catch (e: java.net.SocketTimeoutException) {
            UploadOutcome(false, "Timed out reaching the iPhone. Try again, closer to the router.")
        } catch (e: Exception) {
            UploadOutcome(false, e.message ?: "Upload failed.")
        }
    }

    /** Lists the files the iPhone is offering (its /manifest.json), with the PIN. */
    fun fetchManifest(): List<RemoteFile> {
        val root = base ?: return emptyList()
        val url = root.newBuilder()
            .addPathSegment("manifest.json")
            .addQueryParameter("pin", pin)
            .build()
        return try {
            client.newCall(Request.Builder().url(url).get().build()).execute().use { response ->
                if (!response.isSuccessful) return emptyList()
                val text = response.body?.string() ?: return emptyList()
                val files = JSONObject(text).optJSONArray("files") ?: return emptyList()
                (0 until files.length()).mapNotNull { index ->
                    val obj = files.optJSONObject(index) ?: return@mapNotNull null
                    val name = obj.optString("name").ifBlank { return@mapNotNull null }
                    val path = obj.optString("url").ifBlank { return@mapNotNull null }
                    val link = root.resolve(path) ?: return@mapNotNull null
                    val withPin = link.newBuilder().addQueryParameter("pin", pin).build()
                    RemoteFile(
                        name = name,
                        sizeBytes = obj.optLong("size"),
                        url = withPin.toString(),
                        isVideo = isVideoName(name),
                    )
                }
            }
        } catch (e: Exception) {
            emptyList()
        }
    }

    /** Downloads one offered file into [output], reporting bytes received. */
    fun download(url: String, output: OutputStream, onProgress: (sent: Long, total: Long) -> Unit): Boolean {
        return try {
            client.newCall(Request.Builder().url(url).get().build()).execute().use { response ->
                if (!response.isSuccessful) return false
                val body = response.body ?: return false
                val total = body.contentLength()
                var written = 0L
                body.byteStream().use { input ->
                    val buffer = ByteArray(64 * 1024)
                    while (true) {
                        val read = input.read(buffer)
                        if (read < 0) break
                        output.write(buffer, 0, read)
                        written += read
                        onProgress(written, total)
                    }
                }
                true
            }
        } catch (e: Exception) {
            false
        }
    }

    private fun isVideoName(name: String): Boolean {
        val ext = name.substringAfterLast('.', "").lowercase()
        return ext in setOf("mp4", "mov", "m4v", "3gp", "3gpp", "webm", "mkv", "avi")
    }
}
