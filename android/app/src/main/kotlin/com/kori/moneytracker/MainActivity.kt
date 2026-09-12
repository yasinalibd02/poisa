package com.kori.moneytracker

import android.content.ContentValues
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * Adds one capability Flutter has no plugin-free route to: putting a file the
 * user asked to download into the public Downloads collection.
 *
 * On API 29+ that has to go through MediaStore — an app cannot write into
 * shared storage by path any more, and `path_provider` deliberately offers no
 * Downloads directory on Android for exactly that reason. Below 29 the legacy
 * public directory still works and needs no runtime permission for a file the
 * app itself created.
 */
class MainActivity : FlutterActivity() {

    private companion object {
        const val CHANNEL = "com.kori.moneytracker/downloads"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method != "saveToDownloads") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }

                val fileName = call.argument<String>("fileName")
                val mimeType = call.argument<String>("mimeType")
                val bytes = call.argument<ByteArray>("bytes")

                if (fileName == null || mimeType == null || bytes == null) {
                    result.error("bad_args", "fileName, mimeType and bytes are required", null)
                    return@setMethodCallHandler
                }

                try {
                    result.success(saveToDownloads(fileName, mimeType, bytes))
                } catch (error: Exception) {
                    result.error("save_failed", error.message, null)
                }
            }
    }

    /** Returns the user-facing location the file landed in. */
    private fun saveToDownloads(fileName: String, mimeType: String, bytes: ByteArray): String {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val values = ContentValues().apply {
                put(MediaStore.Downloads.DISPLAY_NAME, fileName)
                put(MediaStore.Downloads.MIME_TYPE, mimeType)
                // Keeps the entry hidden from other apps until the bytes are
                // all there, so nothing can pick up a half-written export.
                put(MediaStore.Downloads.IS_PENDING, 1)
            }

            val resolver = contentResolver
            val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
                ?: throw IllegalStateException("Downloads is unavailable on this device")

            resolver.openOutputStream(uri)?.use { it.write(bytes) }
                ?: throw IllegalStateException("Could not open $uri for writing")

            values.clear()
            values.put(MediaStore.Downloads.IS_PENDING, 0)
            resolver.update(uri, values, null, null)

            return Environment.DIRECTORY_DOWNLOADS
        }

        val directory =
            Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
        if (!directory.exists() && !directory.mkdirs()) {
            throw IllegalStateException("Could not create ${directory.absolutePath}")
        }
        File(directory, fileName).writeBytes(bytes)
        return Environment.DIRECTORY_DOWNLOADS
    }
}
