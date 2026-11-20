package com.technexa.rhythmflow

import android.app.Activity
import android.app.RecoverableSecurityException
import android.content.ContentUris
import android.content.ContentValues
import android.content.Intent
import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMuxer
import android.media.MediaScannerConnection
import android.media.RingtoneManager
import android.provider.Settings
import java.nio.ByteBuffer
import android.os.Environment
import android.database.ContentObserver
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * Main activity. Extends AudioServiceActivity (required by audio_service) and
 * adds a small MediaStore bridge:
 *
 *  - `deleteAudioFile(path)`: deletes a song the user chose to delete. On
 *    Android 11+ apps may not delete media files they did not create with
 *    java.io.File, so a system consent dialog (MediaStore.createDeleteRequest)
 *    is shown. Android 10 uses RecoverableSecurityException, older versions a
 *    plain delete.
 *  - `saveAudioToMusic(tempPath, fileName, title, artist, album)`: copies a
 *    downloaded Discover song into Music/RhythmFlow (MediaStore insert on
 *    Android 10+, direct write + media scan before) and returns its path.
 *  - `startObserving` / `stopObserving`: a ContentObserver on the audio
 *    collection; Dart is notified (`onMediaStoreChanged`) whenever audio files
 *    are added, changed or removed so the library refreshes while the app is
 *    open.
 *  - Ringtones: `saveRingtone`, `setDefaultRingtone`, `canWriteSettings`,
 *    `openWriteSettings`, `renameRingtone`, `deleteRingtone` and
 *    `trimAudio` (lossless AAC/M4A cut with MediaExtractor + MediaMuxer).
 */
class MainActivity : AudioServiceActivity() {

    companion object {
        private const val CHANNEL = "com.technexa.rhythmflow/media_store"
        private const val DELETE_REQUEST_CODE = 4711
    }

    private data class PendingDelete(
        val uri: Uri,
        val result: MethodChannel.Result,
        val deleteAfterConsent: Boolean,
    )

