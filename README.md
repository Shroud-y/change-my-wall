# Change My Wall

Windows makes you set the desktop wallpaper and the lock screen separately. I'm done with that. This adds a right-click option for images that sets both at once.

Works on Windows 10/11 (including Home), no admin rights needed.

## Install

1. Clone or download this repo somewhere it will stay (the menu runs the scripts from this folder).
2. Run `install.bat`.

To remove, run `uninstall.bat`. If you move the folder, run `install.bat` again.

## Use

Right-click an image → **Show more options** (or just **Shift + right-click**) → **Set as desktop + lock screen**.

Want different images? Use Windows' own **Set as desktop background**, which only changes the desktop.

From a terminal:

```
powershell -ExecutionPolicy Bypass -File Set-Wallpaper.ps1 "C:\path\to\image.jpg"
```

> The lock screen must be set to **Picture** (Settings → Personalization → Lock screen), not Windows Spotlight.
