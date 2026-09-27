-- Additive. Legacy private village snapshots never award competitive points.
-- Jadeprüfung I uses the same server-owned troops, opponents and rules for all.
create table if not exists glutwacht_private.ranked_matches (
 user_id uuid primary key references auth.users(id) on delete cascade,
 id uuid not null default gen_random_uuid(),
 state jsonb not null,
 last_request uuid,
 last_result jsonb,
 created_at timestamptz not null default now(),
 window_start timestamptz not null default now(),
 attempts integer not null default 1
);
create table if not exists glutwacht_private.ranked_scores (
 user_id uuid not null references glutwacht_private.social_profiles(user_id) on delete cascade,
 ruleset integer not null default 1,
 score integer not null check(score between 0 and 2000),
 best_at timestamptz not null default now(),
 primary key(user_id,ruleset)
);
create index if not exists ranked_scores_order on glutwacht_private.ranked_scores(ruleset,score desc,best_at);
alter table glutwacht_private.ranked_matches enable row level security;
alter table glutwacht_private.ranked_scores enable row level security;
revoke all on glutwacht_private.ranked_matches,glutwacht_private.ranked_scores from public,anon,authenticated;

-- Pure, inaccessible helpers; clients can send commands but cannot supply state.
create or replace function glutwacht_private.ranked_actor(i integer,k text,t text,x numeric,z numeric,hp integer,dmg integer,rng numeric,speed numeric)
returns jsonb language sql immutable set search_path='' as $$
 select jsonb_build_object('id',i,'kind',k,'team',t,'x',x,'z',z,'hp',hp,'max_hp',hp,'damage',dmg,'range',rng,'speed',speed,'cd',0,'attack_seq',0,'anim','Idle');
$$;
create or replace function glutwacht_private.ranked_initial() returns jsonb language plpgsql immutable set search_path='' as $$
declare a jsonb; lane integer; serial integer:=100;
begin
 a:=jsonb_build_array(glutwacht_private.ranked_actor(1,'hero','ally',-19,0,420,32,2,4.6));
 for lane in -1..1 loop
  a:=a||jsonb_build_array(glutwacht_private.ranked_actor(serial,'wall','enemy',4,lane*11,90,0,0,0));serial:=serial+1;
  a:=a||jsonb_build_array(glutwacht_private.ranked_actor(serial,'tower','enemy',13,lane*11,180,17,12,0));serial:=serial+1;
 end loop;
 a:=a||jsonb_build_array(glutwacht_private.ranked_actor(110,'hall','enemy',25,0,450,0,0,0));
 a:=a||jsonb_build_array(glutwacht_private.ranked_actor(111,'guard','enemy',14,-5,130,15,2,3));
 a:=a||jsonb_build_array(glutwacht_private.ranked_actor(112,'guard','enemy',14,5,130,15,2,3));
 return jsonb_build_object('ruleset',1,'round',0,'actors',a,'reserve',jsonb_build_object('melee',2,'archers',2,'shield',1,'siege',1),'heal',1,'rally',1,'done',false,'score',0,'won',false,'focus',0);
end;$$;

create or replace function glutwacht_private.ranked_simulate(s jsonb,cmd jsonb) returns jsonb language plpgsql set search_path='' as $$
declare
 a jsonb:=s->'actors'; frames jsonb:='[]'; actor jsonb; target jsonb; candidate jsonb;
 i integer;j integer; tick integer; best integer; count_alive integer; next_round integer:=(s->>'round')::integer+1;
 lane integer:=coalesce((cmd->>'lane')::integer,0); k text:=cmd->>'kind'; unit_kind text:=cmd->>'unit'; reserve integer;
 dist numeric; best_distance numeric; dx numeric; dz numeric; step numeric; hp numeric; dmg numeric; points integer:=0; victory boolean; complete boolean; buff numeric:=1;
