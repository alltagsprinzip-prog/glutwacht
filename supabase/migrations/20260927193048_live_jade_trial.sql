-- Additive realtime input protocol. Village/account snapshots are untouched.
-- The existing match, reserves, HP, best score and retry identity are retained.
create or replace function glutwacht_private.live_radius(a jsonb) returns numeric language sql immutable set search_path='' as $$
 select case a->>'kind' when 'hall' then 3 when 'tower' then 1.5 when 'wall' then .75 else 0 end;
$$;
create or replace function glutwacht_private.live_move(a jsonb,nx numeric,nz numeric,actors jsonb) returns jsonb language plpgsql set search_path='' as $$
declare o jsonb; r numeric; dx numeric; dz numeric; d numeric;
begin
 nx:=greatest(-44,least(44,nx));nz:=greatest(-32,least(32,nz));
 for o in select value from jsonb_array_elements(actors) loop
  r:=glutwacht_private.live_radius(o);
  if r=0 or (o->>'hp')::numeric<=0 then continue;end if;
  r:=r+.35;dx:=nx-(o->>'x')::numeric;dz:=nz-(o->>'z')::numeric;d:=sqrt(dx*dx+dz*dz);
  if d<r then
   if d<.001 then dx:=(a->>'x')::numeric-(o->>'x')::numeric;dz:=(a->>'z')::numeric-(o->>'z')::numeric;d:=sqrt(dx*dx+dz*dz);end if;
   if d>0 then nx:=(o->>'x')::numeric+dx/d*r;nz:=(o->>'z')::numeric+dz/d*r;end if;
  end if;
 end loop;
 return a||jsonb_build_object('x',round(nx,3),'z',round(nz,3),'anim','Run');
end;$$;
create or replace function glutwacht_private.live_tick(s jsonb,c jsonb) returns jsonb language plpgsql set search_path='' as $$
declare a jsonb:=s->'actors';u jsonb;t jsonb;candidate jsonb;deployment jsonb;spec jsonb;key text;
 mx numeric:=coalesce((c->>'x')::numeric,0);mz numeric:=coalesce((c->>'z')::numeric,0);magnitude numeric;
 px numeric;pz numeric;dx numeric;dz numeric;dist numeric;best_distance numeric;step numeric;damage numeric;
 i integer;j integer;best integer;tick integer:=(s->>'tick')::integer+1;points integer:=0;objectives integer:=0;alive integer:=0;remaining integer:=0;count_allies integer:=0;life numeric:=0;
 buff numeric:=greatest(0,(s->>'buff')::numeric-.1);roll_cd numeric:=greatest(0,(s->>'roll')::numeric-.1);invul numeric:=greatest(0,(s->>'invul')::numeric-.1);
 deployed boolean:=(s->>'hero_deployed')::boolean;won boolean;done boolean;
