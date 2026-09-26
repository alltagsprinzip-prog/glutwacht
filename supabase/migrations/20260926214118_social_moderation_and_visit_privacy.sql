-- Blocking must not prevent legitimate clan moderation. Whitelist every shared layout field.
create or replace function glutwacht_private.social(p_action text,p_args jsonb default '{}')
returns jsonb language plpgsql security definer set search_path='' as $$
declare
 me uuid:=auth.uid(); other uuid; cid uuid; myrole text; theirrole text;
 v_name text; v_body text; mid uuid; v_snapshot jsonb; v_profile jsonb;
 v_members jsonb; v_clan jsonb; v_messages jsonb; v_friends jsonb; v_incoming jsonb; v_outgoing jsonb; v_invites jsonb; v_blocks jsonb;
begin
 if me is null or not exists(select 1 from auth.users where id=me) then raise exception 'authentication_required'; end if;
 if p_args is null or jsonb_typeof(p_args)<>'object' or octet_length(p_args::text)>4096 then raise exception 'invalid_request'; end if;
 -- Small private test population: serializes relationship changes and capacity checks.
 -- Replace with ordered per-clan/per-user locks before large-scale release.
 perform pg_advisory_xact_lock(731260926);
 insert into glutwacht_private.social_rate(user_id) values(me) on conflict do nothing;
 update glutwacht_private.social_rate set hits=case when window_start<now()-interval '1 minute' then 1 else hits+1 end,
 window_start=case when window_start<now()-interval '1 minute' then now() else window_start end where user_id=me;
 if (select hits from glutwacht_private.social_rate where user_id=me)>60 then raise exception 'rate_limit'; end if;
 if p_action='enroll' then
  v_name:=btrim(p_args->>'name');
  if v_name is null or char_length(v_name) not between 2 and 24 or v_name ~ '[[:cntrl:]]' then raise exception 'invalid_name'; end if;
  insert into glutwacht_private.social_profiles(user_id,name) values(me,v_name) on conflict(user_id) do update set name=excluded.name;
 elsif not exists(select 1 from glutwacht_private.social_profiles where user_id=me) then
  return jsonb_build_object('enrolled',false);
 end if;
 select clan_id,role into cid,myrole from glutwacht_private.clan_members where user_id=me;
 if p_args ? 'tag' then
  select user_id into other from glutwacht_private.social_profiles where tag=upper(replace(btrim(p_args->>'tag'),'#',''));
  if other is null then raise exception 'player_not_found'; end if;
  if other=me then raise exception 'cannot_target_self'; end if;
  if p_action not in ('unblock','block','report','kick','promote','demote','transfer') and exists(select 1 from glutwacht_private.social_blocks where (blocker=me and blocked=other) or (blocker=other and blocked=me)) then raise exception 'player_unavailable'; end if;
 end if;
 if p_action in ('search','request','accept','remove','block','unblock','report','visit','invite','kick','promote','demote','transfer') and other is null then raise exception 'invalid_request'; end if;
 case p_action
 when 'search' then
  return (select jsonb_build_object('player',jsonb_build_object('tag',tag,'name',name)) from glutwacht_private.social_profiles where user_id=other);
 when 'request' then
  if (select count(*) from glutwacht_private.friendships where sender=me or recipient=me)>=100 then raise exception 'friend_limit'; end if;
  if (select count(*) from glutwacht_private.friendships where recipient=other or sender=other)>=100 then raise exception 'friend_limit'; end if;
  insert into glutwacht_private.friendships(sender,recipient) values(me,other) on conflict do nothing;
 when 'accept' then
  update glutwacht_private.friendships set accepted=true where sender=other and recipient=me;
  if not found then raise exception 'request_not_found'; end if;
 when 'remove' then delete from glutwacht_private.friendships where (sender=me and recipient=other) or (sender=other and recipient=me);
 when 'block' then
  insert into glutwacht_private.social_blocks values(me,other) on conflict do nothing;
  delete from glutwacht_private.friendships where (sender=me and recipient=other) or (sender=other and recipient=me);
  delete from glutwacht_private.clan_invites where (sender=me and recipient=other) or (sender=other and recipient=me);
 when 'unblock' then delete from glutwacht_private.social_blocks where blocker=me and blocked=other;
 when 'visit' then
  if not exists(select 1 from glutwacht_private.friendships where accepted and ((sender=me and recipient=other) or (sender=other and recipient=me)))
   and not exists(select 1 from glutwacht_private.clan_members where clan_id=cid and user_id=other) then raise exception 'visit_forbidden'; end if;
  select snapshot into v_snapshot from public.player_saves where user_id=other;
  if v_snapshot is null then raise exception 'village_unavailable'; end if;
  -- Only visible layout is shared, never credentials, resource balances or full saves.
  return jsonb_build_object('village',jsonb_build_object('version',7,'hall',v_snapshot->'hall','barracks',v_snapshot->'barracks','smithy',v_snapshot->'smithy','hero',v_snapshot->'hero','hero_id',v_snapshot->'hero','structures',coalesce((select jsonb_agg(jsonb_build_object('uid',item->'uid','kind',item->'kind','level',item->'level','x',item->'x','z',item->'z','rotation',coalesce(item->'rotation','0'::jsonb))) from jsonb_array_elements(v_snapshot->'structures') item),'[]'::jsonb),'core_positions',coalesce((select jsonb_object_agg(key,jsonb_build_object('x',value->'x','z',value->'z')) from jsonb_each(coalesce(v_snapshot->'core_positions','{}'::jsonb)) where key in ('hall','barracks','smithy')),'{}'::jsonb)), 'name',(select name from glutwacht_private.social_profiles where user_id=other));
 when 'create_clan' then
  if cid is not null then raise exception 'already_in_clan'; end if;
  v_name:=btrim(p_args->>'name');v_body:=btrim(coalesce(p_args->>'description',''));
  if v_name is null or char_length(v_name) not between 3 and 24 or char_length(v_body)>180 or v_name ~ '[[:cntrl:]]' then raise exception 'invalid_name'; end if;
  insert into glutwacht_private.clans(name,description) values(v_name,v_body) returning id into cid;
  insert into glutwacht_private.clan_members values(me,cid,'owner',now());myrole:='owner';
 when 'invite' then
  if cid is null or myrole not in ('owner','officer') then raise exception 'role_required'; end if;
  if exists(select 1 from glutwacht_private.clan_members where user_id=other) then raise exception 'already_in_clan'; end if;
  delete from glutwacht_private.clan_invites where clan_id=cid and created_at<now()-interval '7 days';
  if (select count(*) from glutwacht_private.clan_invites where clan_id=cid)>=30 then raise exception 'invite_limit'; end if;
  insert into glutwacht_private.clan_invites(clan_id,recipient,sender) values(cid,other,me) on conflict do nothing;
 when 'join' then
  if cid is not null then raise exception 'already_in_clan'; end if;
  select i.clan_id into cid from glutwacht_private.clan_invites i where i.recipient=me and i.clan_id=(p_args->>'clan_id')::uuid and i.created_at>now()-interval '7 days'
  and exists(select 1 from glutwacht_private.clan_members m where m.clan_id=i.clan_id and m.user_id=i.sender and m.role in ('owner','officer'))
  and not exists(select 1 from glutwacht_private.social_blocks b where (b.blocker=me and b.blocked=i.sender) or (b.blocker=i.sender and b.blocked=me));
  if cid is null then raise exception 'invite_not_found'; end if;
  if (select count(*) from glutwacht_private.clan_members where clan_id=cid)>=30 then raise exception 'clan_full'; end if;
  insert into glutwacht_private.clan_members values(me,cid,'member',now());
  delete from glutwacht_private.clan_invites where recipient=me;myrole:='member';
 when 'decline_invite' then delete from glutwacht_private.clan_invites where recipient=me and clan_id=(p_args->>'clan_id')::uuid;
 when 'leave' then
  if cid is null then raise exception 'clan_required'; end if;
  if myrole='owner' and (select count(*) from glutwacht_private.clan_members where clan_id=cid)>1 then raise exception 'transfer_first'; end if;
  delete from glutwacht_private.clan_invites where sender=me;
  delete from glutwacht_private.clan_members where user_id=me;
  if myrole='owner' then delete from glutwacht_private.clans where id=cid;end if;
  cid:=null;myrole:=null;
 when 'kick','promote','demote','transfer' then
  select role into theirrole from glutwacht_private.clan_members where user_id=other and clan_id=cid;
  if cid is null or theirrole is null or myrole not in ('owner','officer') then raise exception 'role_required'; end if;
  if p_action='kick' then
   if theirrole='owner' or (myrole='officer' and theirrole<>'member') then raise exception 'role_required'; end if;
   delete from glutwacht_private.clan_members where user_id=other;
  else
   if myrole<>'owner' then raise exception 'role_required'; end if;
   if p_action='transfer' then update glutwacht_private.clan_members set role='officer' where user_id=me;myrole:='officer';end if;
   update glutwacht_private.clan_members set role=case p_action when 'transfer' then 'owner' when 'promote' then 'officer' else 'member' end where user_id=other;
  end if;
  delete from glutwacht_private.clan_invites where sender=other;
 when 'chat' then
  if cid is null then raise exception 'clan_required'; end if;
  v_body:=btrim(p_args->>'body');
  if v_body is null or char_length(v_body) not between 1 and 400 or v_body ~ '[[:cntrl:]]' then raise exception 'invalid_message'; end if;
  -- The client retains this UUID for retry after transport failure.
  mid:=(p_args->>'request_id')::uuid;
  if mid is null then raise exception 'invalid_request'; end if;
  if exists(select 1 from glutwacht_private.clan_messages where id=mid and sender=me and clan_id=cid and body=v_body) then null;
  else
   if exists(select 1 from glutwacht_private.clan_messages where sender=me and created_at>now()-interval '3 seconds') then raise exception 'chat_rate_limit'; end if;
   insert into glutwacht_private.clan_messages(id,clan_id,sender,body) values(mid,cid,me,v_body);
  end if;
  delete from glutwacht_private.clan_messages where clan_id=cid and created_at<now()-interval '30 days';
 when 'report' then
  v_body:=btrim(p_args->>'reason');
  if v_body is null or char_length(v_body) not between 3 and 300 then raise exception 'invalid_message'; end if;
  if (select count(*) from glutwacht_private.social_reports where reporter=me and created_at>now()-interval '1 day')>=5 then raise exception 'report_limit'; end if;
  mid:=nullif(p_args->>'message_id','')::uuid;
  if mid is not null and not exists(select 1 from glutwacht_private.clan_messages where id=mid and sender=other and clan_id=cid) then raise exception 'message_not_found'; end if;
  insert into glutwacht_private.social_reports(reporter,target,message_id,reason,evidence) values(me,other,mid,v_body,(select body from glutwacht_private.clan_messages where id=mid));
 when 'state','enroll' then null;
 else raise exception 'unknown_action';
 end case;
 select jsonb_build_object('name',name,'tag',tag) into v_profile from glutwacht_private.social_profiles where user_id=me;
 select coalesce(jsonb_agg(jsonb_build_object('name',p.name,'tag',p.tag) order by p.name),'[]') into v_friends from glutwacht_private.friendships f join glutwacht_private.social_profiles p on p.user_id=case when f.sender=me then f.recipient else f.sender end where f.accepted and (f.sender=me or f.recipient=me);
 select coalesce(jsonb_agg(jsonb_build_object('name',p.name,'tag',p.tag)),'[]') into v_incoming from glutwacht_private.friendships f join glutwacht_private.social_profiles p on p.user_id=f.sender where f.recipient=me and not f.accepted;
 select coalesce(jsonb_agg(jsonb_build_object('name',p.name,'tag',p.tag)),'[]') into v_outgoing from glutwacht_private.friendships f join glutwacht_private.social_profiles p on p.user_id=f.recipient where f.sender=me and not f.accepted;
 select coalesce(jsonb_agg(jsonb_build_object('name',p.name,'tag',p.tag)),'[]') into v_blocks from glutwacht_private.social_blocks b join glutwacht_private.social_profiles p on p.user_id=b.blocked where b.blocker=me;
 select coalesce(jsonb_agg(jsonb_build_object('id',c.id,'name',c.name,'description',c.description)),'[]') into v_invites from glutwacht_private.clan_invites i join glutwacht_private.clans c on c.id=i.clan_id where i.recipient=me and i.created_at>now()-interval '7 days';
 select jsonb_build_object('id',id,'name',name,'description',description,'role',myrole) into v_clan from glutwacht_private.clans where id=cid;
 select coalesce(jsonb_agg(jsonb_build_object('name',p.name,'tag',p.tag,'role',m.role) order by m.joined_at),'[]') into v_members from glutwacht_private.clan_members m join glutwacht_private.social_profiles p on p.user_id=m.user_id where m.clan_id=cid;
 select coalesce(jsonb_agg(row_to_json(msg) order by msg.created_at),'[]') into v_messages from (select m.id,m.body,m.created_at,p.name,p.tag from glutwacht_private.clan_messages m join glutwacht_private.social_profiles p on p.user_id=m.sender where m.clan_id=cid and not exists(select 1 from glutwacht_private.social_blocks b where (b.blocker=me and b.blocked=m.sender) or (b.blocker=m.sender and b.blocked=me)) order by m.created_at desc limit 50) msg;
 return jsonb_build_object('enrolled',true,'me',v_profile,'friends',v_friends,'incoming',v_incoming,'outgoing',v_outgoing,'blocks',v_blocks,'clan',v_clan,'members',v_members,'invitations',v_invites,'messages',v_messages);
end; $$;
