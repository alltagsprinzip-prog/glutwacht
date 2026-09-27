# 0.13.1 — Recovery before authoritative economy migration

This is the first safety increment of item 1, NOT completion of server-authoritative gameplay.
The repository base is 6b29ddb (0.13.0); existing quests, friends, clans and gameplay remain.

## Implemented
- Immutable baseline of existing cloud snapshots, copied byte-for-byte as JSONB without normalizing their fields. No player_saves row is rewritten by rollout.
- Permanent account-scoped request receipts. Replays remain idempotent after later writes or history pruning; changing payload/device/operation for an ID is rejected.
- A stale acknowledged request reports the current head revision; the new client surfaces a conflict instead of claiming its old state is current.
- Private cloud history: baseline plus at most 48 additional checkpoints. Normal checkpoints are spaced at least 30 minutes apart; explicit restores back up the current version immediately.
- Account > Sicherungsverlauf: paginated list, explicit restore confirmation. Restore produces a new increasing revision and respects the existing 90-second device lease.
- Recovery intent is durably written before submission. Timeouts preserve exact request identity. Old-state uploads and gameplay are blocked while recovery is unresolved; reconnect/relogin resumes it. Local account file must be written before intent is cleared.
- No changes to social tables, auth credentials, hero selection or economy balances during migration.

## Trust boundary and next work
All current saves, including baseline/history, remain **private_pve**, sourced from a historically client-controlled save path. Archiving does not authenticate their resources, XP, campaign reports or buildings. Restore must never roll back social or future competitive ledgers.

Still open, in requested order:
1. Server-owned economy state and versioned commands for build, upgrade, training, production, collection and rewards; immutable economic ledger and request outbox; migration of legacy progression with explicit noncompetitive provenance. A save must never be promoted to competitive trust simply because it passed shape validation. Client combat results alone cannot create tradeable credit.
2. Verified clan tasks/XP/rewards/donations, limits, membership epoch protection, moderation UI and improved chat refresh.
3. Additional heroes/equipment/regions/production chains.
4. Optional periodic quests/achievements and tactical campaign variations.
5. Server-verified PvP, matchmaking, anti-farming protection; clan wars afterwards.
6. Actual Heroic Pop scene/HUD/material/vegetation/water improvements, reuse existing models, paired actual build screenshots. This patch makes no claim of a graphic overhaul.
7. Native secure credential persistence, real signup/account/device tests, Apple processing and group verification.

## Verification
Local: existing private-save SQL 27/27, social SQL 36/36; recovery SQL 32/32 with simulated identities (restore/replay/cross-account/lease/deleted-user/pruning); recovery client 10/10; account-save client 37/37.
CI additionally renders history and confirmation screens, runs existing touch/social/tutorial/campaign gates, exports Windows and signs/uploads iOS.
No actual iPhone/Windows device run or real multi-account signup is implied by these tests. Apple upload is not equivalent to processing or tester assignment.

## Final release verification — 27.09.2026, 00:26 Berlin
- Build commit: `789f99c3664d550fb878fdf41d38d2a207dd4271`.
- Final pipeline: https://github.com/alltagsprinzip-prog/glutwacht/actions/runs/36275562938 — all three jobs successful.
- iPhone: 0.13.1 (6.0.0), upload succeeded; delivery `ad90dfc6-bf9d-4350-88c3-1918dd0065f8`.
- Independent read-only Apple API check: processing VALID, internal_state IN_BETA_TESTING, group Glutwacht test assigned. Check run 36275562886, attempt 2, job 108498913662. No tester invitations or assignment mutations were performed.
- Windows artifact: https://github.com/alltagsprinzip-prog/glutwacht/actions/runs/36275562938/artifacts/10916827580 (exported; not run on physical Windows).
- CI render artifact 10917442173: restore explanation visually inspected after fixing overflow. Social/recovery UI 16/16; simulated touch 54/54; account 37/37; recovery client 10/10; native account 9/9; quests 16/16; campaign 68/68; tutorial 19/19. SQL checks 27/27 + 36/36 + 32/32.
- Additional local end-to-end mock with delayed requests: `tests3d/cloud_recovery_flow_suite.gd`, 6/6. Confirms final-save freeze, exactly-once restore, correct account file and hero retained. This is a mock, not a real-account/device test.
- Live: baseline coverage has no missing accounts; anon REST history request denied (401/42501); both new tables RLS-enabled with no direct authenticated reads.
- Older candidates 4.0.0 and 5.0.0 were superseded by the final dialog/production-freeze corrections. Use 6.0.0 for acceptance.
- `tools/check_testflight.py` is read-only. For future releases update TARGET_VERSION and TARGET_BUILD in its dedicated workflow; it does not compile, upload, assign, or notify.
- The full requested seven-part roadmap remains OPEN. This release completes only the recovery foundation, not the authoritative economy or Heroic Pop redesign. No real iPhone/Windows or real multi-account acceptance is claimed.
