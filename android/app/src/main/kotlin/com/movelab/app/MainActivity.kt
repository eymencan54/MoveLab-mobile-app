package com.movelab.app

import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.movelab.app/share"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "shareImage") {
                val bytes = call.argument<ByteArray>("bytes")
                val text = call.argument<String>("text")
                if (bytes != null) {
                    try {
                        shareImageBytes(bytes, text)
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("SHARE_ERROR", e.message, null)
                    }
                } else {
                    result.error("UNAVAILABLE", "Bytes not available.", null)
                }
            } else if (call.method == "shareText") {
                val text = call.argument<String>("text")
                if (text != null) {
                    try {
                        val intent = Intent(Intent.ACTION_SEND).apply {
                            type = "text/plain"
                            putExtra(Intent.EXTRA_TEXT, text)
                        }
                        startActivity(Intent.createChooser(intent, "Paylaş"))
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("SHARE_ERROR", e.message, null)
                    }
                } else {
                    result.error("UNAVAILABLE", "Text not available.", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun shareImageBytes(bytes: ByteArray, text: String?) {
        val fileName = "movelab_share_${System.currentTimeMillis()}.png"
        val file = File(cacheDir, fileName)
        file.writeBytes(bytes)
        
        val uri: Uri = FileProvider.getUriForFile(this, "$packageName.fileprovider", file)
        
        val intent = Intent(Intent.ACTION_SEND).apply {
            type = "image/png"
            putExtra(Intent.EXTRA_STREAM, uri)
            if (text != null) {
                putExtra(Intent.EXTRA_TEXT, text)
            }
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        startActivity(Intent.createChooser(intent, "Paylaş"))
    }
}
