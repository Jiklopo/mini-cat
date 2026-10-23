# MiniCat

A tiny RunCat-style menu bar app for macOS: a cat that runs faster as CPU load goes up.
The menu shows CPU, memory (GB and %) and swap usage.

No Xcode, App Store or Apple ID needed — it builds with the Command Line Tools.

## Install

```sh
xcode-select --install   # skip if already installed
git clone <repo-url> MiniCat
cd MiniCat
./build.sh
cp -R build/MiniCat.app /Applications/
open /Applications/MiniCat.app
```

Requires macOS 13+. Builds a universal binary (Apple Silicon + Intel).

## Options

Click the cat:

- **Show CPU % in Menu Bar** — shows the number next to the cat
- **Launch at Login** — if it fails, add MiniCat in System Settings → General → Login Items

## Tuning the speed

Edit `speedCurve` in `main.swift` — pairs of CPU % and seconds per frame, interpolated linearly:

```swift
(0, 0.2), (25, 0.115), (50, 0.075), (100, 0.02)
```

Then rebuild and copy to `/Applications` again.

## Credits

Cat animation frames are from [RunCat Neo](https://github.com/runcat-dev/RunCatNeo),
licensed under Apache-2.0 — see `Resources/LICENSE-RunCatNeo`.
