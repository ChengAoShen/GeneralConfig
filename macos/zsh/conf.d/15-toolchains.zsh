# Homebrew's openjdk@17 is keg-only and not on PATH, so JAVA_HOME
# must point at the real JDK home under libexec. The SDK sits in
# ~/android-sdk rather than the Android Studio default, and the
# NDK is pinned so Tauri builds stay reproducible.

export JAVA_HOME="/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home"
export ANDROID_HOME="$HOME/android-sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export NDK_HOME="$ANDROID_HOME/ndk/26.1.10909125"
export ANDROID_NDK_HOME="$NDK_HOME"

path=(
  /opt/homebrew/opt/rustup/bin      # rustup toolchain shims
  $JAVA_HOME/bin                    # java, javac (keg-only)
  $ANDROID_HOME/platform-tools      # adb, fastboot
  $path
)
