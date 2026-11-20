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

## DEX dump / unpack helpers

Installed commands in the Android reverse scenario:

- `dumpdex <apk|zip|jar> [out]`: extracts `classes*.dex`, hidden `.dex/.odex/.dey` candidates from assets/files.
- `apk-unpack-detect <apk> [work_dir]`: unzips APK, prints packer indicators (Jiagu / 360 / Ijiami / Bangcle / Legu / Epic / Tencent) and DEX candidates.
- `d2j-dex2jar`, `d2j-dex2smali`: dex2jar tools.
- `baksmali`, `smali`: smali/disassembly tools.
- `enjarify`: dex to JAR alternative.
- `dexdump`: Android build-tools DEX dumper.

For protected/packed APKs you own, first identify the protector, then look for dumped/runtime DEX. Runtime unpacking usually needs a rooted/emulated device or Frida; the container only guarantees static DEX extraction and analysis.

Do not use these tools on apps you do not own or do not have permission to analyze.
