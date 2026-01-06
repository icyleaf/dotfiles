# Android SDK 路径（Android Studio）
if [ "$(uname -s)" = "Linux" ]; then
  export ANDROID_HOME="$HOME/Android/Sdk"
else
  export REPO_OS_OVERRIDE=macosx
  export ANDROID_HOME="$HOME/Library/Android/sdk"
fi

if [ -d "${ANDROID_HOME}" ]; then
  export PATH="${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${ANDROID_HOME}/tools/bin:/usr/local/sbin:$PATH"
fi
