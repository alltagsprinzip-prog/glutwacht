import {PGlite} from '@electric-sql/pglite';
import {readFileSync,readdirSync,mkdirSync,writeFileSync} from 'node:fs';
import {randomUUID} from 'node:crypto';
import assert from 'node:assert/strict';
const db=new PGlite();let checks=0;const ids=[randomUUID(),randomUUID()];
const check=(v,n)=>{assert.ok(v,n);checks++};
const login=async(i)=>{await db.exec('reset role');await db.query("select set_config('request.jwt.claim.sub',$1,false)",[ids[i]||'']);await db.exec('set role authenticated')};
const call=async(a,p={})=>(await db.query('select public.glutwacht_live_trial($1,$2::jsonb) r',[a,JSON.stringify(p)])).rows[0].r;
const old=async(a,p={})=>(await db.query('select public.glutwacht_ranking($1,$2::jsonb) r',[a,JSON.stringify(p)])).rows[0].r;
const input=(r,inputs)=>({match_id:r.match_id,request_id:randomUUID(),tick:r.state.tick,inputs});
try{
 await db.exec(`create role anon;create role authenticated;create schema auth;create table auth.users(id uuid primary key);create function auth.uid() returns uuid language sql stable as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;grant usage on schema auth to anon,authenticated;grant execute on function auth.uid() to anon,authenticated;`);
 for(const id of ids)await db.query('insert into auth.users values($1)',[id]);
 await db.exec(readFileSync(new URL('../migrations/001_private_saves.sql',import.meta.url),'utf8'));
 const dir=new URL('../../supabase/migrations/',import.meta.url);
 for(const f of readdirSync(dir).filter(f=>f.endsWith('.sql')).sort())await db.exec(readFileSync(new URL(f,dir),'utf8'));
 for(let i=0;i<2;i++){await login(i);await db.query("select public.glutwacht_social('enroll',$1::jsonb)",[JSON.stringify({name:'Live QA '+i})])}
 await login(0);let legacy=await old('start');legacy=await old('turn',{match_id:legacy.match_id,request_id:randomUUID(),round:0,kind:'deploy',unit:'shield',lane:0});
 let resumed=await call('start');check(resumed.match_id===legacy.match_id&&resumed.state.tick===40,'legacy trial retains identity and elapsed time');
 check(JSON.stringify(resumed.state.actors)===JSON.stringify(legacy.state.actors)&&resumed.state.reserve.shield===0,'legacy HP and deployed troops preserved');
 await db.exec('reset role');await db.query("update glutwacht_private.ranked_matches set created_at=now()-interval '90 seconds',state=jsonb_set(state,'{live_started_at}',to_jsonb(now()-interval '90 seconds')) where user_id=$1",[ids[0]]);await login(0);resumed=await call('input',input(resumed,[{finish:true}]));check(resumed.state.done,'explicit finish saved');
 let r=await call('start');check(!r.state.hero_deployed&&r.state.tick===0,'new hero must be placed');const initial=structuredClone(r.state);
 const first=input(r,[{deploy:[{unit:'hero',x:-19,z:0},{unit:'siege',x:-10,z:0}],x:1,attack:true}]);r=await call('input',first);
 check(r.state.hero_deployed&&r.state.actors[0].x>-19&&r.state.reserve.siege===0,'hero placement and direct movement accepted');
 check(JSON.stringify(await call('input',first))===JSON.stringify(r),'exact retry is idempotent');
 await assert.rejects(()=>call('input',{...first,request_id:randomUUID()}),/stale_tick/);checks++;
 await assert.rejects(()=>call('input',{...input(r,[{}]),score:2000}),/invalid_request/);checks++;
 await assert.rejects(()=>call('input',input(r,[{x:50}])),/invalid_movement/);checks++;
 await assert.rejects(()=>call('input',input(r,[{actors:[]}])),/invalid_input/);checks++;
 await login(1);await assert.rejects(()=>call('input',input(r,[{}])),/match_not_found/);checks++;await login(0);
 await db.exec('reset role');await db.query("update glutwacht_private.ranked_matches set created_at=now()-interval '90 seconds',state=jsonb_set(state,'{live_started_at}',to_jsonb(now()-interval '90 seconds')) where user_id=$1",[ids[0]]);await login(0);
 const replay=[{input:first.inputs[0],state:structuredClone(r.state)}];
 const deployment=[{unit:'melee',x:-10,z:1},{unit:'melee',x:-10,z:-1},{unit:'archers',x:-12,z:1},{unit:'archers',x:-12,z:-1},{unit:'shield',x:-9,z:0}];
 for(let i=1;i<720&&!r.state.done;i++){
  const command={x:i<240?1:0,z:i>=240&&i<320?-.8:0,attack:true,target:-1};
  if(i===1)command.deploy=deployment;if(i===90)command.rally=true;if(i===130)command.heal=true;if(i===160)command.roll=true;
  r=await call('input',input(r,[command]));replay.push({input:command,state:structuredClone(r.state)});
 }
 check(r.state.done,'continuous time reaches authoritative completion');check(r.state.score>0,'manual combat causes real scored damage');
 let board=await old('board');check(board.own.score>=r.state.score,'existing best score retains max semantics');
 const stable=JSON.stringify(board);await assert.rejects(()=>call('input',input(r,[{finish:true}])),/match_finished/);checks++;
 check(JSON.stringify(await old('board'))===stable,'repeated completion cannot duplicate points');
 await db.exec('reset role');const wallCase=structuredClone(initial);wallCase.actors.forEach(a=>{if(['hall','tower'].includes(a.kind))a.hp=0});
 const won=(await db.query('select glutwacht_private.live_tick($1::jsonb,$2::jsonb) s',[JSON.stringify(wallCase),'{}'])).rows[0].s;
 check(won.won&&won.actors.some(a=>a.kind==='wall'&&a.hp>0),'intact walls do not prevent victory');
 await login(1);let fast=await call('start');
 await db.exec('reset role');await db.query("update glutwacht_private.ranked_matches set state=jsonb_set(state,'{live_started_at}',to_jsonb(now()-interval '1 second')) where user_id=$1",[ids[1]]);await login(1);
 fast=await call('input',input(fast,Array.from({length:20},()=>({}))));fast=await call('input',input(fast,Array.from({length:20},()=>({}))));
 check(fast.state.tick===40,'2x realtime ticks accepted within bounded retry allowance');
 await assert.rejects(()=>call('input',input(fast,Array.from({length:20},()=>({})))),/clock_ahead/);checks++;
 await login(-1);await assert.rejects(()=>call('start'),/authentication_required/);checks++;
 await db.exec('reset role;set role anon');await assert.rejects(()=>call('start'),/permission denied/);checks++;
 mkdirSync('logs/live-trial',{recursive:true});writeFileSync('logs/live-trial/replay.json',JSON.stringify({initial,replay,final:r.state}));
 console.log(`LIVE_TRIAL_DATABASE_TESTS ${checks}/${checks}; ${replay.length} realtime input ticks; score ${r.state.score}; won ${r.state.won}`);
}finally{await db.close()}
