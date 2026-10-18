package com.brudcast.flutter.inapp

import android.app.Activity
import com.brudcast.flutter.BrudcastModuleRegistry
import com.brudcast.sdk.BrudcastApiError
import com.brudcast.sdk.inapp.BrudcastAsyncMessageHandler
import com.brudcast.sdk.inapp.BrudcastInAppMessage
import com.brudcast.sdk.inapp.BrudcastInboxPage
import com.brudcast.sdk.inapp.BrudcastMessageDecision
import com.brudcast.sdk.inapp.BrudcastUnreadCountListener
import com.brudcast.sdk.inapp.InAppFormat
import com.brudcast.sdk.inapp.InAppModule
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import java.util.concurrent.ConcurrentHashMap

/**
 * The Brudcast in-app plugin: registers the native in-app module, forwards Dart calls to it, routes
 * the message handler to Dart, and draws inbox entries as platform views.
 */
public class BrudcastInAppPlugin : FlutterPlugin, ActivityAware, InAppHostApi {
    private var binding: FlutterPlugin.FlutterPluginBinding? = null
    private var flutterApi: InAppFlutterApi? = null
    private var activity: Activity? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        this.binding = binding
        val api = InAppFlutterApi(binding.binaryMessenger)
        flutterApi = api
        BrudcastModuleRegistry.register(InAppModule)
        InAppHostApi.setUp(binding.binaryMessenger, this)
        UnreadCountChangesStreamHandler.register(binding.binaryMessenger, UnreadCountStream())
        binding.platformViewRegistry.registerViewFactory(InboxMessageViewFactory.VIEW_TYPE, InboxMessageViewFactory(api))
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        clearMessageHandler()
        InAppHostApi.setUp(binding.binaryMessenger, null)
        flutterApi = null
        this.binding = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun pauseDisplay() {
        InAppModule.pauseDisplay()
    }

    override fun resumeDisplay() {
        InAppModule.resumeDisplay()
    }

    override fun sync() {
        InAppModule.sync()
    }

    override fun setMessageHandlerEnabled(enabled: Boolean) {
        if (!enabled) return clearMessageHandler()
        handlerOwner = this
        InAppModule.setAsyncMessageHandler(BrudcastAsyncMessageHandler { message, decide ->
            remember(message)
            val api = handlerOwner?.flutterApi ?: return@BrudcastAsyncMessageHandler decide(BrudcastMessageDecision.SHOW)
            api.handleMessage(message.toPlatform()) { result -> decide(result.getOrNull()?.toNative() ?: BrudcastMessageDecision.SHOW) }
        })
    }

    override fun reportImpression(messageId: String) {
        InAppModule.reportImpression(messageId)
    }

    override fun reportClick(messageId: String, buttonId: String) {
        InAppModule.reportClick(messageId, buttonId)
    }

    override fun reportDismiss(messageId: String) {
        InAppModule.reportDismiss(messageId)
    }

    override fun presentInbox(title: String) {
        val context = activity ?: binding?.applicationContext ?: return
        InAppModule.inbox.present(context, title)
    }

    override fun listInbox(beforeMillis: Long?, limit: Long, callback: (Result<PlatformInboxPage>) -> Unit) {
        InAppModule.inbox.list(beforeMillis, limit.toInt()) { result ->
            result.fold(
                onSuccess = { page -> callback(Result.success(page.toPlatform())) },
                onFailure = { error ->
                    val code = (error as? BrudcastApiError)?.code ?: "inbox_failed"
                    callback(Result.failure(FlutterError(code, error.message, null)))
                },
            )
        }
    }

    override fun markRead(messageId: String) {
        InAppModule.inbox.markRead(messageId)
    }

    override fun delete(messageId: String) {
        InAppModule.inbox.delete(messageId)
    }

    private fun clearMessageHandler() {
        if (handlerOwner !== this) return
        handlerOwner = null
        InAppModule.setAsyncMessageHandler(null)
    }

    internal companion object {
        /** The engine whose Dart set the message handler, so a background engine cannot take it. */
        @Volatile
        private var handlerOwner: BrudcastInAppPlugin? = null

        private val seen = ConcurrentHashMap<String, BrudcastInAppMessage>()

        /**
         * Keeps a message that crossed to Dart, so a platform view can draw it by id later.
         *
         * @param message The message.
         */
        fun remember(message: BrudcastInAppMessage) {
            seen[message.id] = message
        }

        /**
         * Finds a message that crossed to Dart.
         *
         * @param id The message id.
         * @return The message, or null when Dart never saw it.
         */
        fun message(id: String): BrudcastInAppMessage? = seen[id]

        private fun BrudcastInboxPage.toPlatform(): PlatformInboxPage {
            messages.forEach(::remember)
            return PlatformInboxPage(messages.map { it.toPlatform() }, unreadCount.toLong(), hasMore)
        }
    }
}

/** Streams the inbox's unread count to Dart, starting with the current count. */
private class UnreadCountStream : UnreadCountChangesStreamHandler() {
    private var listener: BrudcastUnreadCountListener? = null

    override fun onListen(p0: Any?, sink: PigeonEventSink<Long>) {
        val added = BrudcastUnreadCountListener { count -> sink.success(count.toLong()) }
        listener = added
        InAppModule.inbox.addUnreadCountListener(added)
    }

    override fun onCancel(p0: Any?) {
        listener?.let { InAppModule.inbox.removeUnreadCountListener(it) }
        listener = null
    }
}

internal fun BrudcastInAppMessage.toPlatform(): PlatformInAppMessage = PlatformInAppMessage(
    id = id,
    campaignId = campaignId,
    format = when (format) {
        InAppFormat.MODAL -> PlatformMessageFormat.MODAL
        InAppFormat.BANNER -> PlatformMessageFormat.BANNER
        InAppFormat.FULLSCREEN -> PlatformMessageFormat.FULLSCREEN
        InAppFormat.INBOX_ONLY -> PlatformMessageFormat.INBOX_ONLY
    },
    isTest = isTest,
    title = title,
    preview = preview,
    thumbnailUrl = thumbnailUrl,
    isRead = isRead,
    createdAtMillis = createdAt,
    design = design,
)

private fun PlatformMessageDecision.toNative(): BrudcastMessageDecision = when (this) {
    PlatformMessageDecision.SHOW -> BrudcastMessageDecision.SHOW
    PlatformMessageDecision.SUPPRESS -> BrudcastMessageDecision.SUPPRESS
    PlatformMessageDecision.DEFERRED -> BrudcastMessageDecision.DEFER
    PlatformMessageDecision.CUSTOM -> BrudcastMessageDecision.CUSTOM
}
