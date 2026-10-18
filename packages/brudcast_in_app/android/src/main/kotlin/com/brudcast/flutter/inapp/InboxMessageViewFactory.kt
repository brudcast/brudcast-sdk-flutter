package com.brudcast.flutter.inapp

import android.content.Context
import android.view.View
import com.brudcast.sdk.inapp.InAppModule
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

/**
 * Creates the platform views behind Dart's `BrudcastInboxMessage`: an inbox entry drawn by the
 * native renderer, which reports the height its design needs back to Dart.
 *
 * @param flutterApi The channel the heights go back on.
 */
internal class InboxMessageViewFactory(private val flutterApi: InAppFlutterApi) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        val messageId = (args as? Map<*, *>)?.get("messageId") as? String
        val message = messageId?.let { BrudcastInAppPlugin.message(it) }
        val density = context.resources.displayMetrics.density
        val view = message?.let {
            InAppModule.inbox.render(context, it) { pixels ->
                flutterApi.inboxMessageHeightChanged(viewId.toLong(), (pixels / density).toDouble()) {}
            }
        } ?: View(context)
        return object : PlatformView {
            override fun getView(): View = view

            override fun dispose() {}
        }
    }

    companion object {
        const val VIEW_TYPE: String = "com.brudcast.flutter/inbox_message"
    }
}
