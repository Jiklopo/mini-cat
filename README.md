<h1>
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/cat-dark.gif">
    <img src="docs/cat-light.gif" width="28" height="18" alt="MiniCat running at 40% CPU">
  </picture>
  MiniCat
</h1>

A tiny RunCat-style menu bar app for macOS: a cat that runs faster as CPU load goes up.
The menu shows CPU, memory (GB and %) and swap usage.

No Xcode, App Store or Apple ID needed — it builds with the Command Line Tools.

## Install

```sh
xcode-select --install   # skip if already installed
git clone https://github.com/Jiklopo/mini-cat.git MiniCat
cd MiniCat
./build.sh
cp -R build/MiniCat.app /Applications/
open /Applications/MiniCat.app
```

Requires macOS 13+. Builds a universal binary (Apple Silicon + Intel).

## Options

Click the cat:

- **Character** — Cat, Fat Bongo Cat, Megumin (*Konosuba*) or Frieren (*Frieren: Beyond Journey's End*)
- **Show CPU % in Menu Bar** — shows the number next to the cat
- **Launch at Login** — if it fails, add MiniCat in System Settings → General → Login Items

## Tuning the speed

Edit `speedCurve` in `main.swift` — pairs of CPU % and seconds per frame, interpolated linearly:

```swift
(0, 0.2), (25, 0.115), (50, 0.075), (100, 0.02)
```

Then rebuild and copy to `/Applications` again.

## Adding a character

Put the frames in `Resources/` as `<prefix>00.png`, `<prefix>01.png`, … (40 px tall, transparent
background) and add a line to `characters` in `main.swift`. `template: true` turns the frames into a
one-color silhouette that follows the light/dark menu bar; `false` keeps their colors.

## Credits

Cat animation frames are from [RunCat Neo](https://github.com/runcat-dev/RunCatNeo),
licensed under Apache-2.0 — see `Resources/LICENSE-RunCatNeo`.

Megumin and Frieren frames are cut from the Discord emoji
[megumindanceemoji](https://communityone.io/emoji/megumindanceemoji-609238208382763020/) and
[frierenbeyondfuchsia](https://communityone.io/emoji/frierenbeyondfuchsia-1308629794505625700/).
The characters belong to their respective rights holders.
