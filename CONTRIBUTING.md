# Contributing to Roblox World Audit

Thanks for helping! This project aims to provide clear, low-risk feedback to Roblox developers.

1. Open an issue explaining a reproducible scene configuration or improvement.
2. Reproduce the issue in a disposable Roblox Studio test place.
3. Keep the plugin read-only. New checks must explain why the condition matters, and distinguish warnings from informational findings.
4. Add a manual test to `docs/TESTING.md` when changing behavior.
5. Describe screenshots, reproduction steps and known false positives in the pull request.

Avoid unnecessary network access, hidden game edits, attribution claims or fabricated performance metrics.

## Code guidelines

- Use Luau with clear names and small functions.
- Avoid scanning outside `Workspace` unless the change is explicitly documented.
- Keep rules conservative; normal game patterns must not be presented as definite errors.
- Do not add automated modifications without an explicit, reviewable separate workflow.

## Code of conduct

Be constructive and respectful. Report security issues privately to the maintainer rather than publishing exploit details.
