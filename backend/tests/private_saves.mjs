import {PGlite} from '@electric-sql/pglite';
import {readFileSync} from 'node:fs';
import assert from 'node:assert/strict';
const db=new PGlite();
let checks=0;
const check=(value,label)=>{assert.ok(value,label);checks++;};
const reject=async(fn,pattern)=>{await assert.rejects(fn,pattern);checks++;};
const ids=['11111111-1111-4111-8111-111111111111','22222222-2222-4222-8222-222222222222','33333333-3333-4333-8333-333333333333'];
const device='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const second='bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
let seq=0;
const request=()=>`00000000-0000-4000-8000-${String(++seq).padStart(12,'0')}`;
const login=async(uid,role='authenticated')=>{
 await db.exec('reset role');
 await db.query("select set_config('request.jwt.claim.sub',$1,false)",[uid]);
 await db.exec(`set role ${role}`);
};
const save=async(snapshot,revision=0,req=request(),dev=device)=>(await db.query(
 'select public.save_private_village($1::jsonb,$2::bigint,$3::uuid,$4::uuid) as result',
 [JSON.stringify(snapshot),revision,req,dev])).rows[0].result;
try{
 // Stub only the auth schema/claims, not the database rules under test.
 await db.exec(`create role anon; create role authenticated;
 create schema auth; create table auth.users(id uuid primary key);
 create function auth.uid() returns uuid language sql stable as $$
 select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid $$;
 grant usage on schema auth to anon,authenticated;
 grant execute on function auth.uid() to anon,authenticated;`);
 for(const id of ids)await db.query('insert into auth.users values ($1)',[id]);
 await db.exec(readFileSync(new URL('../migrations/001_private_saves.sql',import.meta.url),'utf8'));
 for(let i=0;i<3;i++){
  await login(ids[i]);
  const result=await save({version:7,player_name:`Dorf ${i}`,gold:100+i});
  check(result.revision===1,'each account gets its own initial revision');
 }
 for(let i=0;i<3;i++){
  await login(ids[i]);
  const rows=(await db.query('select user_id,snapshot from public.player_saves')).rows;
  check(rows.length===1 && rows[0].user_id===ids[i] && rows[0].snapshot.gold===100+i,'RLS reveals only the owner village');
  const other=(await db.query('select * from public.player_saves where user_id=$1',[ids[(i+1)%3]])).rows;
  check(other.length===0,'explicit foreign UUID cannot read another account');
  await reject(()=>db.query('update public.player_saves set snapshot=$1 where user_id=$2',[{},ids[(i+1)%3]]),/permission denied/);
 }
 await login(ids[0]);
 const payload={version:7,gold:110}; const retry=request();
 check((await save(payload,1,retry)).revision===2,'valid revision advances once');
 check((await save(payload,1,retry)).revision===2,'identical retry returns same revision');
 await reject(()=>save({version:7,gold:999},1,retry),/request_reused/);
 await reject(()=>save(payload,1),/revision_conflict/);
 await reject(()=>save(payload,2,request(),second),/other_device_active/);
 await reject(()=>save({},2),/invalid_snapshot/);
 await reject(()=>save({version:8},2),/invalid_snapshot/);
 await reject(()=>save({version:7,text:'x'.repeat(1048576)},2),/invalid_snapshot/);
 await reject(()=>save(payload,2,null),/invalid_request/);
 await db.exec('reset role');
 await db.query("update public.player_saves set lease_until=now()-interval '1 second' where user_id=$1",[ids[0]]);
 await login(ids[0]);
 check((await save(payload,2,request(),second)).revision===3,'device handoff only after expiry');
 await reject(()=>save(payload,2),/revision_conflict/);
 await login('', 'authenticated');
 await reject(()=>save(payload),/authentication_required/);
 await login('', 'anon');
 await reject(()=>db.query('select * from public.player_saves'),/permission denied/);
 await reject(()=>save(payload),/permission denied/);
 await db.exec('reset role');
 const wrappers=(await db.query("select prosecdef from pg_proc where oid='public.save_private_village(jsonb,bigint,uuid,uuid)'::regprocedure")).rows;
 check(wrappers[0].prosecdef===false,'public wrapper is security invoker');
 console.log(`PRIVATE_SAVE_SQL_TESTS ${checks}/${checks}`);
}finally{await db.close();}
