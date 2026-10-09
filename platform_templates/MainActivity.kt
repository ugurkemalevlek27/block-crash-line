package com.uke.block_crash

import android.os.SystemClock
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "block_crash/clock")
            .setMethodCallHandler { call, result ->
                if (call.method == "now") result.success(SystemClock.elapsedRealtime())
                else result.notImplemented()
            }
    }
}