begin
 if (s->>'done')::boolean then return s;end if;
 if jsonb_typeof(c)<>'object' or exists(select 1 from jsonb_object_keys(c) k where k not in ('x','z','attack','target','deploy','heal','rally','roll','finish')) then raise exception 'invalid_input';end if;
 if abs(mx)>1.01 or abs(mz)>1.01 then raise exception 'invalid_movement';end if;
 magnitude:=sqrt(mx*mx+mz*mz);if magnitude>1 then mx:=mx/magnitude;mz:=mz/magnitude;end if;
 if c ? 'deploy' and (jsonb_typeof(c->'deploy')<>'array' or jsonb_array_length(c->'deploy')>7) then raise exception 'invalid_deployment';end if;
 for deployment in select value from jsonb_array_elements(coalesce(c->'deploy','[]')) loop
  if jsonb_typeof(deployment)<>'object' or exists(select 1 from jsonb_object_keys(deployment) k where k not in ('unit','x','z')) then raise exception 'invalid_deployment';end if;
  key:=deployment->>'unit';px:=(deployment->>'x')::numeric;pz:=(deployment->>'z')::numeric;
  if px is null or pz is null or key is null or key not in ('hero','melee','archers','shield','siege') then raise exception 'invalid_deployment';end if;
  if abs(px)>44 or abs(pz)>32 or not(px<=-8 or px>=35 or abs(pz)>=24) then continue;end if;
  if key='hero' then
   if not deployed then deployed:=true;a:=jsonb_set(a,'{0}',(a->0)||jsonb_build_object('x',px,'z',pz));end if;
  elsif (s->'reserve'->>key)::integer>0 then
   u:=case key
    when 'melee' then glutwacht_private.ranked_actor(200+jsonb_array_length(a),'melee','ally',px,pz,150,22,2,4.4)
    when 'archers' then glutwacht_private.ranked_actor(200+jsonb_array_length(a),'archer','ally',px,pz,105,16,8,3.8)
    when 'shield' then glutwacht_private.ranked_actor(200+jsonb_array_length(a),'shield','ally',px,pz,300,14,2,3.3)
    else glutwacht_private.ranked_actor(200+jsonb_array_length(a),'siege','ally',px,pz,170,23,10,3) end;
   a:=a||jsonb_build_array(u);s:=jsonb_set(s,array['reserve',key],to_jsonb((s->'reserve'->>key)::integer-1));
  end if;
 end loop;
 u:=a->0;
 if deployed and (u->>'hp')::numeric>0 then
  if coalesce((c->>'heal')::boolean,false) and (s->>'heal')::integer>0 and (u->>'hp')::numeric<420 then
   s:=jsonb_set(s,'{heal}','0');u:=jsonb_set(u,'{hp}',to_jsonb(least(420,(u->>'hp')::numeric+140)));a:=jsonb_set(a,'{0}',u);
  end if;
  if coalesce((c->>'rally')::boolean,false) and (s->>'rally')::integer>0 then s:=jsonb_set(s,'{rally}','0');buff:=4;end if;
  if coalesce((c->>'roll')::boolean,false) and roll_cd<=.0001 then roll_cd:=2.5;invul:=.4;end if;
 end if;
 for i in 0..jsonb_array_length(a)-1 loop
  u:=a->i;
  if (u->>'hp')::numeric<=0 or (i=0 and not deployed) then continue;end if;
  u:=u||jsonb_build_object('cd',greatest(0,(u->>'cd')::numeric-.1),'anim','Idle');
  if (u->>'damage')::numeric<=0 then a:=jsonb_set(a,array[i::text],u);continue;end if;
  if i=0 and magnitude>.01 then
   step:=(u->>'speed')::numeric*.1*case when invul>0 then 2.6 else 1 end;
   u:=glutwacht_private.live_move(u,(u->>'x')::numeric+mx*step,(u->>'z')::numeric+mz*step,a);
  end if;
  best:=-1;best_distance:=100000;
  for j in 0..jsonb_array_length(a)-1 loop
   candidate:=a->j;
   if candidate->>'team'=u->>'team' or (candidate->>'hp')::numeric<=0 or (j=0 and not deployed) then continue;end if;
   dist:=sqrt(power((candidate->>'x')::numeric-(u->>'x')::numeric,2)+power((candidate->>'z')::numeric-(u->>'z')::numeric,2))-glutwacht_private.live_radius(candidate);
   if i=0 and coalesce((c->>'target')::integer,-1)=(candidate->>'id')::integer then dist:=dist-100;end if;
   if dist<best_distance then best_distance:=dist;best:=j;end if;
  end loop;
  if best>=0 then
   t:=a->best;dx:=(t->>'x')::numeric-(u->>'x')::numeric;dz:=(t->>'z')::numeric-(u->>'z')::numeric;magnitude:=sqrt(dx*dx+dz*dz);dist:=magnitude-glutwacht_private.live_radius(t);
   if i<>0 and dist>(u->>'range')::numeric and (u->>'speed')::numeric>0 then
    step:=least((u->>'speed')::numeric*.1,greatest(0,dist-(u->>'range')::numeric));
    if magnitude>0 then u:=glutwacht_private.live_move(u,(u->>'x')::numeric+dx/magnitude*step,(u->>'z')::numeric+dz/magnitude*step,a);end if;
   elsif dist<=(u->>'range')::numeric+.001 and (u->>'cd')::numeric<=.0001 and (i<>0 or coalesce((c->>'attack')::boolean,false)) then
    damage:=(u->>'damage')::numeric*case when u->>'team'='ally' and buff>0 then 1.5 else 1 end;
    if u->>'kind'='siege' and t->>'kind'='wall' then damage:=damage*3;end if;
    if not(best=0 and invul>0) then t:=jsonb_set(t,'{hp}',to_jsonb(greatest(0,(t->>'hp')::numeric-damage)));a:=jsonb_set(a,array[best::text],t);end if;
    u:=u||jsonb_build_object('cd',case when u->>'kind'='siege' then 2 else 1.5 end,'attack_seq',(u->>'attack_seq')::integer+1,'anim','attack','target',best);
   end if;
  end if;
  a:=jsonb_set(a,array[i::text],u);
 end loop;
 for u in select value from jsonb_array_elements(a) loop
  if u->>'team'='enemy' then
   if u->>'kind' in ('hall','tower') and (u->>'hp')::numeric>0 then objectives:=objectives+1;end if;
   points:=points+floor((1-(u->>'hp')::numeric/(u->>'max_hp')::numeric)*case u->>'kind' when 'hall' then 300 when 'tower' then 150 when 'wall' then 50 else 0 end);
  elsif (u->>'id')::integer<>1 or deployed then
   count_allies:=count_allies+1;life:=life+greatest(0,(u->>'hp')::numeric)/(u->>'max_hp')::numeric;
   if (u->>'hp')::numeric>0 then alive:=alive+1;end if;
  end if;
 end loop;
 select coalesce(sum(value::integer),0) into remaining from jsonb_each_text(s->'reserve');
 if not deployed then remaining:=remaining+1;end if;
 won:=objectives=0;done:=won or tick>=720 or coalesce((c->>'finish')::boolean,false) or (alive=0 and remaining=0);
 if won then points:=points+500+greatest(0,(720-tick)/40)*10+floor(100*life/greatest(1,count_allies));end if;
 return s||jsonb_build_object('actors',a,'tick',tick,'round',tick/40,'hero_deployed',deployed,'buff',buff,'roll',roll_cd,'invul',invul,'score',points,'won',won,'done',done);
