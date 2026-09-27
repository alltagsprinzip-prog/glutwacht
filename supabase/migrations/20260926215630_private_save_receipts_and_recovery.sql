-- Recovery foundation. These are explicitly UNTRUSTED private PvE snapshots.
-- Neither archives nor successful receipts establish economic provenance.
lock table public.player_saves in share row exclusive mode;
create table glutwacht_private.save_receipts (
 user_id uuid not null references auth.users(id) on delete cascade,
 request_id uuid not null, device_id uuid not null, operation text not null,
 payload_hash text not null, revision bigint not null,
 created_at timestamptz not null default now(),
 primary key(user_id,request_id)
);
create table glutwacht_private.save_versions (
 user_id uuid not null references auth.users(id) on delete cascade,
 revision bigint not null, snapshot jsonb not null,
 reason text not null check(reason in ('baseline','checkpoint','before_restore')),
 created_at timestamptz not null default now(),
 primary key(user_id,revision)
);
alter table glutwacht_private.save_receipts enable row level security;
alter table glutwacht_private.save_versions enable row level security;
revoke all on glutwacht_private.save_receipts,glutwacht_private.save_versions from public,anon,authenticated;
-- Preserve exactly what exists at rollout; no coercion, clamping, or save rewrite.
insert into glutwacht_private.save_versions(user_id,revision,snapshot,reason,created_at)
 select user_id,revision,snapshot,'baseline',updated_at from public.player_saves
 on conflict do nothing;
insert into glutwacht_private.save_receipts(user_id,request_id,device_id,operation,payload_hash,revision)
 select user_id,last_request,lease_id,'save',encode(sha256(convert_to(snapshot::text,'UTF8')),'hex'),revision
 from public.player_saves where last_request is not null and lease_id is not null
 on conflict do nothing;

create or replace function glutwacht_private.save_private_village(
 p_snapshot jsonb,p_revision bigint,p_request uuid,p_device uuid
) returns jsonb language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid(); r public.player_saves; receipt glutwacht_private.save_receipts;
 t timestamptz; digest text;
begin
 if u is null or not exists(select 1 from auth.users where id=u) then raise exception 'authentication_required'; end if;
 if p_request is null or p_device is null or p_revision is null or p_revision<0 then raise exception 'invalid_request'; end if;
 if p_snapshot is null or jsonb_typeof(p_snapshot)<>'object' or octet_length(p_snapshot::text)>1048576 or p_snapshot->>'version' is distinct from '7' then raise exception 'invalid_snapshot'; end if;
 digest:=encode(sha256(convert_to(p_snapshot::text,'UTF8')),'hex');
 perform pg_advisory_xact_lock(hashtextextended(u::text,0));
 t:=clock_timestamp();
 select * into receipt from glutwacht_private.save_receipts where user_id=u and request_id=p_request;
 if found then
  if receipt.device_id<>p_device or receipt.operation<>'save' or receipt.payload_hash<>digest then raise exception 'request_reused'; end if;
  return jsonb_build_object('revision',receipt.revision,'head_revision',(select revision from public.player_saves where user_id=u),'replayed',true,'trust','private_pve');
 end if;
 select * into r from public.player_saves where user_id=u for update;
 if found then
  if r.revision<>p_revision then raise exception 'revision_conflict'; end if;
  if r.lease_id<>p_device and r.lease_until>t then raise exception 'other_device_active'; end if;
  if not exists(select 1 from glutwacht_private.save_versions where user_id=u and created_at>t-interval '30 minutes') then
   insert into glutwacht_private.save_versions values(u,r.revision,r.snapshot,'checkpoint',t) on conflict do nothing;
  end if;
  update public.player_saves set snapshot=p_snapshot,revision=revision+1,last_request=p_request,lease_id=p_device,lease_until=t+interval '90 seconds',updated_at=t where user_id=u returning * into r;
 else
  if p_revision<>0 then raise exception 'revision_conflict'; end if;
  insert into public.player_saves(user_id,snapshot,revision,last_request,lease_id,lease_until)
   values(u,p_snapshot,1,p_request,p_device,t+interval '90 seconds') returning * into r;
  insert into glutwacht_private.save_versions values(u,r.revision,r.snapshot,'baseline',t);
 end if;
 insert into glutwacht_private.save_receipts values(u,p_request,p_device,'save',digest,r.revision,t);
 -- Baseline never expires; retain 48 further checkpoints/restoration safety copies.
 delete from glutwacht_private.save_versions where user_id=u and reason<>'baseline' and revision not in
  (select revision from glutwacht_private.save_versions where user_id=u and reason<>'baseline' order by revision desc limit 48);
 return jsonb_build_object('revision',r.revision,'replayed',false,'trust','private_pve');
