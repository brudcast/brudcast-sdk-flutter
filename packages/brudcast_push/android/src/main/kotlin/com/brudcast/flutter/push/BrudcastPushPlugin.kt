package com.brudcast.flutter.push

import android.app.Activity
import android.content.Intent
import com.brudcast.flutter.BrudcastModuleRegistry
import com.brudcast.sdk.push.BrudcastAsyncNotificationHandler
import com.brudcast.sdk.push.BrudcastNotificationDecision
import com.brudcast.sdk.push.BrudcastPushNotification
import com.brudcast.sdk.push.BrudcastPushPermission
import com.brudcast.sdk.push.PushModule
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.PluginRegistry
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

/**
 * The Brudcast push plugin: registers the native push module, forwards Dart calls to it, routes the
 * notification handler to Dart, and passes notification taps on a running activity to the SDK.
 */
public class BrudcastPushPlugin : FlutterPlugin, ActivityAware, PushHostApi, PluginRegistry.NewIntentListener {
    private var binding: FlutterPlugin.FlutterPluginBinding? = null
    private var flutterApi: PushFlutterApi? = null
    private var activityBinding: ActivityPluginBinding? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        this.binding = binding
        flutterApi = PushFlutterApi(binding.binaryMessenger)
        BrudcastModuleRegistry.register(PushModule)
        PushHostApi.setUp(binding.binaryMessenger, this)
        PermissionChangesStreamHandler.register(binding.binaryMessenger, PermissionStream())
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        clearNotificationHandler()
        PushHostApi.setUp(binding.binaryMessenger, null)
        flutterApi = null
        this.binding = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding
        binding.addOnNewIntentListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        detachActivity()
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivity() {
        detachActivity()
    }

    override fun onNewIntent(intent: Intent): Boolean {
        PushModule.handleIntent(intent)
        return false
    }

    override fun setToken(token: String) {
        PushModule.setToken(token)
    }

    override fun requestPermission(provisional: Boolean, callback: (Result<PlatformPushPermission>) -> Unit) {
        val activity: Activity = activityBinding?.activity ?: return callback(Result.success(PushModule.permissionStatus.value.toPlatform()))
        PushModule.requestPermission(activity) { granted ->
            callback(Result.success(if (granted) PlatformPushPermission.AUTHORIZED else PlatformPushPermission.DENIED))
        }
    }

    override fun setNotificationHandlerEnabled(enabled: Boolean) {
        if (!enabled) return clearNotificationHandler()
        handlerOwner = this
        PushModule.setAsyncNotificationHandler(BrudcastAsyncNotificationHandler { notification, decide ->
            val api = handlerOwner?.flutterApi ?: return@BrudcastAsyncNotificationHandler decide(BrudcastNotificationDecision.SHOW)
            api.handleNotification(notification.toPlatform()) { result ->
                decide(if (result.getOrNull() == PlatformNotificationDecision.SUPPRESS) BrudcastNotificationDecision.SUPPRESS else BrudcastNotificationDecision.SHOW)
            }
        })
    }

    override fun handleForegroundMessage(data: Map<String, String>, title: String?, body: String?, imageUrl: String?): Boolean {
        val context = binding?.applicationContext ?: return false
        val notification = BrudcastPushNotification.from(data, title, body, imageUrl) ?: return false
        return PushModule.onMessageReceived(context, notification)
    }

    private fun detachActivity() {
        activityBinding?.removeOnNewIntentListener(this)
        activityBinding = null
    }

    private fun clearNotificationHandler() {
        if (handlerOwner !== this) return
        handlerOwner = null
        PushModule.setAsyncNotificationHandler(null)
    }

    private companion object {
        /** The engine whose Dart set the notification handler, so a background engine cannot take it. */
        @Volatile
        var handlerOwner: BrudcastPushPlugin? = null
    }
}

/** Streams the permission status to Dart, starting with the current status. */
private class PermissionStream : PermissionChangesStreamHandler() {
    private var scope: CoroutineScope? = null

    override fun onListen(p0: Any?, sink: PigeonEventSink<PlatformPushPermission>) {
        val started = CoroutineScope(SupervisorJob() + Dispatchers.Main)
        scope = started
        started.launch { PushModule.permissionStatus.collect { sink.success(it.toPlatform()) } }
    }

    override fun onCancel(p0: Any?) {
        scope?.cancel()
        scope = null
    }
}

private fun BrudcastPushPermission.toPlatform(): PlatformPushPermission = when (this) {
    BrudcastPushPermission.NOT_DETERMINED -> PlatformPushPermission.NOT_DETERMINED
    BrudcastPushPermission.DENIED -> PlatformPushPermission.DENIED
    BrudcastPushPermission.AUTHORIZED -> PlatformPushPermission.AUTHORIZED
}

private fun BrudcastPushNotification.toPlatform(): PlatformPushNotification = PlatformPushNotification(
    messageId = messageId,
    campaignId = campaignId,
    applicationId = applicationId,
    title = title,
    body = body,
    imageUrl = imageUrl,
    clickUrl = clickUrl,
    data = data,
)