end;$$;
revoke all on function glutwacht_private.live_radius(jsonb),glutwacht_private.live_move(jsonb,numeric,numeric,jsonb),glutwacht_private.live_tick(jsonb,jsonb) from public,anon,authenticated;

create or replace function glutwacht_private.live_trial(p_action text,p_args jsonb default '{}') returns jsonb language plpgsql security definer set search_path='' as $$
declare me uuid:=auth.uid();m glutwacht_private.ranked_matches;s jsonb;r jsonb;c jsonb;request_id uuid;count_inputs integer;
begin
 if me is null or not exists(select 1 from auth.users where id=me) then raise exception 'authentication_required';end if;
 if p_args is null or jsonb_typeof(p_args)<>'object' or octet_length(p_args::text)>32768 or exists(select 1 from jsonb_object_keys(p_args) k where k not in ('match_id','request_id','tick','inputs')) then raise exception 'invalid_request';end if;
 perform pg_advisory_xact_lock(hashtextextended(me::text,73127));
 if p_action='start' then
  r:=glutwacht_private.ranking('start','{}');s:=r->'state';
  if not coalesce((s->>'live')::boolean,false) then
   s:=s||jsonb_build_object('live',true,'tick',(s->>'round')::integer*40,'hero_deployed',(s->>'round')::integer>0,'buff',0,'roll',0,'invul',0,'started_tick',(s->>'round')::integer*40,'live_started_at',now());
   update glutwacht_private.ranked_matches set state=s,last_request=null,last_result=null where user_id=me;
  end if;
  return jsonb_build_object('match_id',r->'match_id','state',s);
 end if;
 select * into m from glutwacht_private.ranked_matches where user_id=me for update;
 if m.id is null or m.id is distinct from (p_args->>'match_id')::uuid then raise exception 'match_not_found';end if;
 if p_action<>'input' then raise exception 'unknown_action';end if;
 request_id:=(p_args->>'request_id')::uuid;
 if request_id is null then raise exception 'invalid_request';end if;
 if m.last_request=request_id then return m.last_result;end if;
 if (m.state->>'done')::boolean then raise exception 'match_finished';end if;
 if m.created_at<now()-interval '20 minutes' then raise exception 'match_expired';end if;
 if not coalesce((m.state->>'live')::boolean,false) or (p_args->>'tick')::integer is distinct from (m.state->>'tick')::integer then raise exception 'stale_tick';end if;
 if jsonb_typeof(p_args->'inputs') is distinct from 'array' then raise exception 'invalid_request';end if;
 count_inputs:=jsonb_array_length(p_args->'inputs');
 if count_inputs<1 or count_inputs>20 then raise exception 'invalid_request';end if;
 if (m.state->>'tick')::integer+count_inputs-coalesce((m.state->>'started_tick')::integer,0)>floor(extract(epoch from now()-coalesce((m.state->>'live_started_at')::timestamptz,m.created_at))*10)+20 then raise exception 'clock_ahead';end if;
 s:=m.state;
 for c in select value from jsonb_array_elements(p_args->'inputs') loop s:=glutwacht_private.live_tick(s,c);end loop;
 r:=jsonb_build_object('match_id',m.id,'state',s);
 update glutwacht_private.ranked_matches set state=s,last_request=request_id,last_result=r where user_id=me;
 if (s->>'done')::boolean then
  insert into glutwacht_private.ranked_scores(user_id,score) values(me,(s->>'score')::integer)
  on conflict(user_id,ruleset) do update set score=excluded.score,best_at=now() where excluded.score>ranked_scores.score;
 end if;
 return r;
end;$$;
revoke all on function glutwacht_private.live_trial(text,jsonb) from public,anon;
grant execute on function glutwacht_private.live_trial(text,jsonb) to authenticated;
create or replace function public.glutwacht_live_trial(p_action text,p_args jsonb default '{}') returns jsonb language sql security invoker set search_path='' as $$select glutwacht_private.live_trial(p_action,p_args);$$;
revoke all on function public.glutwacht_live_trial(text,jsonb) from public,anon;
grant execute on function public.glutwacht_live_trial(text,jsonb) to authenticated;

-- Older clients cannot advance the same live match through the legacy turn API.
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
  if coalesce((m.state->>'live')::boolean,false) then raise exception 'update_required';end if;
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
