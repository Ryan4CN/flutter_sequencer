package com.michaeljperri.flutter_sequencer

import android.content.Context
import android.content.res.AssetManager;
import androidx.annotation.NonNull;
import androidx.core.content.ContextCompat

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.net.URLDecoder

const val flutterAssetRoot = "flutter_assets"

/** FlutterSequencerPlugin */
public class FlutterSequencerPlugin: FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.getFlutterEngine().getDartExecutor(), "flutter_sequencer")
    channel.setMethodCallHandler(this);
    context = flutterPluginBinding.applicationContext
  }

  companion object {
    private lateinit var context : Context

    init {
      System.loadLibrary("flutter_sequencer")
    }
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    if (call.method == "getPlatformVersion") {
      result.success("Android ${android.os.Build.VERSION.RELEASE}")
    } else if (call.method == "setupAssetManager") {
      setupAssetManager(context.assets)
      result.success(null)
    } else if (call.method == "normalizeAssetDir") {
      val assetDir = call.argument<String>("assetDir")!!
      val filesDir = context.filesDir
      val isSuccess = copyAssetDirOrFile(assetDir, filesDir)

      if (isSuccess) {
        val copiedDir = filesDir.resolve(assetDir).absolutePath
        result.success(copiedDir)
      } else {
        result.success(null)
      }
    } else if (call.method == "listAudioUnits") {
      result.success(emptyList<String>())
    } else {
      result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  private fun copyAssetFile(assetFilePath: String, outputDir: File): Boolean {
    val inputStream = context.assets.open("$flutterAssetRoot/$assetFilePath")
    val decodedAssetFilePath = URLDecoder.decode(assetFilePath, "UTF-8")
    val outputFile = outputDir.resolve(decodedAssetFilePath)
    var outputStream: FileOutputStream? = null

    try {
      outputFile.parentFile.mkdirs()
      outputFile.createNewFile()

      outputStream = FileOutputStream(outputFile)
      inputStream.copyTo(outputStream, 1024)
    } catch (e: SecurityException) {
      return false;
    } catch (e: java.io.IOException) {
      return false;
    } finally {
      inputStream.close()
      outputStream?.flush()
      outputStream?.close()
    }

    return true;
  }

  private fun copyAssetDirOrFile(assetPath: String, outputDir: File): Boolean {
    val paths = context.assets.list("$flutterAssetRoot/$assetPath")!!
    var isSuccess = true;

    if (paths.isEmpty()) {
      // It's a file.
      isSuccess = isSuccess && copyAssetFile(assetPath, outputDir)
    } else {
      // It's a directory.
      paths.forEach {
        isSuccess = isSuccess && copyAssetDirOrFile("$assetPath/$it", outputDir)
      }
    }

    return isSuccess
  }

  private external fun setupAssetManager(assetManager: AssetManager)
}
