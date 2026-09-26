# Private-save database regression suite

Run `npm ci --ignore-scripts && npm test` in this directory (Node 22).
PGlite 0.5.8 executes the actual PostgreSQL migration and RLS/function code in memory. The test fixture supplies only `auth.users`, the two API roles and an `auth.uid()` function backed by the test session claim.

27 checks cover three separate owners, explicit foreign UUID lookups, forbidden direct writes, idempotent retries, request reuse, revisions, lease handoff, invalid/missing schemas, payload size, anonymous callers and the invoker wrapper.

This is NOT a live Supabase Auth/PostgREST test, and PGlite's single connection does not prove concurrent multi-device locking or 10/25-player capacity. Those remain live acceptance gates. No real account or email is created by this suite.
