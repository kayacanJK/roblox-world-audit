# World Audit

A read-only scene inspector for Roblox Studio.

World Audit looks for configuration choices worth reviewing in large Roblox places: expensive mesh collision settings, unusually high particle rates, invisible colliders, and a handful of common content mistakes. It shows each finding in a docked panel; clicking a row selects the instance in Explorer.

**Status:** `0.1.0` preview. The distributable is generated and checked in CI, but real Studio compatibility has **not** yet been verified. Test against a copy of a place.

## Features

- Manual, read-only Workspace scans. No game objects are added, edited, or deleted.
- Warning and informational levels, searchable by rule code or object path.
- Click-to-select findings, progressive result loading, and a copyable text report.
- Ignore an entire subtree by setting its `WorldAuditIgnore` Boolean attribute to `true`.
- Iterative traversal with periodic yields for larger scenes.
- No HTTP requests, telemetry, asset uploads, or account permissions.

## Checks

| Code | Level | What it flags |
| --- | --- | --- |
| `PRECISE_COLLISION` | Warning | MeshParts using PreciseConvexDecomposition |
| `HIGH_PARTICLE_RATE` | Warning | Enabled emitters emitting more than 250 particles/s |
| `INVISIBLE_COLLIDER` | Info | Fully transparent, collidable BaseParts |
| `LOOSE_ROOT_PART` | Info | Unanchored BaseParts directly in Workspace |
| `WIDE_SHADOW_LIGHT` | Info | Enabled, shadow-casting lights with range greater than 40 |
| `MISSING_SOUND_ID` | Info | Sound objects with an empty SoundId |
| `MISSING_TEXTURE` | Info | Decal/Texture objects with an empty Texture |

Thresholds are starting points, **not measured performance budgets**. An invisible collision volume or a precise mesh collider can be perfectly intentional. Review every finding in its gameplay context.

## Install

1. Download [`dist/WorldAudit.plugin.lua`](dist/WorldAudit.plugin.lua) (use **Raw** on GitHub), or clone this repository.
2. In Roblox Studio, open a disposable place and create a **Script** inside **ServerStorage**.
3. Replace the Script's content with the downloaded file's text.
4. Select the Script, then choose **Plugins → Save as Local Plugin**.
5. Remove the temporary Script from ServerStorage. World Audit will appear on the Plugins toolbar.
6. Open World Audit and select **Scan Workspace**.

For Studio plugin installation details, see [Roblox's plugin guide](https://create.roblox.com/docs/studio/plugins).

## Use

Run a scan, click a finding to locate its object, and decide whether to change it. The plugin deliberately does not make changes for you.

To suppress false positives under a model:

1. Select the model in Explorer.
2. In Properties, add a Boolean attribute named `WorldAuditIgnore`.
3. Set it to `true` and scan again.

The inspector retains at most 5,000 findings per scan (the total count still increments beyond that); the panel shows up to 80 rows at first and loads additional rows as requested.

## Build and validate

Requires Python 3.10+ to bundle; no Python dependencies.

```bash
python scripts/build.py
python -m unittest discover -s tests -v
```

`src/Rules.lua` contains the checks, `src/Scanner.lua` traverses the hierarchy, and `src/Plugin.lua` provides the Studio UI. `scripts/build.py` builds a single-file local plugin into `dist/`.

The Python test suite verifies the bundler and packaging contract. **It does not execute Luau or replace Studio testing.** Follow [the Studio checklist](docs/TESTING.md) before relying on a release.

## Contributing

Useful rule ideas, false-positive reports, accessibility improvements, and test results are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md), [rule guidance](docs/RULES.md), and [the manual test checklist](docs/TESTING.md).

## License

[MIT](LICENSE). This project is independent of Roblox Corporation.
