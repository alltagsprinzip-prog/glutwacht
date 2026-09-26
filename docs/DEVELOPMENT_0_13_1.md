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
