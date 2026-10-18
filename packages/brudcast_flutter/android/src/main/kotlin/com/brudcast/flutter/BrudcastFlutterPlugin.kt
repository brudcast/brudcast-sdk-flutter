package com.brudcast.flutter

import android.app.Activity
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import com.brudcast.sdk.Brudcast
import com.brudcast.sdk.BrudcastAction
import com.brudcast.sdk.BrudcastActionResult
import com.brudcast.sdk.BrudcastAppearance
import com.brudcast.sdk.BrudcastEnvironment
import com.brudcast.sdk.BrudcastLogLevel
import com.brudcast.sdk.BrudcastLogger
import com.brudcast.sdk.BrudcastOptions
import com.brudcast.sdk.BrudcastSdk
import com.brudcast.sdk.BrudcastTraits
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding

/**
 * The core Brudcast plugin: forwards Dart calls to the native SDK and Dart's action handler to it.
 */
public class BrudcastFlutterPlugin : FlutterPlugin, ActivityAware, BrudcastHostApi, ActionRouter.Target {
    private var binding: FlutterPlugin.FlutterPluginBinding? = null
    private var flutterApi: BrudcastFlutterApi? = null
    private var activity: Activity? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        this.binding = binding
        flutterApi = BrudcastFlutterApi(binding.binaryMessenger)
        BrudcastHostApi.setUp(binding.binaryMessenger, this)
        router.engineAttached()
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        router.clearTarget(this)
        BrudcastHostApi.setUp(binding.binaryMessenger, null)
        flutterApi = null
        this.binding = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        if (Brudcast.isInitialized) Brudcast.attachActivity(binding.activity)
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

    override fun initialize(publishableKey: String, options: PlatformOptions) {
        val application = binding?.applicationContext ?: return
        BrudcastSdk.setWrapper("Flutter", options.wrapperVersion)
        Brudcast.initialize(application, publishableKey, options.toNative())
        activity?.let { Brudcast.attachActivity(it) }
    }

    override fun identify(externalId: String, userHash: String?, traits: PlatformTraits?) {
        Brudcast.identify(externalId, userHash, traits?.toNative())
    }

    override fun reset() {
        Brudcast.reset()
    }

    override fun track(name: String, properties: Map<String, Any?>) {
        Brudcast.track(name, properties)
    }

    override fun screen(name: String, properties: Map<String, Any?>) {
        Brudcast.screen(name, properties)
    }

    override fun setOptedOut(optedOut: Boolean) {
        if (optedOut) Brudcast.optOut() else Brudcast.optIn()
    }

    override fun setTrackingEnabled(enabled: Boolean) {
        if (enabled) Brudcast.enableTracking() else Brudcast.disableTracking()
    }

    override fun flush() {
        Brudcast.flush()
    }

    override fun setActionHandlerEnabled(enabled: Boolean) {
        if (enabled) router.setTarget(this) else router.clearTarget(this)
    }

    override fun deviceId(): String? = Brudcast.deviceId

    override fun handle(action: BrudcastAction, decide: (BrudcastActionResult) -> Unit) {
        val api = flutterApi ?: return decide(BrudcastActionResult.USE_DEFAULT)
        api.handleAction(action.toPlatform()) { result ->
            decide(if (result.getOrNull() == PlatformActionResult.HANDLED) BrudcastActionResult.HANDLED else BrudcastActionResult.USE_DEFAULT)
        }
    }

    private companion object {
        private val main = Handler(Looper.getMainLooper())

        val router = ActionRouter(
            clock = SystemClock::uptimeMillis,
            schedule = { delay, task -> main.postDelayed(task, delay) },
            install = Brudcast::setAsyncActionHandler,
            performDefault = Brudcast::performDefaultAction,
        )
    }
}

private fun PlatformOptions.toNative(): BrudcastOptions = BrudcastOptions(
    environment = environment.toNative(),
    logLevel = when (logLevel) {
        PlatformLogLevel.VERBOSE -> BrudcastLogLevel.VERBOSE
        PlatformLogLevel.DEBUG -> BrudcastLogLevel.DEBUG
        PlatformLogLevel.INFO -> BrudcastLogLevel.INFO
        PlatformLogLevel.WARNING -> BrudcastLogLevel.WARNING
        PlatformLogLevel.ERROR -> BrudcastLogLevel.ERROR
        PlatformLogLevel.NONE -> BrudcastLogLevel.NONE
    },
    appearance = when (appearance) {
        PlatformAppearance.SYSTEM -> BrudcastAppearance.SYSTEM
        PlatformAppearance.LIGHT -> BrudcastAppearance.LIGHT
        PlatformAppearance.DARK -> BrudcastAppearance.DARK
    },
    modules = BrudcastModuleRegistry.resolve(modules),
    accentColor = accentColor?.toInt(),
)

private fun PlatformEnvironment.toNative(): BrudcastEnvironment = when (kind) {
    PlatformEnvironmentKind.PRODUCTION -> BrudcastEnvironment.Production
    PlatformEnvironmentKind.STAGING -> BrudcastEnvironment.Staging
    PlatformEnvironmentKind.UAT -> BrudcastEnvironment.Uat
    PlatformEnvironmentKind.DEVELOPMENT -> BrudcastEnvironment.Development
    PlatformEnvironmentKind.LOCAL -> BrudcastEnvironment.Local(androidHost ?: "10.0.2.2", port?.toInt() ?: 8191)
    PlatformEnvironmentKind.CUSTOM -> baseUrl?.let { BrudcastEnvironment.Custom(it) } ?: run {
        BrudcastLogger.error("A custom environment needs a base URL; using production")
        BrudcastEnvironment.Production
    }
}

private fun PlatformTraits.toNative(): BrudcastTraits = BrudcastTraits(email, phone, firstName, lastName, language, timezone)

private fun BrudcastAction.toPlatform(): PlatformAction {
    val (source, messageId, buttonId) = when (val origin = source) {
        is BrudcastAction.Source.InApp -> Triple(PlatformActionSource.IN_APP, origin.messageId, origin.buttonId)
        is BrudcastAction.Source.Push -> Triple(PlatformActionSource.PUSH, origin.messageId, null)
    }
    return PlatformAction(
        kind = when (kind) {
            BrudcastAction.Kind.DEEPLINK -> PlatformActionKind.DEEPLINK
            BrudcastAction.Kind.URL -> PlatformActionKind.URL
            BrudcastAction.Kind.CUSTOM_EVENT -> PlatformActionKind.CUSTOM_EVENT
        },
        value = value,
        opensInApp = opensInApp,
        source = source,
        messageId = messageId,
        buttonId = buttonId,
        verified = verified,
    )
}
