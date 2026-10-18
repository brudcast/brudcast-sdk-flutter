package com.brudcast.flutter

import com.brudcast.sdk.BrudcastAction
import com.brudcast.sdk.BrudcastActionResult
import com.brudcast.sdk.BrudcastAsyncActionHandler

/**
 * Routes actions from in-app buttons and push taps to the Dart action handler.
 *
 * A push tap that starts the app reaches the SDK before Dart has set a handler. For a while after
 * each engine attaches, actions that arrive with no handler set are held and given to the handler
 * once Dart sets one; when the window ends they get the default behaviour. Once the window has
 * ended and no handler is set, no native handler is installed, so the default costs no channel
 * round trip. Every call happens on the main thread.
 *
 * @param clock The current time in milliseconds.
 * @param schedule Runs a task on the main thread after a delay in milliseconds.
 * @param install Installs the native action handler, or removes it with null.
 * @param performDefault Runs an action's default behaviour.
 */
internal class ActionRouter(
    private val clock: () -> Long,
    private val schedule: (Long, () -> Unit) -> Unit,
    private val install: (BrudcastAsyncActionHandler?) -> Unit,
    private val performDefault: (BrudcastAction) -> Unit,
) {
    /** Where actions go once Dart has set a handler. */
    fun interface Target {
        fun handle(action: BrudcastAction, decide: (BrudcastActionResult) -> Unit)
    }

    private var target: Target? = null
    private var holdUntil = 0L
    private var installed = false
    private val held = ArrayList<BrudcastAction>()

    private val handler = BrudcastAsyncActionHandler { action, decide ->
        val current = target
        when {
            current != null -> current.handle(action, decide)
            clock() < holdUntil -> {
                held.add(action)
                decide(BrudcastActionResult.HANDLED)
            }
            else -> decide(BrudcastActionResult.USE_DEFAULT)
        }
    }

    /** Opens the window in which actions wait for Dart, when an engine attaches. */
    fun engineAttached() {
        holdUntil = clock() + HOLD_MS
        installIfNeeded()
        schedule(HOLD_MS) { windowEnded() }
    }

    /**
     * Sends actions to a Dart handler, starting with the ones held for it.
     *
     * @param target The engine whose Dart set a handler.
     */
    fun setTarget(target: Target) {
        this.target = target
        installIfNeeded()
        val waiting = held.toList()
        held.clear()
        waiting.forEach { action ->
            target.handle(action) { result -> if (result == BrudcastActionResult.USE_DEFAULT) performDefault(action) }
        }
    }

    /**
     * Stops sending actions to a Dart handler, when Dart clears it or its engine detaches.
     *
     * @param target The engine.
     */
    fun clearTarget(target: Target) {
        if (this.target !== target) return
        this.target = null
        if (clock() >= holdUntil) uninstall()
    }

    private fun windowEnded() {
        if (clock() < holdUntil) return
        val expired = held.toList()
        held.clear()
        expired.forEach(performDefault)
        if (target == null) uninstall()
    }

    private fun installIfNeeded() {
        if (installed) return
        installed = true
        install(handler)
    }

    private fun uninstall() {
        if (!installed) return
        installed = false
        install(null)
    }

    companion object {
        /** How long after an engine attaches actions wait for a Dart handler. */
        const val HOLD_MS = 5_000L
    }
}