begin
 if lane is null or lane not between -1 and 1 or k is null or k not in ('deploy','advance','heal','rally','finish') then raise exception 'invalid_command'; end if;
 if k='deploy' then
  if unit_kind is null or unit_kind not in ('melee','archers','shield','siege') then raise exception 'invalid_unit';end if;
  reserve:=(s->'reserve'->>unit_kind)::integer;
  if reserve<=0 then raise exception 'reserve_empty';end if;
  actor:=case unit_kind
   when 'melee' then glutwacht_private.ranked_actor(10+next_round,'melee','ally',-20,lane*11,150,22,2,4.4)
   when 'archers' then glutwacht_private.ranked_actor(10+next_round,'archer','ally',-20,lane*11,105,16,8,3.8)
   when 'shield' then glutwacht_private.ranked_actor(10+next_round,'shield','ally',-20,lane*11,300,14,2,3.3)
   else glutwacht_private.ranked_actor(10+next_round,'siege','ally',-20,lane*11,170,23,10,3.0) end;
  a:=a||jsonb_build_array(actor);s:=jsonb_set(s,array['reserve',unit_kind],to_jsonb(reserve-1));
 elsif k='heal' then
  if (s->>'heal')::integer<1 or (a->0->>'hp')::numeric<=0 or (a->0->>'hp')::numeric>=420 then raise exception 'heal_unavailable';end if;
  s:=jsonb_set(s,'{heal}','0');a:=jsonb_set(a,'{0,hp}',to_jsonb(least(420,(a->0->>'hp')::numeric+140)));
 elsif k='rally' then
  if (s->>'rally')::integer<1 then raise exception 'rally_unavailable';end if;
  s:=jsonb_set(s,'{rally}','0');buff:=1.5;
 end if;
 if k<>'finish' then
  -- Eight half-second ticks per order. Damage, targeting and movement all run
  -- here, against private server state, independent of the visual client.
  for tick in 1..8 loop
   for i in 0..jsonb_array_length(a)-1 loop
    actor:=a->i;
    if (actor->>'hp')::numeric<=0 then continue;end if;
    actor:=actor||jsonb_build_object('cd',greatest(0,(actor->>'cd')::numeric-.5),'anim','Idle');
    if (actor->>'damage')::numeric<=0 then a:=jsonb_set(a,array[i::text],actor);continue;end if;
    best:=-1;best_distance:=100000;
    for j in 0..jsonb_array_length(a)-1 loop
     candidate:=a->j;
     if candidate->>'team'=actor->>'team' or (candidate->>'hp')::numeric<=0 then continue;end if;
     dist:=sqrt(power((candidate->>'x')::numeric-(actor->>'x')::numeric,2)+power((candidate->>'z')::numeric-(actor->>'z')::numeric,2));
     if actor->>'team'='ally' and abs((candidate->>'z')::numeric-lane*11)<3 then dist:=dist-4;end if;
     if dist<best_distance then best_distance:=dist;best:=j;end if;
    end loop;
    if best>=0 then
     target:=a->best;dx:=(target->>'x')::numeric-(actor->>'x')::numeric;dz:=(target->>'z')::numeric-(actor->>'z')::numeric;dist:=sqrt(dx*dx+dz*dz);
     if dist>(actor->>'range')::numeric and (actor->>'speed')::numeric>0 then
      step:=least((actor->>'speed')::numeric*.5,greatest(0,dist-(actor->>'range')::numeric));
      -- Melee advances to the blocking structure; its footprint is the range.
      actor:=actor||jsonb_build_object('x',round((actor->>'x')::numeric+dx/dist*step,3),'z',round((actor->>'z')::numeric+dz/dist*step,3),'anim','Run');
     elsif dist<=(actor->>'range')::numeric and (actor->>'cd')::numeric<=0 then
      dmg:=(actor->>'damage')::numeric*case when actor->>'team'='ally' then buff else 1 end;
      if actor->>'kind'='siege' and target->>'kind'='wall' then dmg:=dmg*3;end if;
      hp:=greatest(0,(target->>'hp')::numeric-dmg);target:=jsonb_set(target,'{hp}',to_jsonb(hp));a:=jsonb_set(a,array[best::text],target);
      actor:=actor||jsonb_build_object('cd',case when actor->>'kind'='siege' then 2 else 1.5 end,'attack_seq',(actor->>'attack_seq')::integer+1,'anim','attack','target',best);
     end if;
    end if;
    a:=jsonb_set(a,array[i::text],actor);
   end loop;
   frames:=frames||jsonb_build_array(a);
  end loop;
 end if;
 select count(*) into count_alive from jsonb_array_elements(a) v where v->>'team'='enemy' and v->>'kind' in ('hall','wall','tower') and (v->>'hp')::numeric>0;
 victory:=count_alive=0;
 complete:=victory or next_round>=18 or k='finish' or (not exists(select 1 from jsonb_array_elements(a) v where v->>'team'='ally' and (v->>'hp')::numeric>0) and not exists(select 1 from jsonb_each_text(s->'reserve') r where r.value::integer>0));
 select coalesce(sum(floor((1-(v->>'hp')::numeric/(v->>'max_hp')::numeric)*case v->>'kind' when 'hall' then 300 when 'tower' then 150 when 'wall' then 50 else 0 end)),0) into points from jsonb_array_elements(a) v where v->>'team'='enemy';
 if victory then
  points:=points+500+greatest(0,18-next_round)*10;
  select points+floor(100*avg(greatest(0,(v->>'hp')::numeric)/(v->>'max_hp')::numeric)) into points from jsonb_array_elements(a) v where v->>'team'='ally';
 end if;
 s:=s||jsonb_build_object('actors',a,'round',next_round,'focus',lane,'done',complete,'won',victory,'score',points);
 return jsonb_build_object('state',s,'frames',frames);
