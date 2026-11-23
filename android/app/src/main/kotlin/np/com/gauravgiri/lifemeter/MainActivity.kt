package np.com.gauravgiri.lifemeter

import android.app.WallpaperManager
import android.content.ContentValues
import android.graphics.BitmapFactory
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Hosts Flutter, plus a small channel for things done with a rendered PNG:
 * saving it to Pictures/LifeMeter and setting it as the lock screen.
 * Nothing leaves the device.
 */
class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            val bytes = call.argument<ByteArray>("bytes")
            if (bytes == null) {
                result.error("args", "Missing image bytes", null)
                return@setMethodCallHandler
            }
            when (call.method) {
                "saveImage" -> result.success(saveImage(bytes, call.argument<String>("name") ?: "lifemeter"))
                "setLockScreen" -> result.success(setLockScreen(bytes))
                else -> result.notImplemented()
            }
        }
    }

    /** MediaStore insert (Android 10+, no permission needed). */
    private fun saveImage(bytes: ByteArray, name: String): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return false
        return runCatching {
            val values = ContentValues().apply {
                put(MediaStore.Images.Media.DISPLAY_NAME, "$name-${System.currentTimeMillis()}.png")
                put(MediaStore.Images.Media.MIME_TYPE, "image/png")
                put(MediaStore.Images.Media.RELATIVE_PATH, Environment.DIRECTORY_PICTURES + "/LifeMeter")
            }
            val uri = contentResolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)
                ?: return false
            contentResolver.openOutputStream(uri)?.use { it.write(bytes) } ?: return false
            true
        }.getOrDefault(false)
    }

    private fun setLockScreen(bytes: ByteArray): Boolean = runCatching {
        val bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.size) ?: return false
        WallpaperManager.getInstance(this).setBitmap(bitmap, null, true, WallpaperManager.FLAG_LOCK)
        true
    }.getOrDefault(false)

    companion object {
        private const val CHANNEL = "lifemeter/device"
    }
}
