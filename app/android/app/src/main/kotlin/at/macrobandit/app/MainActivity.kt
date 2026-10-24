package at.macrobandit.app

import android.app.Activity
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/** Adds "saveFile": lets the user pick a location (Storage Access Framework) and writes bytes there. */
class MainActivity : FlutterActivity() {
    private var pendingResult: MethodChannel.Result? = null
    private var pendingBytes: ByteArray? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "at.macrobandit.app/files")
            .setMethodCallHandler { call, result ->
                if (call.method != "saveFile") return@setMethodCallHandler result.notImplemented()
                if (pendingResult != null) return@setMethodCallHandler result.error("busy", null, null)
                pendingResult = result
                pendingBytes = call.argument<ByteArray>("bytes")
                val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                    addCategory(Intent.CATEGORY_OPENABLE)
                    type = call.argument<String>("mime")
                    putExtra(Intent.EXTRA_TITLE, call.argument<String>("name"))
                }
                startActivityForResult(intent, SAVE_REQUEST)
            }
    }

    @Deprecated("startActivityForResult keeps the activity free of extra dependencies")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != SAVE_REQUEST) return
        val result = pendingResult ?: return
        val bytes = pendingBytes
        pendingResult = null
        pendingBytes = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null || bytes == null) return result.success(false)
        try {
            contentResolver.openOutputStream(uri)?.use { it.write(bytes) }
            result.success(true)
        } catch (e: Exception) {
            result.error("write", e.message, null)
        }
    }

    companion object {
        private const val SAVE_REQUEST = 4711
    }
}
