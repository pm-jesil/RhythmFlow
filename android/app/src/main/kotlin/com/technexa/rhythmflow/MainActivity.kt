package com.technexa.rhythmflow

import io.flutter.embedding.engine.FlutterEngine
import com.ryanheise.audioservice.AudioServiceActivity

class MainActivity : AudioServiceActivity() {

    private val rhythmFlowEffectPlugin = RhythmFlowEffectPlugin()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        rhythmFlowEffectPlugin.attachToMessenger(flutterEngine.dartExecutor.binaryMessenger)
    }
}
