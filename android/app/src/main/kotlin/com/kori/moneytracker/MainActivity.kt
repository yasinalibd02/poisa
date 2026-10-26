package com.kori.moneytracker

import android.content.ContentValues
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
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
        const val OVERLAY_CHANNEL = "com.kori.moneytracker/overlay"

        // flutter_overlay_window caches the bubble's engine under this tag.
        const val OVERLAY_ENGINE_TAG = "myCachedEngine"

        // home_widget's launch action: tagging the intent with it lets
        // HomeWidgetService route bubble taps exactly like widget taps.
        const val HOME_WIDGET_LAUNCH_ACTION = "es.antonborri.home_widget.action.LAUNCH"
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

        registerOverlayChannel()
    }

    /**
     * The floating bubble runs in its own engine inside a Service, with no
     * Activity to launch from, so url_launcher cannot open the app from it.
     * This hands it a channel that starts MainActivity directly — allowed from
     * the background because the app holds "display over other apps".
     * The overlay plugin creates that engine when it attaches to this
     * Activity, which happens before configureFlutterEngine runs.
     */
    private fun registerOverlayChannel() {
        val overlayEngine = FlutterEngineCache.getInstance().get(OVERLAY_ENGINE_TAG) ?: return
        val appContext = applicationContext

        MethodChannel(overlayEngine.dartExecutor.binaryMessenger, OVERLAY_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method != "openApp") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }

                val intent = Intent(appContext, MainActivity::class.java).apply {
                    action = HOME_WIDGET_LAUNCH_ACTION
                    call.argument<String>("uri")?.let { data = Uri.parse(it) }
                    addFlags(
                        Intent.FLAG_ACTIVITY_NEW_TASK or
                            Intent.FLAG_ACTIVITY_SINGLE_TOP or
                            Intent.FLAG_ACTIVITY_REORDER_TO_FRONT,
                    )
                }
                try {
                    appContext.startActivity(intent)
                    result.success(true)
                } catch (error: Exception) {
                    result.error("launch_failed", error.message, null)
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
