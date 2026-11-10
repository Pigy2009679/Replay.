package com.replay.app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.MediaRecorder
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.IBinder
import android.os.Environment
import android.util.DisplayMetrics
import android.view.WindowManager
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class ReplayCaptureService : Service() {
    companion object {
        const val ACTION_START = "com.replay.app.START"
        const val ACTION_PAUSE = "com.replay.app.PAUSE"
        const val ACTION_RESUME = "com.replay.app.RESUME"
        const val ACTION_STOP = "com.replay.app.STOP"
        const val EXTRA_RESULT_CODE = "result_code"
        const val EXTRA_DATA = "result_data"
        private const val CHANNEL_ID = "replay_recording"
        private const val NOTIFICATION_ID = 7102

        fun listRecordings(context: Context): List<Map<String, Any>> {
            val baseDir = context.getExternalFilesDir(Environment.DIRECTORY_MOVIES) ?: context.filesDir
            val dir = File(baseDir, "REPLAY")
            if (!dir.exists()) return emptyList()
            return dir.listFiles()
                ?.filter { it.isFile && it.extension.lowercase() == "mp4" }
                ?.sortedByDescending { it.lastModified() }
                ?.map {
                    mapOf(
                        "path" to it.absolutePath,
                        "name" to it.name,
                        "createdAt" to it.lastModified(),
                        "sizeBytes" to it.length()
                    )
                } ?: emptyList()
        }
    }

    private var projection: MediaProjection? = null
    private var virtualDisplay: VirtualDisplay? = null
    private var recorder: MediaRecorder? = null
    private var outputFile: File? = null
    private var isPaused = false
    private var recordingStarted = false

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action
        if (action != ACTION_START && projection == null && recorder == null) {
            stopSelf(startId)
            return START_NOT_STICKY
        }
        when (action) {
            ACTION_START -> if (intent != null) beginCapture(intent)
            ACTION_PAUSE -> pauseCapture()
            ACTION_RESUME -> resumeCapture()
            ACTION_STOP -> stopCapture()
        }
        return START_NOT_STICKY
    }

    private fun beginCapture(intent: Intent) {
        if (projection != null || recorder != null) return
        try {
            createNotificationChannel()
            val notification = buildNotification("Screen recording is active")
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(
                    NOTIFICATION_ID,
                    notification,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION
                )
            } else {
                startForeground(NOTIFICATION_ID, notification)
            }

            val resultCode = intent.getIntExtra(EXTRA_RESULT_CODE, 0)
            @Suppress("DEPRECATION")
            val data = if (Build.VERSION.SDK_INT >= 33) {
                intent.getParcelableExtra(EXTRA_DATA, Intent::class.java)
            } else {
                intent.getParcelableExtra(EXTRA_DATA)
            } ?: throw IllegalStateException("Screen capture permission data is missing.")

            val manager = getSystemService(MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
            projection = manager.getMediaProjection(resultCode, data)
            projection?.registerCallback(object : MediaProjection.Callback() {
                override fun onStop() {
                    stopCapture()
                }
            }, null)
            startEncoder()
        } catch (e: Exception) {
            stopCapture()
        }
    }

    private fun startEncoder() {
        val metrics = DisplayMetrics()
        @Suppress("DEPRECATION")
        (getSystemService(WINDOW_SERVICE) as WindowManager).defaultDisplay.getRealMetrics(metrics)
        val scale = minOf(1.0, 1280.0 / maxOf(metrics.widthPixels, metrics.heightPixels))
        val width = ((metrics.widthPixels * scale).toInt() / 2) * 2
        val height = ((metrics.heightPixels * scale).toInt() / 2) * 2
        val baseDir = getExternalFilesDir(Environment.DIRECTORY_MOVIES) ?: filesDir
        val outputDir = File(baseDir, "REPLAY")
        if (!outputDir.exists() && !outputDir.mkdirs()) {
            throw IllegalStateException("Unable to create the recordings folder.")
        }
        val stamp = SimpleDateFormat("yyyy-MM-dd_HHmmss", Locale.US).format(Date())
        outputFile = File(outputDir, "REPLAY_$stamp.mp4")

        val r = if (Build.VERSION.SDK_INT >= 31) MediaRecorder(this) else @Suppress("DEPRECATION") MediaRecorder()
        recorder = r
        r.setVideoSource(MediaRecorder.VideoSource.SURFACE)
        r.setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
        r.setOutputFile(outputFile!!.absolutePath)
        r.setVideoEncoder(MediaRecorder.VideoEncoder.H264)
        r.setVideoSize(width.coerceAtLeast(2), height.coerceAtLeast(2))
        r.setVideoFrameRate(30)
        r.setVideoEncodingBitRate(4_000_000)
        r.prepare()
        virtualDisplay = projection?.createVirtualDisplay(
            "REPLAY Screen Capture",
            width, height, metrics.densityDpi,
            DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
            r.surface, null, null
        ) ?: throw IllegalStateException("Android could not create the screen capture display.")
        r.start()
        recordingStarted = true
    }

    private fun pauseCapture() {
        try {
            if (Build.VERSION.SDK_INT >= 24 && recorder != null && !isPaused) {
                recorder?.pause()
                isPaused = true
                updateNotification("Screen recording is paused")
            }
        } catch (_: Exception) {}
    }

    private fun resumeCapture() {
        try {
            if (Build.VERSION.SDK_INT >= 24 && recorder != null && isPaused) {
                recorder?.resume()
                isPaused = false
                updateNotification("Screen recording is active")
            }
        } catch (_: Exception) {}
    }

    private fun stopCapture() {
        val fileToFinalize = outputFile
        outputFile = null

        try {
            recorder?.let { activeRecorder ->
                try {
                    activeRecorder.stop()
                } catch (_: Exception) {
                    // MediaRecorder.stop can fail when no valid frames were written.
                } finally {
                    try { activeRecorder.reset() } catch (_: Exception) {}
                    try { activeRecorder.release() } catch (_: Exception) {}
                }
            }
        } finally {
            recorder = null
            try { virtualDisplay?.release() } catch (_: Exception) {}
            virtualDisplay = null

            val oldProjection = projection
            projection = null
            try { oldProjection?.stop() } catch (_: Exception) {}

            isPaused = false
            val validRecording = recordingStarted &&
                fileToFinalize != null &&
                fileToFinalize.exists() &&
                fileToFinalize.length() > 0L
            recordingStarted = false

            if (!validRecording) {
                try { fileToFinalize?.delete() } catch (_: Exception) {}
            }

            try { stopForeground(true) } catch (_: Exception) {}
            stopSelf()
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID, "REPLAY recording", NotificationManager.IMPORTANCE_LOW
            ).apply { description = "Visible status while REPLAY captures the screen." }
            getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
        }
    }

    private fun buildNotification(message: String): Notification {
        val stopIntent = Intent(this, ReplayCaptureService::class.java).setAction(ACTION_STOP)
        val stopPending = PendingIntent.getService(
            this, 1, stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }
        return builder
            .setContentTitle("REPLAY")
            .setContentText(message)
            .setSmallIcon(android.R.drawable.presence_video_online)
            .setOngoing(true)
            .addAction(android.R.drawable.ic_media_pause, "Stop", stopPending)
            .build()
    }

    private fun updateNotification(message: String) {
        getSystemService(NotificationManager::class.java)
            .notify(NOTIFICATION_ID, buildNotification(message))
    }

    override fun onDestroy() {
        if (projection != null || recorder != null) stopCapture()
        super.onDestroy()
    }
}
