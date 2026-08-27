# KernelSU Legacy+

Modern Action and WebUI support for older KernelSU setups.

Newer KernelSU Managers introduced useful module features like Actions and WebUIs later on.

So I thought of a way to bring some of that newer functionality back without having to replace a perfectly working older kernel.

KernelSU Legacy+ is a companion app based around the KernelSU v1.0.1 / 11928 generation, with selected newer module-management features backported for legacy installations.

Newer devices can use it too. For example, with Root My Galaxy you can first grant Legacy+ root, remove the original KernelSU Manager APK afterwards if your setup no longer needs it, and simply keep using Legacy+ as your Manager. This can also be useful on setups where apps react to the original KernelSU package being installed. :)

I specifically built this companion for my old vili (Xiaomi 11T Pro), which is still running an older KernelSU version that works perfectly fine for my setup.

## What it adds

Legacy+ focuses on the parts of newer KernelSU Managers that are useful for module interaction:

- Run a module's `action.sh` directly from the module list
- Open module WebUIs from `webroot/index.html`
- Show Action output and logs inside the app
- Use a patched legacy `ksud` with `module action <id>` support
- Install alongside the normal KernelSU Manager
- Leave the existing kernel and KernelSU integration untouched

---

<details>
<summary><strong>Why a companion app?</strong></summary>

Some older KernelSU kernels expect the official Manager identity/signature.

That makes replacing the normal Manager with a modified APK a bad idea on setups where the kernel still relies on that identity for authorization.

Legacy+ avoids that by using its own package ID:

```text
me.weishu.kernelsu.legacyplus
```

The normal KernelSU Manager can stay installed and continue doing its job where the kernel expects it.

Legacy+ sits beside it and gets root access like any other root app.

On setups where the underlying root implementation does not require the original Manager to remain installed after authorization, Legacy+ can also be used on its own as the module-management frontend.

</details>


---

<details>
<summary><strong>Why not just update KernelSU?</strong></summary>

Because a working kernel is sometimes more valuable than a newer Manager.

Older devices, ROM-specific kernels and custom builds can depend on a particular KernelSU integration. Updating the whole stack just to get newer Manager features can create completely unrelated problems.

Legacy+ takes the less exciting but safer approach:

> Keep the working kernel. Improve the part you actually interact with.

There is still an important limit to that.

Legacy+ can backport Manager-side functionality, but it cannot magically add kernel-side features that only exist in newer KernelSU versions. If a module genuinely requires a newer KernelSU kernel or UAPI, the companion app alone cannot provide that.

</details>


---

<details>
<summary><strong>Module Actions</strong></summary>

Modules can provide an Action script at:

```text
/data/adb/modules/<module-id>/action.sh
```

When Legacy+ finds one, it exposes an Action control for that module.

The bundled legacy `ksud` has been patched to understand:

```text
ksud module action <module-id>
```

That means Actions can be launched from the app instead of manually opening a shell and running the script yourself.

Doing that through a terminal every single time gets annoying pretty quickly, which is one of the main reasons I wanted this approach in the first place.

Output from the Action is captured and displayed in the app as well, which is useful for modules that use their Action for diagnostics, setup steps, logs, bug reports, or other one-shot tasks.

</details>


---

<details>
<summary><strong>Module WebUI</strong></summary>

Modules can also provide a local WebUI at:

```text
/data/adb/modules/<module-id>/webroot/index.html
```

If that file exists, Legacy+ exposes an Open/WebUI control for the module.

The page is loaded locally inside the app and the WebUI side includes the bridge needed for KernelSU-style interaction.

If a module does not ship a WebUI, the button simply does not appear.

</details>


---

## Installation

Keep your normal KernelSU Manager installed if your setup still depends on it for Manager authorization.

Then:

1. Install the KernelSU Legacy+ APK.
2. Open Legacy+.
3. Grant it root access.
4. Open the Modules page.

From there:

```text
action.sh                 -> Action control
webroot/index.html        -> Open/WebUI control
```

On compatible setups, both apps can stay installed at the same time.

## Building

From the project directory, build from the terminal with:

```bash
./scripts/build-apk.sh
```

The finished APK will be placed in:

```text
out/KernelSU-LegacyPlus-Companion-debug.apk
```

You can also just compile it directly in VS Code by opening the project folder and running:

```text
Ctrl + Shift + B
```

### Requirements

- JDK 21
- Android SDK
- Android NDK
- Rust toolchain

## Base

The current Legacy+ build is based on:

```text
KernelSU v1.0.1
Manager version code 11928
```

That generation was chosen because it fits the older KernelSU stack this project was originally made for while still being a practical Manager base to extend. Meaning: the current and maybe last version of KernelSU for my vili.

## Current status

- Builds and installs as an Android APK
- Installs alongside the official KernelSU Manager
- Supports legacy `ksud` module Actions
- Handles Action detection, execution and output
- Supports module WebUIs
- Includes terminal and VS Code APK builds

Some modules may still behave differently depending on how they use newer KernelSU features.

## Credits

KernelSU and its original Manager are developed by the KernelSU project and its contributors.

Legacy+ is based on KernelSU v1.0.1 and selectively adapts functionality and ideas from later KernelSU module-management implementations.

KernelSU:

https://github.com/tiann/KernelSU

---

Built because manually launching `action.sh` every time is not much of a UI.
