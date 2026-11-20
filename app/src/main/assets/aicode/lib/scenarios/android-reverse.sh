#!/bin/sh
# Scénario: Android reverse / ré-ingénierie APK
# Installe JDK, Android SDK build-tools, apktool, jadx, aapt2/apksigner/zipalign et NDK/sysroot.
scenario_name_android_reverse() { echo "Android reverse / APK tools (JDK + NDK + apktool + jadx)"; }

install_scenario_android_reverse() {
    echo ""
    echo "Installation des outils Android reverse..."

    # Base: Java, download, archive, compression, build natif portable.
    pkg_add curl wget unzip tar xz zip unzip which file || return 1
    case "$PMGR" in
        apk)
            pkg_add openjdk17-jdk clang llvm make cmake ninja python3 py3-pip || return 1
            ;;
        apt)
            pkg_add "$(apt_jdk_pkg)" clang llvm make cmake ninja-build python3 python3-pip || return 1
            ;;
        dnf|yum)
            pkg_add java-17-openjdk-headless clang llvm make cmake ninja-build python3 python3-pip || return 1
            ;;
        pacman)
            pkg_add jdk17-openjdk clang llvm make cmake ninja python python-pip || return 1
            ;;
    esac

    # Android SDK: plateforme 36 + build-tools 35, avec remplacement ARM64 des binaires natifs.
    install_android_sdk "36" "35.0.0" || return 1
    install_android_tools_arm64 || true
    write_android_profile || true

    SDK="$HOME/android/sdk"
    BIN="$HOME/.local/bin"
    TOOLS="$HOME/.aicode/tools"
    mkdir -p "$BIN" "$TOOLS" "$SDK/ndk-sysroot"

    # NDK via sdkmanager si disponible. Sur ARM64, les binaires x86_64 du NDK officiel ne sont pas
    # exécutables: on garde le sysroot NDK pour compiler avec clang natif cible aarch64-linux-android.
    export ANDROID_HOME="$SDK" ANDROID_SDK_ROOT="$SDK"
    export PATH="$SDK/cmdline-tools/latest/bin:$BIN:$PATH"
    SDK_ROOT_FOR_MIRROR="$SDK"
    echo "Tentative installation du paquet NDK via sdkmanager..."
    SDK_TEST_BASE_URL="$ANDROID_MIRROR" yes | sdkmanager --install "ndk;27.2.12479018" >/dev/null 2>&1 \
        || yes | sdkmanager --install "ndk;27.2.12479018" >/dev/null 2>&1 \
        || echo "${C_YELLOW}NDK sdkmanager non installé; sysroot NDK sera utilisé avec clang.${C_RESET}"

    # Apktool (jar multiplateforme).
    APKTOOL_VER="3.0.3"
    APKTOOL_JAR="$TOOLS/apktool-$APKTOOL_VER.jar"
    if [ ! -f "$APKTOOL_JAR" ]; then
        echo "Téléchargement apktool $APKTOOL_VER..."
        curl -fL --retry 3 -o "$APKTOOL_JAR" \
            "https://github.com/iBotPeaches/Apktool/releases/download/v$APKTOOL_VER/apktool_$APKTOOL_VER.jar" \
        || curl -fL --retry 3 -o "$APKTOOL_JAR" \
            "https://gh-proxy.com/https://github.com/iBotPeaches/Apktool/releases/download/v$APKTOOL_VER/apktool_$APKTOOL_VER.jar" \
        || { echo "${C_RED}apktool download failed${C_RESET}"; return 1; }
    fi
    cat > "$BIN/apktool" <<'EOF'
