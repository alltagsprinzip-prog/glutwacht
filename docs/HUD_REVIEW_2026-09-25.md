# HUD continuation — 25 September 2026

Continues `update/hud-review-20260925` from `c52831e`, preserving the integrated mobile candidate and upstream `85cbae9`.

## Changes

- Larger, labelled home actions; distinct profile panel; larger resource counters; framed building action strip.
- Village joystick separated from Attack, with visible direction ticks, consistent drag sensitivity, dead zone and captured pointer ownership beyond its circle.
- Pointer release, window focus loss and hidden controls stop movement. Joystick touches never pan or place troops.
- Class-specific Super control and distinct Erdbrecher, Schattenschnitt, Geisterstrom and Runenfall geometry. Existing pending-hit logic is unchanged.
- The previously published `/v08final/` URL redirects to the new build on the same origin; browser validation checks that the profile survives this route.
- Existing save filename and schema 7 retained. Unsupported or corrupt saves cannot be overwritten by autosave. Malformed JSON is handled without a Godot error log.

## Validation

Godot 4.7.2, local software OpenGL rendering:

- 187/187 rule/save checks, including schema 4–7 progress/deadline preservation and byte-for-byte protection of unsupported/corrupt files.
- 51/51 real InputEvent touch checks, including 10 individual placements of each troop type, joystick outside-drag/release, separate hit regions and all dialog close buttons.
- 69/69 rendered scene checks; home/selection/dialog/result and all class effect screenshots inspected as appropriate.
- Existing upstream release gate: passed (single deployment, delayed hit, partial loot).
- Web export: passed.

No existing user save was accessed or deleted. Tests use isolated fixtures. This is not a claim about a user's actual device or save file.

## Browser findings and remaining release gate

The exported game was exercised in Chromium/WebGL2 on GitHub Actions. Touch joystick movement, catalogue/shop closing, hero/resource persistence after reload and five single deployments succeeded. Screenshots confirm the new HUD.

The full-raid test exposed a real bug: the movement delta cap also capped elapsed raid time. On the very slow software renderer, four real minutes advanced the timer by only 14 seconds. Godot itself also bounds process delta at low FPS (confirmed with a 1 FPS probe). The raid clock now receives monotonic elapsed real time from the main loop while movement integration retains its stability cap. Paused frames update the clock reference without advancing combat. A regression test covers a delayed frame crossing the raid deadline.

The updated full browser gate must pass before merge/publication. No mobile FPS claim. Continued in isolated PR #3 after another work session modified the former shared review branch.
