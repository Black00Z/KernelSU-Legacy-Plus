$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$Manager = Join-Path $Root "manager"
$Ksud = Join-Path $Root "userspace\ksud"
$Out = Join-Path $Root "out"

function Fail([string]$Message) { Write-Error $Message; exit 1 }
function Step([string]$Message) { Write-Host "`n==> $Message" -ForegroundColor Cyan }

if (-not (Get-Command java -ErrorAction SilentlyContinue)) { Fail "Java 21 is required." }
if (-not (Get-Command cargo -ErrorAction SilentlyContinue)) { Fail "Rust/Cargo is required." }
if (-not (Get-Command rustup -ErrorAction SilentlyContinue)) { Fail "rustup is required." }

$Sdk = $env:ANDROID_SDK_ROOT
if (-not $Sdk) { $Sdk = $env:ANDROID_HOME }
if (-not $Sdk) {
    $Candidate = Join-Path $env:LOCALAPPDATA "Android\Sdk"
    if (Test-Path $Candidate) { $Sdk = $Candidate }
}
if (-not $Sdk -or -not (Test-Path $Sdk)) { Fail "Android SDK not found. Set ANDROID_SDK_ROOT or ANDROID_HOME." }

$NdkVersion = "27.0.12077973"
$Ndk = Join-Path $Sdk "ndk\$NdkVersion"
if (-not (Test-Path $Ndk)) { Fail "Android NDK $NdkVersion is missing. Install it in Android Studio SDK Manager." }

$PrebuiltRoot = Join-Path $Ndk "toolchains\llvm\prebuilt"
$Prebuilt = Get-ChildItem $PrebuiltRoot -Directory | Select-Object -First 1
if (-not $Prebuilt) { Fail "NDK LLVM prebuilt toolchain not found." }
$ToolBin = Join-Path $Prebuilt.FullName "bin"
$Clang = Join-Path $ToolBin "aarch64-linux-android26-clang.cmd"
if (-not (Test-Path $Clang)) { $Clang = Join-Path $ToolBin "aarch64-linux-android26-clang.exe" }
if (-not (Test-Path $Clang)) { Fail "Android clang not found in $ToolBin" }

New-Item -ItemType Directory -Force -Path $Out | Out-Null
$Jni = Join-Path $Manager "app\src\main\jniLibs\arm64-v8a"
New-Item -ItemType Directory -Force -Path $Jni | Out-Null
$SdkProp = $Sdk.Replace('\','/')
"sdk.dir=$SdkProp" | Set-Content -Encoding ASCII (Join-Path $Manager "local.properties")

Step "Preparing Rust target"
& rustup target add aarch64-linux-android

Step "Building patched legacy ksud (arm64)"
$env:CARGO_TARGET_AARCH64_LINUX_ANDROID_LINKER = $Clang
$env:CC_aarch64_linux_android = $Clang
$env:AR_aarch64_linux_android = Join-Path $ToolBin "llvm-ar.exe"
Push-Location $Ksud
try { & cargo build --target aarch64-linux-android --release --locked } finally { Pop-Location }

$KsudBin = Join-Path $Ksud "target\aarch64-linux-android\release\ksud"
if (-not (Test-Path $KsudBin)) { $KsudBin = "$KsudBin.exe" }
if (-not (Test-Path $KsudBin)) { Fail "ksud binary not found after Cargo build." }
Copy-Item -Force $KsudBin (Join-Path $Jni "libksud.so")

Step "Building KernelSU Legacy+ debug APK"
Push-Location $Manager
try { & .\gradlew.bat --no-daemon clean assembleDebug } finally { Pop-Location }

$Apk = Get-ChildItem (Join-Path $Manager "app\build\outputs\apk\debug") -Filter *.apk | Select-Object -First 1
if (-not $Apk) { Fail "Gradle completed but no APK was found." }
$Final = Join-Path $Out "KernelSU-LegacyPlus-Companion-debug.apk"
Copy-Item -Force $Apk.FullName $Final
Step "DONE"
Write-Host "APK: $Final" -ForegroundColor Green
