# Account reliability and onboarding milestone

## Requirements
Preserve existing schema 7 villages; fix automatic account persistence and load; onboarding with one-time hero choice; modern icons, clearer upgrade previews, water and vessels; remove mail HUD; shareable test and fresh builds on reload.

## Implementation
Browser session persisted separately from exports. Account-owned local save plus revision/pending request sidecar; auto restore verifies Auth identity, fetches own row, resumes unsynced local data only at matching revision. Divergent local/cloud snapshots require explicit choice and offer a local backup download. Autosave every five seconds when dirty, local backups every fifteen seconds and after actions. Network errors retry exact idempotent payload; revision conflicts stop automation; another device lease waits ninety seconds. Logout first uploads and remains signed in if saving fails.
New villages persist completed tutorial actions; old villages with a hero skip onboarding. No added tutorial reward and no double rewards. Hero immutable. Current unlock rules preserved. Modern generated wood/stone/gold/wall atlas, blue-white UI, individual upgrade benefit rows, scrollable progression, removed mail action, animated river and two original 3D sailboats.

## Validation so far
187 rule/save tests; 37 account tests; 19 new onboarding/retry checks; 142 HUD layout checks. Local rendering unavailable under current sandbox (X11 socket creation blocked); render/WebGL checks run in existing GitHub CI. Actual two-device and new-account email interaction remain untested. Server economy remains client-authoritative.
Supabase redirect allowlist added exact owned test URL /v08/game.html; existing address preserved. Security advisor: leaked-password protection warning (no RLS warning); no schema changes made.

## Remaining release steps
Review CI rendered screenshots; finish cache versioning and publish same origin/path. Confirm test audience supports link sharing. Update PROJECT_STATE with final code and deployment identifiers. No completed deployment claim before terminal success.