end; $$;
revoke all on function glutwacht_private.save_private_village(jsonb,bigint,uuid,uuid) from public,anon;

create or replace function glutwacht_private.private_save_history(
 p_action text,p_revision bigint default null,p_expected bigint default null,p_request uuid default null,p_device uuid default null
) returns jsonb language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid(); r public.player_saves; v glutwacht_private.save_versions; receipt glutwacht_private.save_receipts;
 t timestamptz; result jsonb;
begin
 if u is null or not exists(select 1 from auth.users where id=u) then raise exception 'authentication_required'; end if;
 if p_action='list' then
  select coalesce(jsonb_agg(jsonb_build_object('revision',revision,'created_at',created_at,'reason',reason,
   'name',left(snapshot->>'player_name',24),'hall',snapshot->'hall','gold',snapshot->'gold') order by revision desc),'[]'::jsonb)
   into result from glutwacht_private.save_versions where user_id=u;
  return jsonb_build_object('versions',result,'trust','private_pve');
 end if;
 if p_action<>'restore' or p_action is null or p_request is null or p_device is null or p_revision is null or p_expected is null or p_expected<0 then raise exception 'invalid_request'; end if;
 perform pg_advisory_xact_lock(hashtextextended(u::text,0));t:=clock_timestamp();
 select * into receipt from glutwacht_private.save_receipts where user_id=u and request_id=p_request;
 if found then
  if receipt.operation<>'restore' or receipt.device_id<>p_device or receipt.payload_hash<>p_revision::text then raise exception 'request_reused'; end if;
  return jsonb_build_object('revision',receipt.revision,'replayed',true);
 end if;
 select * into r from public.player_saves where user_id=u for update;
 if not found then raise exception 'save_not_found'; end if;
 if r.revision<>p_expected then raise exception 'revision_conflict'; end if;
 if r.lease_id<>p_device and r.lease_until>t then raise exception 'other_device_active'; end if;
 select * into v from glutwacht_private.save_versions where user_id=u and revision=p_revision;
 if not found then raise exception 'version_not_found'; end if;
 -- Recovery remains private. No economy, clan rewards, or social rows are changed.
 insert into glutwacht_private.save_versions values(u,r.revision,r.snapshot,'before_restore',t) on conflict do nothing;
 update public.player_saves set snapshot=v.snapshot,revision=revision+1,last_request=p_request,lease_id=p_device,lease_until=t+interval '90 seconds',updated_at=t where user_id=u returning * into r;
 insert into glutwacht_private.save_receipts values(u,p_request,p_device,'restore',p_revision::text,r.revision,t);
 delete from glutwacht_private.save_versions where user_id=u and reason<>'baseline' and revision not in
  (select revision from glutwacht_private.save_versions where user_id=u and reason<>'baseline' order by revision desc limit 48);
 return jsonb_build_object('revision',r.revision,'replayed',false);
end; $$;
revoke all on function glutwacht_private.private_save_history(text,bigint,bigint,uuid,uuid) from public,anon;
grant execute on function glutwacht_private.private_save_history(text,bigint,bigint,uuid,uuid) to authenticated;
create or replace function public.private_save_history(
 p_action text,p_revision bigint default null,p_expected bigint default null,p_request uuid default null,p_device uuid default null
) returns jsonb language sql security invoker set search_path='' as $$
 select glutwacht_private.private_save_history(p_action,p_revision,p_expected,p_request,p_device);
$$;
revoke all on function public.private_save_history(text,bigint,bigint,uuid,uuid) from public,anon;
grant execute on function public.private_save_history(text,bigint,bigint,uuid,uuid) to authenticated;