#!/bin/sh
exec java -jar "__APKTOOL_JAR__" "$@"
EOF
    sed -i "s|__APKTOOL_JAR__|$APKTOOL_JAR|g" "$BIN/apktool"
    chmod +x "$BIN/apktool"

    # jadx (jar + scripts).
    JADX_VER="1.5.7"
    if [ ! -x "$BIN/jadx" ]; then
        echo "Téléchargement jadx $JADX_VER..."
        ZIP="$HOME/.aicode-cache/jadx-$JADX_VER.zip"
        mkdir -p "$HOME/.aicode-cache"
        curl -fL --retry 3 -o "$ZIP" "https://github.com/skylot/jadx/releases/download/v$JADX_VER/jadx-$JADX_VER.zip" \
        || curl -fL --retry 3 -o "$ZIP" "https://gh-proxy.com/https://github.com/skylot/jadx/releases/download/v$JADX_VER/jadx-$JADX_VER.zip" \
        || { echo "${C_YELLOW}jadx download failed; apktool reste disponible.${C_RESET}"; ZIP=""; }
        if [ -n "$ZIP" ] && [ -f "$ZIP" ]; then
            rm -rf "$TOOLS/jadx-$JADX_VER"
            unzip -q "$ZIP" -d "$TOOLS"
            JADX_DIR="$(find "$TOOLS" -maxdepth 1 -type d -name 'jadx-*' | head -1)"
            if [ -n "$JADX_DIR" ]; then
                chmod +x "$JADX_DIR/bin/jadx" "$JADX_DIR/bin/jadx-gui" 2>/dev/null || true
                ln -sf "$JADX_DIR/bin/jadx" "$BIN/jadx"
            fi
        fi
    fi

    # DEX tooling: dex2jar, baksmali/smali, enjarify, dumpdex, unpack detectors.
    D2J_VER="2.4"
    D2J_DIR="$TOOLS/dex-tools-$D2J_VER"
    echo "Téléchargement dex2jar $D2J_VER..."
    D2J_ZIP="$HOME/.aicode-cache/dex-tools-$D2J_VER.zip"
    mkdir -p "$HOME/.aicode-cache"
    if [ ! -x "$D2J_DIR/d2j-dex2jar.sh" ]; then
        curl -fL --retry 3 -o "$D2J_ZIP" "https://github.com/pxb1988/dex2jar/releases/download/v$D2J_VER/dex-tools-$D2J_VER.zip" \
        || curl -fL --retry 3 -o "$D2J_ZIP" "https://gh-proxy.com/https://github.com/pxb1988/dex2jar/releases/download/v$D2J_VER/dex-tools-$D2J_VER.zip" \
        || echo "${C_YELLOW}dex2jar download failed.${C_RESET}"
        if [ -f "$D2J_ZIP" ]; then
            rm -rf "$D2J_DIR"
            unzip -q "$D2J_ZIP" -d "$TOOLS" || true
        fi
    fi
    if [ -x "$D2J_DIR/d2j-dex2jar.sh" ]; then
        chmod +x "$D2J_DIR"/*.sh 2>/dev/null || true
        for t in d2j-dex2jar d2j-dex2smali d2j-baksmali d2j-smali; do
            cat > "$BIN/$t" <<EOF
#!/bin/sh
exec sh "$D2J_DIR/$t.sh" "\$@"
EOF
            chmod +x "$BIN/$t"
        done
    fi

    SMALI_VER="2.5.2"
    BAKSMALI_JAR="$TOOLS/baksmali-$SMALI_VER.jar"
    SMALI_JAR="$TOOLS/smali-$SMALI_VER.jar"
    if [ ! -f "$BAKSMALI_JAR" ]; then
        echo "Téléchargement baksmali/smali..."
        curl -fL --retry 3 -o "$BAKSMALI_JAR" "https://repo1.maven.org/maven2/org/smali/baksmali/$SMALI_VER/baksmali-$SMALI_VER.jar" || true
        curl -fL --retry 3 -o "$SMALI_JAR" "https://repo1.maven.org/maven2/org/smali/smali/$SMALI_VER/smali-$SMALI_VER.jar" || true
    fi
    if [ -f "$BAKSMALI_JAR" ]; then
        cat > "$BIN/baksmali" <<EOF
#!/bin/sh
exec java -jar "$BAKSMALI_JAR" "\$@"
EOF
        chmod +x "$BIN/baksmali"
    fi
    if [ -f "$SMALI_JAR" ]; then
        cat > "$BIN/smali" <<EOF
#!/bin/sh
exec java -jar "$SMALI_JAR" "\$@"
EOF
        chmod +x "$BIN/smali"
    fi

    if [ ! -x "$BIN/enjarify" ]; then
        echo "Téléchargement enjarify..."
        ENJ_ZIP="$HOME/.aicode-cache/enjarify-master.zip"
        curl -fL --retry 3 -o "$ENJ_ZIP" "https://github.com/google/enjarify/archive/refs/heads/master.zip" || true
        if [ -f "$ENJ_ZIP" ]; then
            rm -rf "$TOOLS/enjarify-master"
            unzip -q "$ENJ_ZIP" -d "$TOOLS" || true
            if [ -f "$TOOLS/enjarify-master/enjarify.sh" ]; then
                chmod +x "$TOOLS/enjarify-master/enjarify.sh"
                cat > "$BIN/enjarify" <<EOF
#!/bin/sh
exec sh "$TOOLS/enjarify-master/enjarify.sh" "\$@"
EOF
                chmod +x "$BIN/enjarify"
            fi
        fi
    fi

    cat > "$BIN/dumpdex" <<'EOF'
#!/bin/sh
if [ -z "$1" ] || [ ! -f "$1" ]; then
  echo "Usage: dumpdex <apk|zip|jar|dex> [output_dir]" >&2
  exit 1
fi
SRC="$1"
OUT="${2:-dex_out_$(basename "$SRC")}"
mkdir -p "$OUT"
case "$SRC" in
  *.dex|*.odex|*.dey) cp -f "$SRC" "$OUT/" ;;
  *) unzip -q -o "$SRC" -d "$OUT" 'classes*.dex' '*.dex' '*.odex' '*.dey' 'assets/*.dex' 'assets/*/*.dex' 'files/*.dex' 'files/*/*.dex' 2>/dev/null || true ;;
