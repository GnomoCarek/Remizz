package com.remizz.remizz

import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity: AudioServiceActivity() {
    override fun provideFlutterEngine(context: android.content.Context): FlutterEngine? {
        return super.provideFlutterEngine(context)
    }
}
