# Glutwacht 0.14.0 — playable Heroic pass

## Continuation 27 September — interrupted save acknowledgements
- Confirmed existing TestFlight 0.14.0 (9.0.0): Apple reports VALID / IN_BETA_TESTING / Glutwacht test in run 36280416699. Windows artifact 10918497167 comes from successful publication run 36279940485.
- The browser gate in run 36280421191 stopped at `cloud_confirm` after reloading. A reproducible cause is a cloud write committed before shutdown whose acknowledgement was not retained locally.
- Automatic startup now replays the exact persisted request before comparing revisions. The server's existing idempotent receipt prevents duplicate writes; later local actions remain dirty and untouched. A genuinely newer head still requires explicit conflict resolution. Network failure retains the request. No database or save-schema changes.
- Local regression evidence: session resume 13/13, account/save 37/37, onboarding 19/19, cloud recovery 10/10, native sessions 13/13. Browser verification and a build containing this follow-up are pending; build 9 does not contain it.
- The earlier visual and audio limitations still apply. Recorded combat Foley and physical iPhone acceptance remain open.

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
- Local final logic: 40 Heroic assertions (viewport sizes, persistence, collection idempotence, deployment, camera), 187 release/migration assertions, 144 visible-control HUD layout assertions. Account save 37, native account 9, cloud recovery 10, progression 106, campaign 68 passed during development.
- Native publication workflow requires fresh release, HUD, Heroic render, account, recovery, campaign, tutorial, social and simulated touch checks before producing signed iOS and Windows builds. Final CI results supersede these local counts.
- Render metrics explicitly identify CI software rendering and replay conditions. They are not measurements of iPhone GPU performance.

## Limits / remaining acceptance
- No physical iPhone or Windows device session has been performed here. Keyboard, thermal/frame stability, real multi-account/device switching and touch comfort require device acceptance.
- Rendering is closer in layout/material direction, not a reproduction of the Heroic reference. Existing low-poly mine, defenses and soldier meshes remain. More detailed sculpted foliage, building trim, character outfits and bespoke attack clips would be needed for close visual fidelity.
- Clan/friend systems and their permissions are preserved, not extended in this visual pass. This release does not turn private client snapshots into an authoritative economy or enable secure PvP.
- Do not downgrade after placing buildings in expanded territory: old clients still clamp to the old bounds. Saves remain schema 7; only supported forward loading is covered.
- TestFlight availability is reported only after Apple processing and group assignment are checked. A successful upload is not device acceptance.

## Session, combat and clarity follow-up
- Native login now persists separately from village exports in an app-private encrypted file, restores the identity through the server and saves rotated refresh tokens. Temporary network failure retains the session for retry; revoked tokens and explicit logout clear it. No password is stored. This is device-bound file encryption, not an Apple Keychain / Windows Credential Manager integration.
- Up to five successful login addresses are remembered, most recent prefilled, native suggestions after three characters; addresses can be removed. Web form exposes saved addresses through a datalist and existing browser autocomplete. Actual iOS keyboard/password-manager behavior still needs hardware verification.
- Autoangriff appears after manual hero deployment. It approaches and attacks enemies; joystick input immediately switches back to manual. It does not automatically spend skills or potions.
- Locked catalog cards explain the actual main-building level with its icon, limits, builder availability or missing resources; a reachable explanation leads back to the catalog or main building.
- Original procedural combat audio now separates swing, bow, shield, impact and siege cues with three variants, pitch variation, voice pooling and per-cue throttling. Construction completion and battle start have distinct cues. These are synthesized effects, not recorded realistic Foley; listening acceptance remains open.
- Local mocked native-session tests: 13/13; interaction/audio checks: 25/25; account-save 37/37, recovery 10/10, visible HUD 144/144. They are not real multi-device or signed-in backend acceptance.
- Static scenery batching excludes ships and selectable obstacles. At 1560×720 on Linux llvmpipe LLVM 20.1.2, the 60-frame village replay changed from 1006 to 705 draw calls and 27677 ms to 25878 ms. These software-render timings do not predict iPhone frame rate.

## Final candidate evidence
- Application source: `fe6a62ba9ef55fa7894ed2e80314cd960e796eee`. Subsequent `e6c0ab4` changes only the art-preview assertion to recognize merged scenery meshes.
- Render review: https://github.com/alltagsprinzip-prog/glutwacht/actions/runs/36279940463 — 40/40 Heroic and 54/54 simulated input checks; genuine village, upgrade, resource collection and combat screenshots in artifact `heroic-review` (10918442071). The combat screenshot includes the new Autoangriff control.
- Final native publication run: https://github.com/alltagsprinzip-prog/glutwacht/actions/runs/36279940485 — target 0.14.0 (9.0.0). This link is build evidence, not proof of device acceptance. Apple processing/group status is checked independently by `check-testflight.yml`.
- Device acceptance: update the installed app (do not uninstall), sign in once, close/reopen, verify the same village, then explicitly log out and check remembered-email suggestions. Deploy hero, enable Autoangriff and interrupt with joystick. Inspect locked building requirements, resource pickup and combat sound volume. No physical device results have been asserted.
