# SDK verify and repair

The local transport verifies all declared component digests and paths. Restore refuses an occupied prefix. If the compiler mode or bytes change, use the current lifecycle verify/repair commands with a known local candidate; repair replaces only owned components and preserves foreign files.

From the restored candidate directory, run python3 -B -S -m compiler.sdk.sdk_lifecycle verify ../sdk and then python3 -B -S -m compiler.sdk.sdk_lifecycle repair . ../sdk. Verify again before compiling. This documentation does not construct the future release SDK, publish a release, or claim another target. Linux x86_64 and the local Python/NASM/ld stage0 dependency remain explicit.
