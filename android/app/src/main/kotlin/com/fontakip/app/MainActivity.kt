package com.fontakip.app

import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "com.fontakip.app/update"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "installApk") {
                val apkPath = call.argument<String>("apkPath")
                if (apkPath != null) {
                    val installSuccess = installApk(apkPath)
                    if (installSuccess) {
                        result.success("Kurulum başlatıldı")
                    } else {
                        result.error("INSTALL_FAILED", "Kurulum başlatılamadı", null)
                    }
                } else {
                    result.error("INVALID_PATH", "APK yolu boş", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun installApk(apkPath: String): Boolean {
        return try {
            val apkFile = File(apkPath)
            if (!apkFile.exists()) {
                return false
            }

            // Create content:// URI using FileProvider
            val apkUri: Uri = FileProvider.getUriForFile(
                this,
                "${packageName}.fileprovider",
                apkFile
            )

            // Create intent to install APK
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(apkUri, "application/vnd.android.package-archive")
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }

            startActivity(intent)
            true
        } catch (e: Exception) {
            false
        }
    }
}

