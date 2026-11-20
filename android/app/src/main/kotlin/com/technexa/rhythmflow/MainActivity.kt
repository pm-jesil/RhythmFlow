package com.technexa.rhythmflow

import android.app.Activity
import android.app.RecoverableSecurityException
import android.content.ContentUris
import android.content.ContentValues
import android.content.Intent
import android.media.MediaScannerConnection
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
