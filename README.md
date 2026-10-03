# Shocker OwnZ: Grow Empire — APK Build Fix

This clean build-test package fixes the two errors shown in GitHub Actions:

- Replaces the broken `scenes/Main.tscn` with valid Godot 4 syntax.
- Removes the corrupted PNG dependency entirely for this build test.

IMPORTANT: upload the CONTENTS of this folder to the ROOT of the GitHub repository.
The root should contain:
`project.godot`, `export_presets.cfg`, `scenes/`, `scripts/`, and `.github/` (your existing workflow).

Do not upload the ZIP itself as the game project.
After these files are in the root, GitHub Actions should run again.
