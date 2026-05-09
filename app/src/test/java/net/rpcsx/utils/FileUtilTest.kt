package net.rpcsx.utils

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class FileUtilTest {
    @Test
    fun nativeInstallerSafeFileNamesAreConservative() {
        assertTrue(FileUtil.isNativeInstallerSafeFileName("game.pkg"))
        assertTrue(FileUtil.isNativeInstallerSafeFileName("LICENSE.EDAT"))
        assertFalse(FileUtil.isNativeInstallerSafeFileName("disc.iso"))
        assertFalse(FileUtil.isNativeInstallerSafeFileName("PS3_GAME"))
        assertFalse(FileUtil.isNativeInstallerSafeFileName("readme.txt"))
    }
}
