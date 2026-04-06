# Azox Clicker (macOS menu bar auto-clicker)

This repo contains the SwiftUI source files for a menu bar auto-clicker called **Azox Clicker**. It uses global keyboard shortcuts and requires Accessibility permission to send mouse events.

## Quick start (Xcode)
1. Open Xcode and create a new **macOS App** project.
   - Product Name: `Azox Clicker`
   - Interface: `SwiftUI`
   - Language: `Swift`
   - Bundle Identifier: anything you want (e.g. `com.azox.clicker`)
   - Minimum macOS: 13.0+ recommended (for `MenuBarExtra`)
2. Delete the auto-created Swift files in the project.
3. Drag every `.swift` file from `AzoxClicker/` into the Xcode project (keep “Copy items if needed” checked).
4. Add the **KeyboardShortcuts** package:
   - Xcode menu: `File` -> `Add Packages...`
   - URL: `https://github.com/sindresorhus/KeyboardShortcuts`
5. Build and run. The app appears as a menu bar icon. Open **Settings** from the menu to configure speed, shortcuts, and stop limits.

## Accessibility permission
The first time you run it, macOS will ask for Accessibility access. If not, open System Settings -> Privacy & Security -> Accessibility, and enable **Azox Clicker**.

## DMG build (explain how to compile)
Once your app is building in Xcode, you can export a `.app` and wrap it into a `.dmg`:

1. In Xcode: `Product` -> `Archive`.
2. When the Organizer opens, select the latest archive and click **Distribute App**.
3. Choose **Copy App** (or **Developer ID** if you have signing) and export the `.app`.
4. Put the exported app into a folder, e.g. `~/Desktop/AzoxClickerDist/Azox Clicker.app`.
5. Create a DMG with Terminal:

```bash
hdiutil create -volname "Azox Clicker" -srcfolder "~/Desktop/AzoxClickerDist" -ov -format UDZO "~/Desktop/AzoxClicker.dmg"
```

That produces `AzoxClicker.dmg` on your Desktop.

## Notes
- Click speed warning appears when the max CPS exceeds 100.
- Use **Fixed CPS** + **Stop After Time** for the “CPS + end time” workflow.
- “Both” click mode sends a left click followed by a right click at the current cursor location.
