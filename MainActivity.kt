package com.replay.app

import android.app.Activity
import android.content.Intent
import android.media.projection.MediaProjectionManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.replay.app/screen_capture"
    private val captureRequestCode = 7412
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startRecording" -> {
                        if (pendingResult != null) {
                            result.error("BUSY", "A screen-capture permission request is already open.", null)
                            return@setMethodCallHandler
                        }
                        val manager = getSystemService(MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
                        pendingResult = result
                        try {
                            @Suppress("DEPRECATION")
                            startActivityForResult(manager.createScreenCaptureIntent(), captureRequestCode)
                        } catch (e: Exception) {
                            pendingResult = null
                            result.error("PERMISSION_REQUEST_FAILED", e.message, null)
                        }
                    }
                    "pauseRecording" -> sendServiceAction(ReplayCaptureService.ACTION_PAUSE, result)
                    "resumeRecording" -> sendServiceAction(ReplayCaptureService.ACTION_RESUME, result)
                    "stopRecording" -> sendServiceAction(ReplayCaptureService.ACTION_STOP, result)
                    "listRecordings" -> result.success(ReplayCaptureService.listRecordings(this))
                    else -> result.notImplemented()
                }
            }
    }

    @Deprecated("Deprecated by Android, retained for FlutterActivity compatibility")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != captureRequestCode) return

        val callback = pendingResult
        pendingResult = null
        if (resultCode != Activity.RESULT_OK || data == null) {
            callback?.success(false)
            return
        }

        val serviceIntent = Intent(this, ReplayCaptureService::class.java).apply {
            action = ReplayCaptureService.ACTION_START
            putExtra(ReplayCaptureService.EXTRA_RESULT_CODE, resultCode)
            putExtra(ReplayCaptureService.EXTRA_DATA, data)
        }
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(serviceIntent)
            } else {
                startService(serviceIntent)
            }
            callback?.success(true)
        } catch (e: Exception) {
            callback?.error("SERVICE_START_FAILED", e.message, null)
        }
    }

    private fun sendServiceAction(action: String, result: MethodChannel.Result) {
        try {
            val serviceIntent = Intent(this, ReplayCaptureService::class.java).setAction(action)
            startService(serviceIntent)
            result.success(null)
        } catch (e: Exception) {
            result.error("SERVICE_ERROR", e.message, null)
        }
    }
}
