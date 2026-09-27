import {PGlite} from '@electric-sql/pglite';
import {readFileSync,readdirSync,mkdirSync,writeFileSync} from 'node:fs';
import {randomUUID} from 'node:crypto';
import assert from 'node:assert/strict';
const db=new PGlite();let checks=0;
const ids=Array.from({length:24},()=>randomUUID());
const check=(x,t)=>{assert.ok(x,t);checks++;};
const login=async(i,role='authenticated')=>{await db.exec('reset role');await db.query("select set_config('request.jwt.claim.sub',$1,false)",[i===null?'':ids[i]]);await db.exec(`set role ${role}`);};
const call=async(action,args={})=>(await db.query('select public.glutwacht_ranking($1,$2::jsonb) result',[action,JSON.stringify(args)])).rows[0].result;
const social=async(action,args={})=>(await db.query('select public.glutwacht_social($1,$2::jsonb) result',[action,JSON.stringify(args)])).rows[0].result;
const reject=async(action,args,pattern)=>{await assert.rejects(()=>call(action,args),pattern);checks++;};
const turn=(r,kind='advance',unit='',lane=0)=>({match_id:r.match_id,round:r.state.round,request_id:randomUUID(),kind,...(unit?{unit}:{}),lane});
try{
 await db.exec(`create role anon;create role authenticated;create schema auth;create table auth.users(id uuid primary key);
 create function auth.uid() returns uuid language sql stable as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;
 grant usage on schema auth to anon,authenticated;grant execute on function auth.uid() to anon,authenticated;`);
 for(const id of ids)await db.query('insert into auth.users values($1)',[id]);
 await db.exec(readFileSync(new URL('../migrations/001_private_saves.sql',import.meta.url),'utf8'));
 const dir=new URL('../../supabase/migrations/',import.meta.url);
 for(const migration of readdirSync(dir).filter(x=>x.endsWith('.sql')).sort())await db.exec(readFileSync(new URL(migration,dir),'utf8'));
 await login(0);check((await call('board')).total===0,'empty board contains no fictional players');
 await reject('start',{},/profile_required/);
 const me=await social('enroll',{name:'QA erste Sitzung'});
 let a=await call('start');check(a.state.actors[0].hp===420,'server owns starting attributes');
 check((await call('start')).match_id===a.match_id,'duplicate start resumes same trial');
 await reject('turn',{...turn(a),score:999999},/invalid_request/);
 await assert.rejects(()=>db.query('update glutwacht_private.ranked_scores set score=2000'),/permission denied/);checks++;
 await assert.rejects(()=>db.query("select glutwacht_private.ranked_simulate('{}','{}')"),/permission denied/);checks++;
 const action=turn(a,'deploy','siege',0);a=await call('turn',action);
 check(a.state.reserve.siege===0,'deployment consumed exactly once on server');
 check(JSON.stringify(await call('turn',action))===JSON.stringify(a),'lost response retry returns same authoritative result');
 await reject('turn',{...action,request_id:randomUUID()},/stale_turn/);
 await login(1);await social('enroll',{name:'QA zweite Sitzung'});
 await reject('turn',turn(a),/match_not_found/);
 await login(0);a=await call('turn',turn(a,'finish'));check(a.state.done,'abort is an authoritative completion');
 await reject('turn',turn(a),/match_finished/);
 let board=await call('board');check(board.own.tag===me.me.tag&&board.rows.length===1,'own rank uses public tag only');
 await login(1);let b=await call('start');const replay=[b];
 const commands=[['deploy','shield',0],['deploy','siege',0],['deploy','archers',-1],['deploy','archers',1],['deploy','melee',-1],['deploy','melee',1]];
 for(let i=0;i<18&&!b.state.done;i++){
  const [kind,unit,lane]=commands[i]||[i===8?'rally':(i===10&&b.state.actors[0].hp>0&&b.state.actors[0].hp<420?'heal':'advance'),'',i%3-1];
  b=await call('turn',turn(b,kind,unit,lane));replay.push(b);
 }
 check(b.state.done&&b.state.score>a.state.score,'second account earns a real higher server-computed score');
 check(b.state.actors.some(x=>x.kind==='tower'&&x.hp<x.max_hp),'commands cause actual building damage');
 board=await call('board');check(board.own.rank===1&&board.rows[0].score===b.state.score,'ranking order and own rank refresh after completion');
 await login(0);board=await call('board');check(board.own.rank===2,'first account sees its changed rank');
 const clan=await social('create_clan',{name:'Jadewacht QA',description:'Isolierter Datenbanktest'});
 await login(1);const found=await social('find_clans',{query:'Jadewacht'});check(found.clans[0].id===clan.clan.id&&found.clans[0].owner_tag===me.me.tag,'clan lookup exposes contact and real member count');
 check(!JSON.stringify(board).includes(ids[0])&&!JSON.stringify(board).includes('@'),'leaderboard exposes no auth IDs or private email');
 // Distinct authenticated identities in the isolated database verify ties,
 // pagination, own rank outside the first page and no direct score setter.
 for(let i=2;i<24;i++){
  await login(i);await social('enroll',{name:'Isolierter Seitentest '+i});let r=await call('start');await call('turn',turn(r,'finish'));
 }
 await login(23);board=await call('board',{page:1});check(board.rows.length===4&&board.total===24&&board.own!==null,'paged board retains own rank outside page one');
 check(board.rows.every(x=>x.rank===board.own.rank),'equal scores receive equal ranks');
 await db.exec('reset role');await db.exec(readFileSync(new URL('20260927165402_verified_tactics_and_clan_search.sql',dir),'utf8'));
 await login(23);check((await call('board')).total===24,'repeating additive migration retains every rank and account');
 await login(null);await reject('board',{},/authentication_required/);
 await login(null,'anon');await reject('board',{},/permission denied/);
 const out=new URL('../../logs/ranking/',import.meta.url);mkdirSync(out,{recursive:true});
 writeFileSync(new URL('server-replay.json',out),JSON.stringify(replay));
 console.log(`RANKING_DATABASE_TESTS ${checks}/${checks}; verified scores ${a.state.score} / ${b.state.score}; victory ${b.state.won}`);
}finally{await db.close();}
