package net.rpcsx.performance

import android.content.Context
import android.system.Os
import android.util.Log
import net.rpcsx.utils.GeneralSettings
import java.io.File
import java.io.IOException

object CacheStorageManager {
    private const val TAG = "CacheStorageManager"
    private const val PREF_CACHE_ROOT = "cache_storage_root"
    private const val COPY_BUFFER_SIZE = 256 * 1024

    data class Location(
        val id: String,
        val label: String,
        val rootPath: String,
        val cachePath: String,
        val freeBytes: Long,
        val removable: Boolean
    )

    data class Status(
        val locations: List<Location>,
        val activeLocation: Location,
        val coreCachePath: String,
        val effectiveCachePath: String,
        val bytes: Long,
        val redirected: Boolean,
        val warning: String?
    )

    data class SwitchResult(
        val success: Boolean,
        val message: String,
        val status: Status
    )

    fun ensureSelectedLocation(context: Context): SwitchResult {
        val locations = availableLocations(context)
        val primary = locations.first()
        val selectedRoot = (GeneralSettings[PREF_CACHE_ROOT] as? String)
            ?.let { path -> locations.firstOrNull { it.rootPath == path } }
            ?: primary
        return applyLocation(
            context = context,
            selectedRootPath = selectedRoot.rootPath,
            migrateExisting = false,
            calculateBytes = false
        )
    }

    fun setLocation(context: Context, location: Location): SwitchResult =
        applyLocation(
            context = context,
            selectedRootPath = location.rootPath,
            migrateExisting = true,
            calculateBytes = true
        )

    fun status(context: Context): Status = status(context, calculateBytes = true)

    private fun status(context: Context, calculateBytes: Boolean): Status {
        val locations = availableLocations(context)
        val primary = locations.first()
        val selectedRoot = (GeneralSettings[PREF_CACHE_ROOT] as? String)
            ?.let { path -> locations.firstOrNull { it.rootPath == path } }
            ?: primary

        val coreCache = coreCacheDir(context)
        val linkTarget = readSymlink(coreCache)
        val effectiveCache = linkTarget?.let { File(it) } ?: coreCache
        val active = if (linkTarget != null) {
            locations.firstOrNull { location ->
                normalizePath(location.cachePath) == normalizePath(linkTarget)
            }
        } else {
            locations.firstOrNull { location ->
                normalizePath(location.cachePath) == normalizePath(coreCache.absolutePath)
            }
        } ?: selectedRoot

        val warning = when {
            selectedRoot.rootPath != active.rootPath ->
                "Selected compiled-cache storage was not active; using ${active.label}."
            active.removable ->
                "SD-card compiled cache can save internal space, but it may make PPU/SPU/shader cache reads slower."
            else -> null
        }

        return Status(
            locations = locations,
            activeLocation = active,
            coreCachePath = coreCache.absolutePath,
            effectiveCachePath = effectiveCache.absolutePath,
            bytes = if (calculateBytes) directorySize(effectiveCache) else 0L,
            redirected = linkTarget != null,
            warning = warning
        )
    }

    fun formatBytes(bytes: Long): String {
        if (bytes <= 0L) {
            return "0 MB"
        }

        val mib = bytes / (1024.0 * 1024.0)
        return if (mib < 1024.0) {
            "%.1f MB".format(mib)
        } else {
            "%.2f GB".format(mib / 1024.0)
        }
    }

    private fun applyLocation(
        context: Context,
        selectedRootPath: String,
        migrateExisting: Boolean,
        calculateBytes: Boolean
    ): SwitchResult {
        val locations = availableLocations(context)
        val primaryRoot = primaryRoot(context)
        val selectedLocation = locations.firstOrNull { it.rootPath == selectedRootPath }
            ?: locations.first()
        val selectedRoot = File(selectedLocation.rootPath)
        val coreCache = coreCacheDir(context)
        val targetCache = File(selectedLocation.cachePath)

        return try {
            selectedRoot.mkdirs()
            if (sameFile(primaryRoot, selectedRoot)) {
                restorePrimaryCache(coreCache, migrateExisting)
            } else {
                redirectCache(coreCache, targetCache, migrateExisting)
            }

            GeneralSettings[PREF_CACHE_ROOT] = selectedLocation.rootPath
            GeneralSettings.sync()

            val newStatus = status(context, calculateBytes)
            SwitchResult(
                success = true,
                message = "Cache storage set to ${newStatus.activeLocation.label}.",
                status = newStatus
            )
        } catch (error: Exception) {
            Log.w(TAG, "Could not switch cache storage", error)
            val fallback = status(context, calculateBytes)
            SwitchResult(
                success = false,
                message = error.message ?: "Could not switch cache storage.",
                status = fallback
            )
        }
    }

