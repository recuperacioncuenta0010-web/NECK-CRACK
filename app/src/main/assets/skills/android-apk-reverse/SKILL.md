---
name: android-apk-reverse
description: Use this skill when working on APK files, Android resources, manifest decoding, rebuilding, signing, decompiling Java/Kotlin bytecode, or installing Android reverse tools inside NECK CRACK.
---

# Android APK reverse workflow

If a command fails because `java`, `apktool`, `jadx`, `aapt2`, `apksigner`, `zipalign`, or an Android SDK/NDK is missing, run `aicode` in the terminal and install the scenario **Android reverse / APK tools**.

After install, verify:

```sh
java -version
apktool --version
jadx --version
aapt2 version
apksigner --version | head -1
```

Common workflow:

- Decode resources: `apktool d app.apk -o out`
- Rebuild: `apktool b out -o rebuilt.apk`
- Sign: `apksigner sign --ks keystore.jks --ks-key-alias alias rebuilt.apk`
- Decompile bytecode: `jadx -d sources app.apk`

Prefer file tools for text files and Bash/terminal for tooling. Do not use `cat | nc` or local HTTP relays to move files; use workspace paths and `sendFile`.
