-- Private, unranked account saves. Never use these client-provided snapshots for PvP.
create table if not exists public.player_saves (
 user_id uuid primary key references auth.users(id) on delete cascade,
 revision bigint not null default 0 check (revision >= 0),
 snapshot jsonb not null,
 last_request uuid,
 lease_id uuid,
 lease_until timestamptz,
 updated_at timestamptz not null default now(),
 constraint snapshot_size check (octet_length(snapshot::text) <= 1048576),
 constraint snapshot_object check (jsonb_typeof(snapshot) = 'object')
);
alter table public.player_saves enable row level security;
revoke all on public.player_saves from anon, authenticated;
grant select on public.player_saves to authenticated;
create policy read_own_save on public.player_saves for select to authenticated using (user_id = (select auth.uid()));

-- Every write is serialized per authenticated account. Revision + short lease
-- prevent a second device from silently overwriting newer progress.
create schema if not exists glutwacht_private;
revoke all on schema glutwacht_private from public, anon;
grant usage on schema glutwacht_private to authenticated;

create or replace function glutwacht_private.save_private_village(
 p_snapshot jsonb, p_revision bigint, p_request uuid, p_device uuid
) returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_uid uuid := auth.uid(); v_row public.player_saves; v_now timestamptz := clock_timestamp();
begin
 if v_uid is null then raise exception 'authentication_required'; end if;
 if p_request is null or p_device is null or p_revision is null or p_revision < 0 then raise exception 'invalid_request'; end if;
 if p_snapshot is null or jsonb_typeof(p_snapshot) <> 'object' or octet_length(p_snapshot::text)>1048576 or p_snapshot->>'version' is distinct from '7' then raise exception 'invalid_snapshot'; end if;
 perform pg_advisory_xact_lock(hashtextextended(v_uid::text,0));
 v_now := clock_timestamp();
 select * into v_row from public.player_saves where user_id=v_uid for update;
 if found then
  if v_row.last_request=p_request then
   if v_row.snapshot<>p_snapshot or v_row.lease_id<>p_device then raise exception 'request_reused'; end if;
   return jsonb_build_object('revision',v_row.revision);
  end if;
  if v_row.revision<>p_revision then raise exception 'revision_conflict'; end if;
  if v_row.lease_id<>p_device and v_row.lease_until>v_now then raise exception 'other_device_active'; end if;
  update public.player_saves set snapshot=p_snapshot, revision=revision+1,last_request=p_request,
   lease_id=p_device,lease_until=v_now+interval '90 seconds',updated_at=v_now where user_id=v_uid returning * into v_row;
 else
  if p_revision<>0 then raise exception 'revision_conflict'; end if;
  insert into public.player_saves(user_id,snapshot,revision,last_request,lease_id,lease_until)
   values(v_uid,p_snapshot,1,p_request,p_device,v_now+interval '90 seconds') returning * into v_row;
 end if;
 return jsonb_build_object('revision',v_row.revision);
end; $$;
revoke all on function glutwacht_private.save_private_village(jsonb,bigint,uuid,uuid) from public,anon;
grant execute on function glutwacht_private.save_private_village(jsonb,bigint,uuid,uuid) to authenticated;

-- Public entry point stays invoker; the tightly scoped privileged implementation
-- is not in an exposed schema. Only it can mutate rows, always for auth.uid().
create or replace function public.save_private_village(
 p_snapshot jsonb, p_revision bigint, p_request uuid, p_device uuid
) returns jsonb language sql security invoker set search_path = '' as $$
 select glutwacht_private.save_private_village(p_snapshot,p_revision,p_request,p_device);
$$;
revoke all on function public.save_private_village(jsonb,bigint,uuid,uuid) from public,anon;
grant execute on function public.save_private_village(jsonb,bigint,uuid,uuid) to authenticated;