end;$$;
revoke all on function glutwacht_private.ranked_actor(integer,text,text,numeric,numeric,integer,integer,numeric,numeric),glutwacht_private.ranked_initial(),glutwacht_private.ranked_simulate(jsonb,jsonb) from public,anon,authenticated;

create or replace function glutwacht_private.ranking(p_action text,p_args jsonb default '{}') returns jsonb language plpgsql security definer set search_path='' as $$
declare me uuid:=auth.uid(); m glutwacht_private.ranked_matches; response jsonb; s jsonb; page integer; rows jsonb; own jsonb; amount integer; request_id uuid;
begin
 if me is null or not exists(select 1 from auth.users where id=me) then raise exception 'authentication_required';end if;
 if p_args is null or jsonb_typeof(p_args)<>'object' or octet_length(p_args::text)>1024 then raise exception 'invalid_request';end if;
 if exists(select 1 from jsonb_object_keys(p_args) k where k not in ('page','match_id','request_id','round','kind','unit','lane')) then raise exception 'invalid_request';end if;
 if p_action='board' then
  page:=greatest(0,least(5000,coalesce((p_args->>'page')::integer,0)));
  with ranked as (select p.user_id,p.name,p.tag,s.score,s.best_at,rank() over(order by s.score desc) place from glutwacht_private.ranked_scores s join glutwacht_private.social_profiles p using(user_id) where s.ruleset=1)
  select coalesce(jsonb_agg(jsonb_build_object('name',name,'tag',tag,'score',score,'rank',place) order by score desc,best_at,user_id),'[]') into rows from (select * from ranked order by score desc,best_at,user_id limit 20 offset page*20) r;
  with ranked as (select s.user_id,p.name,p.tag,s.score,rank() over(order by s.score desc) place from glutwacht_private.ranked_scores s join glutwacht_private.social_profiles p using(user_id) where ruleset=1)
  select jsonb_build_object('name',name,'tag',tag,'score',score,'rank',place) into own from ranked where user_id=me;
  select count(*) into amount from glutwacht_private.ranked_scores where ruleset=1;
  return jsonb_build_object('rows',rows,'own',own,'page',page,'total',amount,'enrolled',exists(select 1 from glutwacht_private.social_profiles where user_id=me),'ruleset',1);
 end if;
 if not exists(select 1 from glutwacht_private.social_profiles where user_id=me) then raise exception 'profile_required';end if;
 perform pg_advisory_xact_lock(hashtextextended(me::text,73127));
 select * into m from glutwacht_private.ranked_matches where user_id=me for update;
 if p_action='start' then
  if m.id is not null and not (m.state->>'done')::boolean and m.created_at>now()-interval '20 minutes' then return jsonb_build_object('match_id',m.id,'state',m.state,'frames','[]'::jsonb);end if;
  if m.id is not null and m.window_start>now()-interval '1 hour' and m.attempts>=20 then raise exception 'trial_rate_limit';end if;
  s:=glutwacht_private.ranked_initial();
  insert into glutwacht_private.ranked_matches(user_id,state) values(me,s)
  on conflict(user_id) do update set id=gen_random_uuid(),state=excluded.state,last_request=null,last_result=null,created_at=now(),attempts=case when ranked_matches.window_start<now()-interval '1 hour' then 1 else ranked_matches.attempts+1 end,window_start=case when ranked_matches.window_start<now()-interval '1 hour' then now() else ranked_matches.window_start end returning * into m;
  return jsonb_build_object('match_id',m.id,'state',m.state,'frames','[]'::jsonb);
 elsif p_action='turn' then
  if m.id is null or m.id is distinct from (p_args->>'match_id')::uuid then raise exception 'match_not_found';end if;
  request_id:=(p_args->>'request_id')::uuid;
  if request_id is null then raise exception 'invalid_request';end if;
  if m.last_request=request_id then return m.last_result;end if;
  if (m.state->>'done')::boolean then raise exception 'match_finished';end if;
  if m.created_at<now()-interval '20 minutes' then raise exception 'match_expired';end if;
  if (p_args->>'round')::integer is distinct from (m.state->>'round')::integer then raise exception 'stale_turn';end if;
  response:=glutwacht_private.ranked_simulate(m.state,p_args)||jsonb_build_object('match_id',m.id);
  update glutwacht_private.ranked_matches set state=response->'state',last_request=request_id,last_result=response where user_id=me;
  if (response->'state'->>'done')::boolean then
   insert into glutwacht_private.ranked_scores(user_id,score) values(me,(response->'state'->>'score')::integer)
   on conflict(user_id,ruleset) do update set score=excluded.score,best_at=now() where excluded.score>ranked_scores.score;
  end if;
  return response;
 elsif p_action='state' then return jsonb_build_object('match_id',m.id,'state',m.state,'frames','[]'::jsonb);
 else raise exception 'unknown_action';end if;