    private fun restorePrimaryCache(coreCache: File, migrateExisting: Boolean) {
        val linkTarget = readSymlink(coreCache) ?: run {
            coreCache.mkdirs()
            return
        }

        val oldTarget = File(linkTarget)
        val staging = File(coreCache.parentFile, "cache-restore-${System.currentTimeMillis()}")
        if (migrateExisting && oldTarget.exists()) {
            staging.mkdirs()
            moveDirectoryContents(oldTarget, staging)
        }

        if (!coreCache.delete()) {
            throw IOException("Could not remove cache redirect.")
        }

        if (staging.exists()) {
            if (!staging.renameTo(coreCache)) {
                coreCache.mkdirs()
                moveDirectoryContents(staging, coreCache)
                staging.deleteRecursively()
            }
        } else {
            coreCache.mkdirs()
        }
    }

    private fun redirectCache(coreCache: File, targetCache: File, migrateExisting: Boolean) {
        targetCache.mkdirs()

        val existingTarget = readSymlink(coreCache)
        if (existingTarget != null) {
            if (sameFile(File(existingTarget), targetCache)) {
                return
            }

            if (migrateExisting) {
                moveDirectoryContents(File(existingTarget), targetCache)
            }

            if (!coreCache.delete()) {
                throw IOException("Could not remove old cache redirect.")
            }
        } else if (coreCache.exists()) {
            if (migrateExisting) {
                moveDirectoryContents(coreCache, targetCache)
            } else if (coreCache.listFiles().orEmpty().isNotEmpty()) {
                throw IOException("Existing cache folder needs migration from Settings before redirecting.")
            }

            if (!coreCache.deleteRecursively()) {
                throw IOException("Could not replace existing cache folder.")
            }
        }

        Os.symlink(targetCache.absolutePath, coreCache.absolutePath)
    }

    private fun availableLocations(context: Context): List<Location> {
        val roots = context.getExternalFilesDirs(null)
            .filterNotNull()
            .distinctBy { runCatching { it.canonicalPath }.getOrDefault(it.absolutePath) }
            .filter { it.exists() || it.mkdirs() }

        val fallback = primaryRoot(context).also { it.mkdirs() }
        val usableRoots = if (roots.isEmpty()) listOf(fallback) else roots
        val primaryCanonical = runCatching { usableRoots.first().canonicalPath }
            .getOrDefault(usableRoots.first().absolutePath)

        return usableRoots.mapIndexed { index, root ->
            val canonical = runCatching { root.canonicalPath }.getOrDefault(root.absolutePath)
            val removable = canonical != primaryCanonical || index > 0
            val volume = root.absolutePath
                .removePrefix("/storage/")
                .substringBefore('/')
                .takeIf { it.isNotBlank() && it != "emulated" }
            val label = if (removable) {
                "SD card compiled cache${volume?.let { " ($it)" } ?: ""}"
            } else {
                "Internal fast compiled cache"
            }

            Location(
                id = if (removable) "external:$canonical" else "primary",
                label = label,
                rootPath = canonical,
                cachePath = File(root, "cache/cache").absolutePath,
                freeBytes = root.freeSpace,
                removable = removable
            )
        }
    }

    private fun coreCacheDir(context: Context): File =
        File(primaryRoot(context), "cache/cache")

    private fun primaryRoot(context: Context): File =
        context.getExternalFilesDir(null) ?: context.filesDir

    private fun readSymlink(file: File): String? =
        runCatching { Os.readlink(file.absolutePath) }.getOrNull()

    private fun sameFile(left: File, right: File): Boolean =
        runCatching { left.canonicalPath == right.canonicalPath }
            .getOrDefault(left.absolutePath == right.absolutePath)

    private fun normalizePath(path: String): String =
        path.replace('\\', '/').trimEnd('/')

    private fun directorySize(directory: File): Long {
        if (!directory.exists()) {
            return 0L
        }

        var total = 0L
        runCatching {
            directory.walkTopDown().forEach { file ->
                if (file.isFile) {
                    total += file.length()
                }
            }
        }
        return total
    }

    private fun moveDirectoryContents(source: File, target: File) {
        if (!source.exists()) {
            return
        }
        if (!source.isDirectory) {
            throw IOException("Cache source is not a directory: ${source.absolutePath}")
        }

        target.mkdirs()
        source.listFiles().orEmpty().forEach { child ->
            val destination = File(target, child.name)
            if (child.isDirectory) {
                moveDirectoryContents(child, destination)
                child.delete()
            } else {
                moveFile(child, destination)
            }
        }
    }

    private fun moveFile(source: File, target: File) {
        target.parentFile?.mkdirs()
        if (target.exists() && !target.delete()) {
            throw IOException("Could not replace cache file: ${target.absolutePath}")
        }

        if (source.renameTo(target)) {
            return
        }

        source.inputStream().use { input ->
            target.outputStream().use { output ->
                input.copyTo(output, COPY_BUFFER_SIZE)
            }
        }

        if (source.length() != target.length()) {
            target.delete()
            throw IOException("Could not verify copied cache file: ${source.absolutePath}")
        }

        if (!source.delete()) {
            throw IOException("Could not remove old cache file: ${source.absolutePath}")
        }
    }
}