esac
find "$OUT" -type f \( -name '*.dex' -o -name '*.odex' -o -name '*.dey' \) -print
EOF
    chmod +x "$BIN/dumpdex"

    cat > "$BIN/apk-unpack-detect" <<'EOF'
#!/bin/sh
if [ -z "$1" ] || [ ! -f "$1" ]; then
  echo "Usage: apk-unpack-detect <apk>" >&2
  exit 1
fi
APK="$1"
WORK="${2:-unpacked_$(basename "$APK" .apk)}"
mkdir -p "$WORK"
unzip -q -o "$APK" -d "$WORK" || exit 1
echo "== Packer indicators =="
grep -RaoE 'libjiagu|jiagu|360|ijiami|libsecexe|libsecmain|libshella|libDexHelper|bangcle|secneo|legu|epic|tencent' "$WORK" 2>/dev/null | sort -u | head -40 || true
echo "== DEX candidates =="
find "$WORK" -type f \( -name '*.dex' -o -name '*.odex' -o -name '*.dey' \) -print | head -80
echo "== Suspicious assets/files =="
find "$WORK/assets" "$WORK/files" -type f 2>/dev/null | head -80 || true
echo "Suggestion: dumpdex \"$APK\" \"$WORK/dex\"; then baksmali d <file.dex> -o smali_out"
EOF
    chmod +x "$BIN/apk-unpack-detect"

    # Wrappers Android build tools.
    for t in aapt aapt2 apksigner zipalign dx d8 dexdump; do
        p="$(find "$SDK/build-tools" -type f -name "$t" 2>/dev/null | head -1)"
        if [ -n "$p" ]; then chmod +x "$p" 2>/dev/null || true; ln -sf "$p" "$BIN/$t"; fi
    done
    [ -x "$SDK/platform-tools/adb" ] && ln -sf "$SDK/platform-tools/adb" "$BIN/adb"

    # Wrapper clang cible Android arm64. Préfère sysroot NDK sdkmanager, sinon tente un NDK sysroot local.
    cat > "$BIN/ndk-clang" <<'EOF'
#!/bin/sh
NDK_DIR="$(find "__SDK__/ndk" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | head -1)"
if [ -n "$NDK_DIR" ] && [ -d "$NDK_DIR/toolchains/llvm/prebuilt/linux-x86_64/sysroot" ]; then
    SYSROOT="$NDK_DIR/toolchains/llvm/prebuilt/linux-x86_64/sysroot"
else
    SYSROOT="__SDK__/ndk-sysroot"
fi
exec clang --target=aarch64-linux-android24 --sysroot="$SYSROOT" "$@"
EOF
    sed -i "s|__SDK__|$SDK|g" "$BIN/ndk-clang"
    chmod +x "$BIN/ndk-clang"

    # Ajouter le profil utilisateur.
    grep -q '/\.local/bin' /etc/profile.d/aicode-android.sh 2>/dev/null || echo 'export PATH="$HOME/.local/bin:$PATH"' >> /etc/profile.d/aicode-android.sh
    export PATH="$BIN:$PATH"

    echo ""
    echo "${C_GREEN}Outils Android reverse installés.${C_RESET}"
    echo "  apktool : $BIN/apktool"
    echo "  jadx    : $BIN/jadx"
    echo "  dex2jar : $BIN/d2j-dex2jar (si disponible)"
    echo "  baksmali: $BIN/baksmali (si disponible)"
    echo "  dumpdex : $BIN/dumpdex"
    echo "  unpack  : $BIN/apk-unpack-detect"
    echo "  aapt2   : $BIN/aapt2"
    echo "  apksigner: $BIN/apksigner"
    echo "  zipalign: $BIN/zipalign"
    echo "  NDK/clang: $BIN/ndk-clang"
    echo ""
    echo "Nouvelle session requise pour que le PATH profil soit rechargé."
    return 0
}
