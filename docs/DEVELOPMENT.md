# Development

The source is intentionally small and has three main components:

- `Rules.lua`: stateless checks against a single Instance; emits zero or more findings.
- `Scanner.lua`: depth-first traversal, ignored-subtree support, periodic yielding and report limits.
- `Plugin.lua`: Studio toolbar, docked UI, filters, object selection, and copyable report.

The bundler substitutes both ModuleScript imports with inlined functions, because a saved Local Plugin Script cannot import project files from your filesystem.

Run `python scripts/build.py` after editing the Luau modules and commit the updated `dist/WorldAudit.plugin.lua` together with the source.

CI checks that the generated file matches the committed output. This catches the common mistake of editing `src/` but not rebuilding `dist/`. Roblox Studio is the runtime for the distributable; the build tool cannot validate engine APIs.

## Release procedure

1. Run the Python test suite.
2. Complete `docs/TESTING.md` inside a current version of Roblox Studio.
3. Try the tool with a small and a larger place, recording false positives and scan times.
4. Tag a release only after any runtime issues are resolved.
