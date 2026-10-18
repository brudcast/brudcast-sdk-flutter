package com.brudcast.flutter

import com.brudcast.sdk.BrudcastLogger
import com.brudcast.sdk.BrudcastModule
import java.util.concurrent.ConcurrentHashMap

/**
 * The native modules the installed Brudcast plugins provide. `brudcast_in_app` and `brudcast_push`
 * register theirs when they attach to an engine, which Flutter does before Dart's `main` runs, so
 * the registry is complete by the time Dart calls `initialize`.
 */
public object BrudcastModuleRegistry {
    private val modules = ConcurrentHashMap<String, BrudcastModule>()

    /**
     * Registers a module under the name Dart uses for it.
     *
     * @param module The module; its [BrudcastModule.name] is the key.
     */
    @JvmStatic
    public fun register(module: BrudcastModule) {
        modules[module.name] = module
    }

    /**
     * Finds the modules Dart listed, logging each one whose plugin is not installed.
     *
     * @param names The module names, such as `in_app` and `push`.
     * @return The modules found, in the order given.
     */
    internal fun resolve(names: List<String>): List<BrudcastModule> = names.distinct().mapNotNull { name ->
        modules[name] ?: run {
            BrudcastLogger.error("The $name module was listed, but its Flutter package is not installed; add ${packageFor(name)} to pubspec.yaml")
            null
        }
    }

    private fun packageFor(name: String): String = when (name) {
        "in_app" -> "brudcast_in_app"
        "push" -> "brudcast_push"
        else -> "the package for $name"
    }
}
