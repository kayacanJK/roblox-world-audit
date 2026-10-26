# Writing inspection rules

World Audit is a review tool, not an automatic optimizer. A warning is a prompt for investigation, not a declaration that a place is broken.

## Checklist

1. Detect a specific, reproducible configuration using public instance properties.
2. Keep the threshold explicit and provide the reasoning in the finding message.
3. Avoid assumptions about the gameplay, platform, or developer intent.
4. Prefer information-level findings when false positives are plausible.
5. Avoid yielding, changing instance properties, remote requests, or expensive descendant queries inside an individual rule.
6. Add a reproducible fixture to the manual test checklist.

## Current trade-offs

- `HIGH_PARTICLE_RATE` flags rates over 250/s by default. Actual cost depends on particle lifetime, emitter count, device, and visibility.
- `PRECISE_COLLISION` is advisory. Some assets genuinely need detailed collision.
- `INVISIBLE_COLLIDER` flags intentional invisible walls as well as accidental ones.
- `LOOSE_ROOT_PART` does not examine parts nested in models.
- Light and asset checks are about potential review opportunities, not validated runtime errors.

Avoid introducing a single global performance score: it would imply a degree of certainty the plugin cannot support without profiling.
