package com.shveatamishra.gallerytransfer.net

import android.net.Uri
import okhttp3.HttpUrl.Companion.toHttpUrlOrNull
import okhttp3.MediaType.Companion.toMediaTypeOrNull
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody
import okio.BufferedSink
import okio.source
import java.io.InputStream
import java.util.concurrent.TimeUnit

/**
 * Talks to the iPhone app's local server. Uploads post the original bytes to
 * `/upload?filename=&pin=` with an `X-Original-Filename` header, matching what the
 * served web page does — so the same PIN-protected endpoint handles both.
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
                openStream().source().use { sink.writeAll(it) }
            }
        }

        val request = Request.Builder()
            .url(url)
            .header("X-Original-Filename", Uri.encode(filename))
            .post(body)
            .build()

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
        } catch (e: Exception) {
            UploadOutcome(false, e.message ?: "Upload failed.")
        }
    }
}
