# Manual test checklist

Run these tests inside a **copy** of a Roblox Studio place. The plugin has not been validated in Studio yet.

- [ ] Save the Script as a Local Plugin; reload Studio and check for output errors.
- [ ] Toolbar button opens/closes the docked World Audit window.
- [ ] Pressing Scan Workspace reports a sensible instance count.
- [ ] Adding a `MeshPart` with PreciseConvexDecomposition produces a warning.
- [ ] Adding a `ParticleEmitter` with Rate 300 and Enabled true produces a warning.
- [ ] A fully invisible, collidable `Part` produces an informational result.
- [ ] An unanchored `Part` directly under Workspace produces an informational result.
- [ ] An enabled shadow-casting `PointLight` with Range 50 produces an informational result.
- [ ] A Sound with blank SoundId produces an informational result.
- [ ] A Decal with blank Texture produces an informational result.
- [ ] Clicking a finding selects the exact instance in Studio.
- [ ] Setting `WorldAuditIgnore=true` on a containing Model hides its descendants' findings.
- [ ] Scanning twice does not duplicate UI rows.
- [ ] Inspect the before/after place hierarchy: the plugin does not modify or delete objects.
- [ ] Scan a large place and check UI responsiveness; record total instance count.
