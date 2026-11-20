package com.technexa.rhythmflow

import android.app.Activity
import android.app.RecoverableSecurityException
import android.content.ContentUris
import android.content.Intent
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
