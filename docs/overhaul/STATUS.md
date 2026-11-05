# Glutwacht overhaul — 2026-11-05

Base: aba21e61f2878c0dbd8be8744af583e4f3103cc1. Work branch: update/expeditions-v09.

## Acceptance plan
1. New village/combat visual reference: slate/amber UI, runic citadel, stone avenues, readable boss silhouette; capture and inspect actual renders before extending.
2. Connected progression: expeditions, boss objectives, earned shards, permanent crafting, specializations, region unlocking. Validate reward idempotency, costs and save continuity.
3. Remaining breadth: equipment variety and rarities, full asset direction, narrative missions, achievements, meaningful village research interaction, balancing and mobile usability.
4. Release: native regression, real exported WebGL playthrough covering new features, before/after captures, rollback reference, full source ZIP and only then merge/deploy.

## Implemented, not released
- Schema 8 expedition state with bounded input normalization; legacy saves backed up before migration.
- Nine expedition stages across three named regions, followed by scaling rift stages. Regions have different terrain and atmosphere palettes.
- Two-star clear requirement, boss survival blocks completion, replay rewards reduced, completion remains guarded by battle settlement.
- Runic weapon/armor crafting and expedition research; earned shards fund permanent improvements.
- Three freely selectable stat specializations, boss telegraph, larger boss silhouette.
- UI restyle, citadel geometry and settlement paths.

## Evidence and limitations
Local Godot 4.7.2 import/start passed. Existing rule/save suite: 187/187. New progression suite: 16/16. GitHub PR #5 runs existing rendered and browser gates. Those legacy browser gates do not yet cover the new expedition/workshop UI. No physical phone test. No measured performance claims. No complete overhaul or publication claim is warranted at this stage.
