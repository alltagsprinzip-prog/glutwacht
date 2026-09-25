# HUD continuation — 25 September 2026

Continues `update/hud-review-20260925` from `c52831e`, preserving the integrated mobile candidate and upstream `85cbae9`.

## Changes

- Larger, labelled home actions; distinct profile panel; larger resource counters; framed building action strip.
- Village joystick separated from Attack, with visible direction ticks, consistent drag sensitivity, dead zone and captured pointer ownership beyond its circle.
- Pointer release, window focus loss and hidden controls stop movement. Joystick touches never pan or place troops.
- Class-specific Super control and distinct Erdbrecher, Schattenschnitt, Geisterstrom and Runenfall geometry. Existing pending-hit logic is unchanged.
- Existing save filename and schema 7 retained. Unsupported or corrupt saves cannot be overwritten by autosave. Malformed JSON is handled without a Godot error log.

## Validation

Godot 4.7.2, local software OpenGL rendering:

- 186/186 rule/save checks, including schema 4–7 progress/deadline preservation and byte-for-byte protection of unsupported/corrupt files.
- 51/51 real InputEvent touch checks, including 10 individual placements of each troop type, joystick outside-drag/release, separate hit regions and all dialog close buttons.
- 69/69 rendered scene checks; home/selection/dialog/result and all class effect screenshots inspected as appropriate.
- Existing upstream release gate: passed (single deployment, delayed hit, partial loot).
- Web export: passed.

No existing user save was accessed or deleted. Tests use isolated fixtures. This is not a claim about a user's actual device or save file.

## Remaining release gate

The new Web export has not been exercised in a WebGL2 browser. The local Playwright browser download returned a Site Unavailable page. Prior candidate's cloud-browser WebGL2 limitation remains documented in PR #1. Do not merge to main or publish until browser gameplay is verified. No mobile FPS claim.
