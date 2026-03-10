package com.technexa.rhythmflow

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import android.media.audiofx.PresetReverb
import android.media.audiofx.EnvironmentalReverb
import android.media.audiofx.Virtualizer
import android.media.audiofx.BassBoost

/**
 * Native Android plugin for audio effects not exposed by just_audio:
 * Reverb, Echo (EnvironmentalReverb), Virtualizer, BassBoost.
 * Effects attach to the ExoPlayer audio session ID provided by just_audio.
 *
 * Also handles setChannelVolumes (L/R knobs) — returns (globalVolume, balance)
 * for Dart to apply via AudioPlayer.setVolume() since ExoPlayer does not expose
 * per-channel volume through the AudioEffect API.
 */
class RhythmFlowEffectPlugin : FlutterPlugin, MethodCallHandler {

    private var channel: MethodChannel? = null

    private var presetReverb: PresetReverb? = null
    private var environmentalReverb: EnvironmentalReverb? = null
    private var virtualizer: Virtualizer? = null
    private var bassBoost: BassBoost? = null

    private var reverbMode: String = "preset" // "preset" | "environmental"

    // Stored L/R volumes (0.0–1.0 each) — persisted across re-inits
    private var channelVolumeLeft: Float = 1.0f
    private var channelVolumeRight: Float = 1.0f

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        attachToMessenger(binding.binaryMessenger)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
        releaseEffects()
    }

    /** Called from MainActivity to manually attach when plugin registration is manual. */
    fun attachToMessenger(messenger: BinaryMessenger) {
        channel?.setMethodCallHandler(null)
        channel = MethodChannel(messenger, "com.technexa.rhythmflow/audio_effects")
        channel?.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "initEffects" -> {
                val sessionId = (call.argument<Number>("sessionId"))?.toInt() ?: 0
                if (sessionId == 0) {
                    result.error("INVALID_SESSION", "sessionId is required and must be non-zero", null)
                    return
                }
                initEffects(sessionId, result)
            }
            "releaseEffects" -> {
                releaseEffects()
                result.success(null)
            }
            "setReverbPreset" -> {
                val preset = (call.argument<Number>("preset"))?.toInt() ?: PresetReverb.PRESET_NONE.toInt()
                setReverbPreset(preset, result)
            }
            "setReverbEnabled" -> {
                val enabled = call.argument<Boolean>("enabled") ?: false
                setReverbEnabled(enabled, result)
            }
            "setEnvironmentalReverbEnabled" -> {
                val enabled = call.argument<Boolean>("enabled") ?: false
                setEnvironmentalReverbEnabled(enabled, result)
            }
            "setEnvironmentalReverb" -> {
                val roomLevel        = (call.argument<Int>("roomLevel")        ?: -6000).coerceIn(-6000, 0)
                val reverbLevel      = (call.argument<Int>("reverbLevel")      ?: -6000).coerceIn(-6000, 0)
                val decayTime        = (call.argument<Int>("decayTime")        ?: 200).coerceIn(100, 20000)
                val diffusion        = (call.argument<Int>("diffusion")        ?: 800).coerceIn(0, 1000)
                val density          = (call.argument<Int>("density")          ?: 800).coerceIn(0, 1000)
                val reflectionsLevel = (call.argument<Int>("reflectionsLevel") ?: -2000).coerceIn(-6000, 0)
                val reflectionsDelay = (call.argument<Int>("reflectionsDelay") ?: 20).coerceIn(0, 65)
                val reverbDelay      = (call.argument<Int>("reverbDelay")      ?: 40).coerceIn(0, 65)
                setEnvironmentalReverb(
                    roomLevel, reverbLevel, decayTime, diffusion, density,
                    reflectionsLevel, reflectionsDelay, reverbDelay, result
                )
            }
            "setVirtualizerStrength" -> {
                val strength = (call.argument<Int>("strength") ?: 0).coerceIn(0, 1000)
                setVirtualizerStrength(strength, result)
            }
            "setVirtualizerEnabled" -> {
                val enabled = call.argument<Boolean>("enabled") ?: false
                setVirtualizerEnabled(enabled, result)
            }
            "setBassBoostStrength" -> {
                val strength = (call.argument<Int>("strength") ?: 0).coerceIn(0, 1000)
                setBassBoostStrength(strength, result)
            }
            "setBassBoostEnabled" -> {
                val enabled = call.argument<Boolean>("enabled") ?: false
                setBassBoostEnabled(enabled, result)
            }
            // ── Stereo Channel Volumes ─────────────────────────────────────────────
            // ExoPlayer (just_audio) has no hardware per-channel volume API.
            // We compute the derived (globalVolume, leftGain, rightGain) values
            // and return them so Dart can apply globalVolume via AudioPlayer.setVolume()
            // and scale left/right visually in the knob UI.
            // Left-attenuated: lower left knob → right channel louder → panned right
            // Right-attenuated: lower right knob → left channel louder → panned left
            "setChannelVolumes" -> {
                val left  = (call.argument<Number>("left"))?.toFloat()?.coerceIn(0f, 1f)  ?: 1f
                val right = (call.argument<Number>("right"))?.toFloat()?.coerceIn(0f, 1f) ?: 1f
                channelVolumeLeft  = left
                channelVolumeRight = right

                // Global volume = max of L and R so at least one channel is always at full
                val globalVolume = maxOf(left, right).toDouble()

                // Balance is the gain ratio for the quieter channel:
                //   leftGain  = 1.0 when left ≥ right, else left/right
                //   rightGain = 1.0 when right ≥ left, else right/left
                val leftGain  = if (left  >= right) 1.0 else (left  / maxOf(right, 0.001f)).toDouble()
                val rightGain = if (right >= left)  1.0 else (right / maxOf(left,  0.001f)).toDouble()

                result.success(mapOf(
                    "globalVolume" to globalVolume,
                    "leftGain"     to leftGain,
                    "rightGain"    to rightGain
                ))
            }
            else -> result.notImplemented()
        }
    }

    private fun initEffects(sessionId: Int, result: Result) {
        try {
            releaseEffects()

            val reverbAvailable = try {
                presetReverb = PresetReverb(0, sessionId)
                presetReverb?.enabled = false
                true
            } catch (e: Exception) { false }

            val envReverbAvailable = try {
                environmentalReverb = EnvironmentalReverb(0, sessionId)
                environmentalReverb?.enabled = false
                true
            } catch (e: Exception) { false }

            val virtualizerAvailable = try {
                virtualizer = Virtualizer(0, sessionId)
                virtualizer?.enabled = false
                true
            } catch (e: Exception) { false }

            val bassBoostAvailable = try {
                bassBoost = BassBoost(0, sessionId)
                bassBoost?.enabled = false
                true
            } catch (e: Exception) { false }

            result.success(mapOf(
                "reverbAvailable"             to reverbAvailable,
                "environmentalReverbAvailable" to envReverbAvailable,
                "virtualizerAvailable"         to virtualizerAvailable,
                "bassBoostAvailable"           to bassBoostAvailable
            ))
        } catch (e: Exception) {
            result.error("INIT_FAILED", e.message, null)
        }
    }

    private fun releaseEffects() {
        try {
            presetReverb?.release()
            environmentalReverb?.release()
            virtualizer?.release()
            bassBoost?.release()
        } catch (_: Exception) { }
        presetReverb        = null
        environmentalReverb = null
        virtualizer         = null
        bassBoost           = null
    }

    private fun setReverbPreset(preset: Int, result: Result) {
        try {
            presetReverb?.let {
                if (preset == PresetReverb.PRESET_NONE.toInt()) {
                    it.enabled = false
                } else {
                    val settings = PresetReverb.Settings()
                    settings.preset = preset.toShort()
                    it.properties  = settings
                    it.enabled     = true
                }
                result.success(null)
            } ?: result.error("EFFECT_NOT_INIT", "PresetReverb not initialized", null)
        } catch (e: Exception) {
            result.error("REVERB_FAILED", e.message, null)
        }
    }

    private fun setReverbEnabled(enabled: Boolean, result: Result) {
        try {
            presetReverb?.enabled = enabled
            result.success(null)
        } catch (e: Exception) {
            result.error("REVERB_FAILED", e.message, null)
        }
    }

    private fun setEnvironmentalReverbEnabled(enabled: Boolean, result: Result) {
        try {
            environmentalReverb?.enabled = enabled
            result.success(null)
        } catch (e: Exception) {
            result.error("ENV_REVERB_FAILED", e.message, null)
        }
    }

    private fun setEnvironmentalReverb(
        roomLevel: Int, reverbLevel: Int, decayTime: Int,
        diffusion: Int, density: Int, reflectionsLevel: Int,
        reflectionsDelay: Int, reverbDelay: Int,
        result: Result
    ) {
        try {
            environmentalReverb?.let {
                val settings = EnvironmentalReverb.Settings()
                settings.roomLevel        = roomLevel.toShort()
                settings.reverbLevel      = reverbLevel.toShort()
                settings.decayTime        = decayTime
                settings.decayHFRatio     = 500
                settings.diffusion        = diffusion.toShort()
                settings.density          = density.toShort()
                settings.reflectionsLevel = reflectionsLevel.toShort()
                settings.reflectionsDelay = reflectionsDelay
                settings.reverbDelay      = reverbDelay
                settings.roomHFLevel      = (-500).toShort()
                it.properties  = settings
                it.enabled     = true
                presetReverb?.enabled = false
                reverbMode = "environmental"
                result.success(null)
            } ?: result.error("EFFECT_NOT_INIT", "EnvironmentalReverb not initialized", null)
        } catch (e: Exception) {
            result.error("ENV_REVERB_FAILED", e.message, null)
        }
    }

    private fun setVirtualizerStrength(strength: Int, result: Result) {
        try {
            virtualizer?.let {
                it.setStrength(strength.toShort())
                it.enabled = strength > 0
                result.success(null)
            } ?: result.error("EFFECT_NOT_INIT", "Virtualizer not initialized", null)
        } catch (e: Exception) {
            result.error("VIRTUALIZER_FAILED", e.message, null)
        }
    }

    private fun setVirtualizerEnabled(enabled: Boolean, result: Result) {
        try {
            virtualizer?.enabled = enabled
            result.success(null)
        } catch (e: Exception) {
            result.error("VIRTUALIZER_FAILED", e.message, null)
        }
    }

    private fun setBassBoostStrength(strength: Int, result: Result) {
        try {
            bassBoost?.let {
                it.setStrength(strength.toShort())
                it.enabled = strength > 0
                result.success(null)
            } ?: result.error("EFFECT_NOT_INIT", "BassBoost not initialized", null)
        } catch (e: Exception) {
            result.error("BASSBOOST_FAILED", e.message, null)
        }
    }

    private fun setBassBoostEnabled(enabled: Boolean, result: Result) {
        try {
            bassBoost?.enabled = enabled
            result.success(null)
        } catch (e: Exception) {
            result.error("BASSBOOST_FAILED", e.message, null)
        }
    }
}
