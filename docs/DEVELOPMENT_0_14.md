# Glutwacht 0.14.0 — playable Heroic pass

Continues 0.13.1; no new account system, reset or replacement repository.

## Implemented
- Replaced fixed 1280×720 centered UI with expanded canvas, actual viewport layout and mapped iOS safe rectangle. Four village actions, edge joystick/attack, compact save status. Dialogs center in safe area; existing native keyboard-aware account form remains.
- Shared navy/gold beveled surfaces with inset rim, upper reflection, lower shadow and distinct primary/selected/disabled styling across panels and buttons. Existing own resource/action artwork retained.
- Procedural 3D log bundles, faceted stone and coin stacks over production buildings. Gentle bob/pulse, actual stock number; pickup flies to the actual resource HUD location and shows the awarded amount. Economy code credits once before visual feedback.
- Manual raids begin with an undeployed hero. Shared troop-zone validation; pending hero cannot move, attack, cast or receive damage and is excluded from enemy targets. Single/group troop deployment preserved. Ground preview uses green/red marker.
- Smooth hero-follow camera; manual pan/zoom disables follow until Zum Helden. Hero is larger, has a gold crest and class ring. Heavy/ranged infantry have different movement cadence; siege carrier gains a wheeled equipment silhouette. Existing attack clips remain role-specific.
- Inland village bounds expand from 62×62 to 70×78 world units (eastern river boundary unchanged). Placement, save loading, movement and camera bounds updated; existing coordinates retained. Shared loading path is also used for friend visits.
- Foliage wind shader, moving fabric flags, turquoise moving water, cobbled paths, corrected imported rock/bridge materials and broader vegetation variation. Actual build progress changes construction scale; completion emits a nonblocking effect only for finished jobs.

## Evidence and validation
- Initial render-only review at 52a77c8: 34 new assertions plus 54 simulated touch assertions passed; four real Godot screenshots reviewed. Corrected overbright imported rocks/bridge and sync-label overlap afterward.
- Local final logic: 37 Heroic assertions (viewport sizes, persistence, collection idempotence, deployment, camera), 187 release/migration assertions, 204 HUD layout assertions. Account save 37, native account 9, cloud recovery 10, progression 106, campaign 68 passed during development.
- Native publication workflow requires fresh release, HUD, Heroic render, account, recovery, campaign, tutorial, social and simulated touch checks before producing signed iOS and Windows builds. Final CI results supersede these local counts.
- Render metrics explicitly identify CI software rendering and replay conditions. They are not measurements of iPhone GPU performance.

## Limits / remaining acceptance
- No physical iPhone or Windows device session has been performed here. Keyboard, thermal/frame stability, real multi-account/device switching and touch comfort require device acceptance.
- Rendering is closer in layout/material direction, not a reproduction of the Heroic reference. Existing low-poly mine, defenses and soldier meshes remain. More detailed sculpted foliage, building trim, character outfits and bespoke attack clips would be needed for close visual fidelity.
- Clan/friend systems and their permissions are preserved, not extended in this visual pass. This release does not turn private client snapshots into an authoritative economy or enable secure PvP.
- Do not downgrade after placing buildings in expanded territory: old clients still clamp to the old bounds. Saves remain schema 7; only supported forward loading is covered.
- TestFlight availability is reported only after Apple processing and group assignment are checked. A successful upload is not device acceptance.
