-- Allow the requested 1x/2x control. Fixed simulation ticks still determine damage, duration and score.
-- The wall-clock envelope permits at most twice real time plus the existing retry allowance.
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
 if (m.state->>'tick')::integer+count_inputs-coalesce((m.state->>'started_tick')::integer,0)>floor(extract(epoch from now()-coalesce((m.state->>'live_started_at')::timestamptz,m.created_at))*20)+20 then raise exception 'clock_ahead';end if;
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