    private var channel: MethodChannel? = null
    private var audioObserver: ContentObserver? = null
    private var pendingDelete: PendingDelete? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).also {
            it.setMethodCallHandler { call, result ->
                when (call.method) {
                    "deleteAudioFile" -> {
                        val path = call.argument<String>("path")
                        if (path.isNullOrEmpty()) {
                            result.error("bad_args", "path is required", null)
                        } else {
                            deleteAudioFile(path, result)
                        }
                    }
                    "saveAudioToMusic" -> {
                        val tempPath = call.argument<String>("tempPath")
                        val fileName = call.argument<String>("fileName")
                        if (tempPath.isNullOrEmpty() || fileName.isNullOrEmpty()) {
                            result.error("bad_args", "tempPath and fileName are required", null)
                        } else {
                            saveAudioToMusic(
                                tempPath,
                                fileName,
                                call.argument<String>("title"),
                                call.argument<String>("artist"),
                                call.argument<String>("album"),
                                result,
                            )
                        }
                    }
                    "startObserving" -> {
                        registerAudioObserver()
                        result.success(true)
                    }
                    "stopObserving" -> {
                        unregisterAudioObserver()
                        result.success(true)
                    }
                    "saveRingtone" -> {
                        val tempPath = call.argument<String>("tempPath")
                        val fileName = call.argument<String>("fileName")
                        if (tempPath.isNullOrEmpty() || fileName.isNullOrEmpty()) {
                            result.error("bad_args", "tempPath and fileName are required", null)
                        } else {
                            background(result) {
                                saveRingtone(
                                    tempPath,
                                    fileName,
                                    call.argument<String>("title") ?: fileName,
                                    call.argument<String>("mimeType") ?: "audio/mpeg",
                                    call.argument<String>("artist"),
                                )
                            }
                        }
                    }
                    "canWriteSettings" -> result.success(canWriteSettings())
                    "openWriteSettings" -> {
                        try {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                                startActivity(
                                    Intent(Settings.ACTION_MANAGE_WRITE_SETTINGS)
                                        .setData(Uri.parse("package:$packageName"))
                                        .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
                                )
                            }
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("open_failed", e.message, null)
                        }
                    }
                    "setDefaultRingtone" -> {
                        val uri = call.argument<String>("uri")
                        val type = call.argument<String>("type") ?: "ringtone"
                        if (uri.isNullOrEmpty()) {
                            result.error("bad_args", "uri is required", null)
                        } else if (!canWriteSettings()) {
                            result.error("no_permission", "Modify system settings is not allowed", null)
                        } else {
                            try {
                                val kind = when (type) {
                                    "notification" -> RingtoneManager.TYPE_NOTIFICATION
                                    "alarm" -> RingtoneManager.TYPE_ALARM
                                    else -> RingtoneManager.TYPE_RINGTONE
                                }
                                RingtoneManager.setActualDefaultRingtoneUri(this, kind, Uri.parse(uri))
                                result.success(true)
                            } catch (e: Exception) {
                                result.error("set_failed", e.message, null)
                            }
                        }
                    }
                    "renameRingtone" -> {
                        val uri = call.argument<String>("uri")
                        val path = call.argument<String>("path")
                        val fileName = call.argument<String>("fileName")
                        val title = call.argument<String>("title")
                        if (fileName.isNullOrEmpty()) {
                            result.error("bad_args", "fileName is required", null)
                        } else {
                            background(result) { renameRingtone(uri, path, fileName, title ?: fileName) }
                        }
                    }
                    "deleteRingtone" -> {
                        val uri = call.argument<String>("uri")
                        val path = call.argument<String>("path")
                        background(result) { deleteRingtone(uri, path) }
                    }
                    "trimAudio" -> {
                        val input = call.argument<String>("inputPath")
                        val output = call.argument<String>("outputPath")
                        val startMs = call.argument<Number>("startMs")?.toLong() ?: 0L
                        val endMs = call.argument<Number>("endMs")?.toLong() ?: 0L
                        if (input.isNullOrEmpty() || output.isNullOrEmpty() || endMs <= startMs) {
                            result.error("bad_args", "inputPath, outputPath and a valid range are required", null)
                        } else {
                            Thread {
                                try {
                                    val ms = trimWithMuxer(input, output, startMs, endMs)
                                    runOnUiThread { result.success(ms) }
                                } catch (e: UnsupportedOperationException) {
                                    runOnUiThread { result.error("unsupported", e.message, null) }
                                } catch (e: Exception) {
                                    runOnUiThread { result.error("trim_failed", e.message, null) }
                                }
                            }.start()
                        }
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    override fun onDestroy() {
        unregisterAudioObserver()
        pendingDelete?.let { it.result.success(false) }
        pendingDelete = null
        super.onDestroy()
    }

    // ==================== OBSERVER ====================

    private fun registerAudioObserver() {
        if (audioObserver != null) return
        val observer = object : ContentObserver(Handler(Looper.getMainLooper())) {
            override fun onChange(selfChange: Boolean) {
                channel?.invokeMethod("onMediaStoreChanged", null)
            }
        }
        try {
            contentResolver.registerContentObserver(
                MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                true,
                observer,
            )
            audioObserver = observer
        } catch (_: Exception) {
            // Observing is best effort; the app still refreshes on resume.
        }
    }

    private fun unregisterAudioObserver() {
        audioObserver?.let {
            try {
                contentResolver.unregisterContentObserver(it)
            } catch (_: Exception) {
            }
        }
        audioObserver = null
    }

    // ==================== SAVE DOWNLOAD ====================

    private fun saveAudioToMusic(
        tempPath: String,
        fileName: String,
        title: String?,
        artist: String?,
        album: String?,
        result: MethodChannel.Result,
    ) {
        Thread {
            try {
                val path = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    insertIntoMediaStore(tempPath, fileName, title, artist, album)
                } else {
                    writeLegacy(tempPath, fileName)
                }
                runOnUiThread { result.success(path) }
            } catch (e: Exception) {
                runOnUiThread { result.error("save_failed", e.message, null) }
            }
        }.start()
    }

    @Suppress("DEPRECATION")
    private fun insertIntoMediaStore(
        tempPath: String,
        fileName: String,
        title: String?,
        artist: String?,
        album: String?,
    ): String {
        val collection = MediaStore.Audio.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        val values = ContentValues().apply {
            put(MediaStore.Audio.Media.DISPLAY_NAME, fileName)
            put(MediaStore.Audio.Media.MIME_TYPE, "audio/mpeg")
            put(MediaStore.Audio.Media.RELATIVE_PATH, Environment.DIRECTORY_MUSIC + "/RhythmFlow")
            put(MediaStore.Audio.Media.IS_PENDING, 1)
            if (!title.isNullOrEmpty()) put(MediaStore.Audio.Media.TITLE, title)
            if (!artist.isNullOrEmpty()) put(MediaStore.Audio.Media.ARTIST, artist)
            if (!album.isNullOrEmpty()) put(MediaStore.Audio.Media.ALBUM, album)
        }
        val uri = contentResolver.insert(collection, values)
            ?: throw IllegalStateException("MediaStore insert failed")
        try {
            contentResolver.openOutputStream(uri)?.use { out ->
                File(tempPath).inputStream().use { input -> input.copyTo(out) }
            } ?: throw IllegalStateException("Cannot open output stream")
            values.clear()
            values.put(MediaStore.Audio.Media.IS_PENDING, 0)
            contentResolver.update(uri, values, null, null)
        } catch (e: Exception) {
            contentResolver.delete(uri, null, null)
            throw e
        }
        contentResolver.query(uri, arrayOf(MediaStore.Audio.Media.DATA), null, null, null)
            ?.use { c -> if (c.moveToFirst()) return c.getString(0) }
        return Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_MUSIC)
            .absolutePath + "/RhythmFlow/" + fileName
    }

    @Suppress("DEPRECATION")
    private fun writeLegacy(tempPath: String, fileName: String): String {
        val dir = File(
            Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_MUSIC),
            "RhythmFlow",
        )
        if (!dir.exists() && !dir.mkdirs()) throw IllegalStateException("Cannot create $dir")
        var target = File(dir, fileName)
        var n = 1
        while (target.exists()) {
            target = File(dir, fileName.removeSuffix(".mp3") + " ($n).mp3")
            n++
        }
        File(tempPath).copyTo(target)
        MediaScannerConnection.scanFile(this, arrayOf(target.absolutePath), arrayOf("audio/mpeg"), null)
        return target.absolutePath
    }

    // ==================== RINGTONES ====================

    private fun background(result: MethodChannel.Result, work: () -> Any?) {
        Thread {
            try {
                val value = work()
                runOnUiThread { result.success(value) }
            } catch (e: Exception) {
                runOnUiThread { result.error("ringtone_failed", e.message, null) }
            }
        }.start()
    }

    private fun canWriteSettings(): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.M || Settings.System.canWrite(this)

    /** Saves into Ringtones/RhythmFlow and returns {uri, path}. */
    @Suppress("DEPRECATION")
    private fun saveRingtone(
        tempPath: String,
        fileName: String,
        title: String,
        mimeType: String,
        artist: String?,
    ): Map<String, String> {
        val values = ContentValues().apply {
            put(MediaStore.Audio.Media.TITLE, title)
            put(MediaStore.Audio.Media.MIME_TYPE, mimeType)
            put(MediaStore.Audio.Media.IS_RINGTONE, 1)
            put(MediaStore.Audio.Media.IS_NOTIFICATION, 1)
            put(MediaStore.Audio.Media.IS_ALARM, 1)
            put(MediaStore.Audio.Media.IS_MUSIC, 0)
            if (!artist.isNullOrEmpty()) put(MediaStore.Audio.Media.ARTIST, artist)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val collection = MediaStore.Audio.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
            values.put(MediaStore.Audio.Media.DISPLAY_NAME, fileName)
            values.put(MediaStore.Audio.Media.RELATIVE_PATH, Environment.DIRECTORY_RINGTONES + "/RhythmFlow")
            values.put(MediaStore.Audio.Media.IS_PENDING, 1)
            val uri = contentResolver.insert(collection, values)
                ?: throw IllegalStateException("MediaStore insert failed")
            try {
                contentResolver.openOutputStream(uri)?.use { out ->
                    File(tempPath).inputStream().use { input -> input.copyTo(out) }
                } ?: throw IllegalStateException("Cannot open output stream")
                val done = ContentValues().apply { put(MediaStore.Audio.Media.IS_PENDING, 0) }
                contentResolver.update(uri, done, null, null)
            } catch (e: Exception) {
                contentResolver.delete(uri, null, null)
                throw e
            }
            var path = ""
            contentResolver.query(uri, arrayOf(MediaStore.Audio.Media.DATA), null, null, null)
                ?.use { c -> if (c.moveToFirst()) path = c.getString(0) ?: "" }
            return mapOf("uri" to uri.toString(), "path" to path)
        }
        val dir = File(
            Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_RINGTONES),
            "RhythmFlow",
        )
        if (!dir.exists() && !dir.mkdirs()) throw IllegalStateException("Cannot create $dir")
        val dot = fileName.lastIndexOf('.')
        val base = if (dot > 0) fileName.substring(0, dot) else fileName
        val ext = if (dot > 0) fileName.substring(dot) else ""
        var target = File(dir, fileName)
        var n = 1
        while (target.exists()) {
            target = File(dir, "$base ($n)$ext")
            n++
        }
        File(tempPath).copyTo(target)
        values.put(MediaStore.Audio.Media.DATA, target.absolutePath)
        val uri = contentResolver.insert(
            MediaStore.Audio.Media.getContentUriForPath(target.absolutePath)
                ?: MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
            values,
        ) ?: throw IllegalStateException("MediaStore insert failed")
        return mapOf("uri" to uri.toString(), "path" to target.absolutePath)
    }

    /** Renames a ringtone this app created. Returns the new path. */
    @Suppress("DEPRECATION")
    private fun renameRingtone(uri: String?, path: String?, fileName: String, title: String): String {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q && !uri.isNullOrEmpty()) {
            val target = Uri.parse(uri)
            val values = ContentValues().apply {
                put(MediaStore.Audio.Media.DISPLAY_NAME, fileName)
                put(MediaStore.Audio.Media.TITLE, title)
            }
            try {
                contentResolver.update(target, values, null, null)
            } catch (e: SecurityException) {
                // Made by an earlier install of the app: no longer ours.
                throw IllegalStateException(
                    "Android did not allow renaming this ringtone (it was made by an earlier install). Make a new one instead",
                )
            }
            var newPath = path ?: ""
            contentResolver.query(target, arrayOf(MediaStore.Audio.Media.DATA), null, null, null)
                ?.use { c -> if (c.moveToFirst()) newPath = c.getString(0) ?: newPath }
            return newPath
        }
        if (path.isNullOrEmpty()) throw IllegalStateException("No file to rename")
        val from = File(path)
        val to = File(from.parentFile, fileName)
        if (to.exists() && to.absolutePath != from.absolutePath) {
            throw IllegalStateException("A ringtone with that name already exists")
        }
        if (!from.renameTo(to)) throw IllegalStateException("Rename failed")
        if (!uri.isNullOrEmpty()) {
            val values = ContentValues().apply {
                put(MediaStore.Audio.Media.DATA, to.absolutePath)
                put(MediaStore.Audio.Media.TITLE, title)
                put(MediaStore.Audio.Media.DISPLAY_NAME, fileName)
            }
            try {
                contentResolver.update(Uri.parse(uri), values, null, null)
            } catch (_: Exception) {
            }
        }
        return to.absolutePath
    }

    /** Deletes a ringtone this app created (no consent dialog needed). */
    private fun deleteRingtone(uri: String?, path: String?): Boolean {
        var deleted = false
        if (!uri.isNullOrEmpty()) {
            try {
                deleted = contentResolver.delete(Uri.parse(uri), null, null) > 0
            } catch (_: Exception) {
            }
        }
        if (!path.isNullOrEmpty()) {
            val file = File(path)
            if (file.exists()) deleted = file.delete() || deleted
            else deleted = true
        }
        return deleted
    }

    /**
     * Copies the audio samples between [startMs] and [endMs] into an MP4/M4A
     * container without re-encoding. Returns the kept duration in ms.
     */
    private fun trimWithMuxer(input: String, output: String, startMs: Long, endMs: Long): Long {
        val extractor = MediaExtractor()
        var muxer: MediaMuxer? = null
        try {
            extractor.setDataSource(input)
            var track = -1
            var format: MediaFormat? = null
            for (i in 0 until extractor.trackCount) {
                val f = extractor.getTrackFormat(i)
                val mime = f.getString(MediaFormat.KEY_MIME) ?: ""
                if (mime.startsWith("audio/")) {
                    track = i
                    format = f
                    break
                }
            }
            if (track < 0 || format == null) throw UnsupportedOperationException("No audio track")
            val mime = format.getString(MediaFormat.KEY_MIME) ?: ""
            if (mime != MediaFormat.MIMETYPE_AUDIO_AAC) {
                throw UnsupportedOperationException("Only AAC audio can be cut without re-encoding ($mime)")
            }
            extractor.selectTrack(track)
            muxer = MediaMuxer(output, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
            val outTrack = muxer.addTrack(format)
            muxer.start()
            val size = if (format.containsKey(MediaFormat.KEY_MAX_INPUT_SIZE)) {
                format.getInteger(MediaFormat.KEY_MAX_INPUT_SIZE)
            } else {
                256 * 1024
            }
            val buffer = ByteBuffer.allocate(size)
            val info = MediaCodec.BufferInfo()
            val startUs = startMs * 1000
            val endUs = endMs * 1000
            extractor.seekTo(startUs, MediaExtractor.SEEK_TO_PREVIOUS_SYNC)
            var firstUs = -1L
            var lastUs = 0L
            while (true) {
                info.offset = 0
                info.size = extractor.readSampleData(buffer, 0)
                if (info.size < 0) break
                val t = extractor.sampleTime
                if (t > endUs) break
                if (t >= startUs || firstUs < 0 && t + 50_000 >= startUs) {
                    if (firstUs < 0) firstUs = t
                    info.presentationTimeUs = t - firstUs
                    @Suppress("WrongConstant")
                    info.flags = extractor.sampleFlags
                    muxer.writeSampleData(outTrack, buffer, info)
                    lastUs = t - firstUs
                }
                extractor.advance()
            }
            if (firstUs < 0) throw IllegalStateException("The selection is outside the song")
            return lastUs / 1000
        } finally {
            try {
                muxer?.stop()
            } catch (_: Exception) {
            }
            try {
                muxer?.release()
            } catch (_: Exception) {
            }
            extractor.release()
        }
    }

    // ==================== DELETE ====================

    @Suppress("DEPRECATION")
    private fun findAudioUri(path: String): Uri? {
        val collection = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
        contentResolver.query(
            collection,
            arrayOf(MediaStore.Audio.Media._ID),
            "${MediaStore.Audio.Media.DATA}=?",
            arrayOf(path),
            null,
        )?.use { cursor ->
            if (cursor.moveToFirst()) {
                return ContentUris.withAppendedId(collection, cursor.getLong(0))
            }
        }
        return null
    }

    @Suppress("DEPRECATION")
    private fun deleteAudioFile(path: String, result: MethodChannel.Result) {
        if (pendingDelete != null) {
            result.error("busy", "Another delete is waiting for confirmation", null)
            return
        }
        val file = File(path)
        val uri = try {
            findAudioUri(path)
        } catch (_: Exception) {
            null
        }

        if (uri == null) {
            // Not indexed by MediaStore: a plain delete is the only option.
            result.success(file.delete() || !file.exists())
            return
        }

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                val request = MediaStore.createDeleteRequest(contentResolver, listOf(uri))
                pendingDelete = PendingDelete(uri, result, deleteAfterConsent = false)
                startIntentSenderForResult(
                    request.intentSender, DELETE_REQUEST_CODE, null, 0, 0, 0,
                )
            } else {
                val rows = contentResolver.delete(uri, null, null)
                if (rows == 0 && file.exists()) file.delete()
                result.success(rows > 0 || !file.exists())
            }
        } catch (e: SecurityException) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q &&
                e is RecoverableSecurityException
            ) {
                pendingDelete = PendingDelete(uri, result, deleteAfterConsent = true)
                startIntentSenderForResult(
                    e.userAction.actionIntent.intentSender,
                    DELETE_REQUEST_CODE, null, 0, 0, 0,
                )
            } else {
                result.error("permission_denied", e.message, null)
            }
        } catch (e: Exception) {
            pendingDelete = null
            result.error("delete_failed", e.message, null)
        }
    }

    @Deprecated("Deprecated in Android API, still required for IntentSender results")
    @Suppress("DEPRECATION")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != DELETE_REQUEST_CODE) return
        val pending = pendingDelete ?: return
        pendingDelete = null

        if (resultCode != Activity.RESULT_OK) {
            pending.result.success(false) // user cancelled
            return
        }
        if (pending.deleteAfterConsent) {
            try {
                contentResolver.delete(pending.uri, null, null)
            } catch (e: Exception) {
                pending.result.error("delete_failed", e.message, null)
                return
            }
        }
        pending.result.success(true)
    }
}