end;$$;
revoke all on function glutwacht_private.ranking(text,jsonb) from public,anon;
grant execute on function glutwacht_private.ranking(text,jsonb) to authenticated;
create or replace function public.glutwacht_ranking(p_action text,p_args jsonb default '{}') returns jsonb language sql security invoker set search_path='' as $$select glutwacht_private.ranking(p_action,p_args);$$;
revoke all on function public.glutwacht_ranking(text,jsonb) from public,anon;
grant execute on function public.glutwacht_ranking(text,jsonb) to authenticated;

create or replace function glutwacht_private.clan_directory(p_args jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare me uuid:=auth.uid(); q text; result jsonb;
begin
 if me is null or not exists(select 1 from auth.users where id=me) then raise exception 'authentication_required';end if;
 perform glutwacht_private.social('state','{}'); -- Existing authentication and rate limit.
 q:=left(btrim(coalesce(p_args->>'query','')),24);
 select coalesce(jsonb_agg(row_to_json(c)),'[]') into result from (
  select c.id,c.name,c.description,p.name owner_name,p.tag owner_tag,(select count(*) from glutwacht_private.clan_members cm where cm.clan_id=c.id) members
  from glutwacht_private.clans c join glutwacht_private.clan_members m on m.clan_id=c.id and m.role='owner' join glutwacht_private.social_profiles p on p.user_id=m.user_id
  where (q='' or position(lower(q) in lower(c.name))>0) and not exists(select 1 from glutwacht_private.social_blocks b where (b.blocker=me and b.blocked=m.user_id) or (b.blocker=m.user_id and b.blocked=me))
  order by c.created_at limit 30
 ) c;
 return jsonb_build_object('clans',result);
end;$$;
revoke all on function glutwacht_private.clan_directory(jsonb) from public,anon;
grant execute on function glutwacht_private.clan_directory(jsonb) to authenticated;
create or replace function public.glutwacht_social(p_action text,p_args jsonb default '{}') returns jsonb language sql security invoker set search_path='' as $$
 select case when p_action='find_clans' then glutwacht_private.clan_directory(p_args) else glutwacht_private.social(p_action,p_args) end;
$$;
revoke all on function public.glutwacht_social(text,jsonb) from public,anon;
grant execute on function public.glutwacht_social(text,jsonb) to authenticated;
