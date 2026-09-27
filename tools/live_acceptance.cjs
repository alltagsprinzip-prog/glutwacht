/* Real production RPCs, restricted to two disposable QA identities. No mail. */
const {chromium}=require('playwright');
const fs=require('node:fs');const {spawn}=require('node:child_process');const {randomUUID}=require('node:crypto');const assert=require('node:assert/strict');
const cfg=JSON.parse(fs.readFileSync('game3d/online/config.json','utf8'));
const users=JSON.parse(fs.readFileSync(process.env.RUNNER_TEMP+'/glutwacht-qa/credentials.json','utf8'));
const url=cfg.url||cfg.supabase_url;const key=cfg.anon_key||cfg.publishable_key;
const tokens=[];const pause=ms=>new Promise(r=>setTimeout(r,ms));
async function raw(path,token,body){const r=await fetch(url+path,{method:'POST',headers:{apikey:key,'Content-Type':'application/json',...(token?{Authorization:'Bearer '+token}:{})},body:JSON.stringify(body),signal:AbortSignal.timeout(20000)});const data=await r.json().catch(()=>({}));return {ok:r.ok,status:r.status,data};}
async function rpc(i,name,action,args={}){const r=await raw('/rest/v1/rpc/'+name,tokens[i],{p_action:action,p_args:args});if(!r.ok)throw Error(name+' '+action+' returned '+r.status+': '+String(r.data.message||''));return r.data;}
const social=(i,a,p={})=>rpc(i,'glutwacht_social',a,p),rank=(i,a,p={})=>rpc(i,'glutwacht_ranking',a,p);
(async()=>{
 fs.mkdirSync('logs/live',{recursive:true});let browser;const server=spawn('python3',['-m','http.server','8767','--directory','dist'],{stdio:'ignore'});
 try{
  for(let i=0;i<2;i++){
   let result;
   for(let n=0;n<36;n++){
    result=await raw('/auth/v1/token?grant_type=password','',{email:users[i].email,password:users[i].password});
    if(result.ok)break;
    if(n%6===0)console.log('Waiting for disposable test account activation.');await pause(20000);
   }
   assert.ok(result.ok,'disposable account activation');tokens[i]=result.data.access_token;
   assert.equal(result.data.user.id,users[i].id,'account identity is distinct and expected');
  }
  console.log('Both real Auth sessions verified.');
  const profiles=[await social(0,'enroll',{name:'QA 017 Nord'}),await social(1,'enroll',{name:'QA 017 Süd'})];
  browser=await chromium.launch({headless:true,args:['--use-angle=swiftshader','--enable-unsafe-swiftshader','--disable-dev-shm-usage']});
  const contexts=[],pages=[];const errors=[];
  for(let i=0;i<2;i++){
   const context=await browser.newContext({viewport:{width:i===0?956:844,height:i===0?440:390},deviceScaleFactor:1,hasTouch:true,isMobile:true});contexts.push(context);
   const page=await context.newPage();pages.push(page);page.on('pageerror',e=>errors.push(e.message));
   console.log('Opening game session '+i);
   await page.goto('http://127.0.0.1:8767/v08/?qa=1'+(i===1?'&invite='+profiles[0].me.tag:''),{waitUntil:'domcontentloaded'});
   await page.waitForFunction(()=>window.__glutwacht?.mode==='login',null,{timeout:150000});
   if(i===1)assert.equal(await page.evaluate(()=>GlutwachtInvite.peek()),profiles[0].me.tag,'invitation survives boot before sign-in');
   await page.locator('#gw-email').fill(users[i].email);await page.locator('#gw-password').fill(users[i].password);
   await page.keyboard.press('Enter');await page.locator('#gw-account button[type=submit]').click();
   await page.waitForFunction(()=>window.__glutwacht?.mode==='home',null,{timeout:120000});
   assert.equal((await page.evaluate(()=>__glutwacht)).hero,i===0?'mage':'warrior');
   await page.screenshot({path:'logs/live/account-'+i+'-landscape.png',timeout:20000});
   console.log('Game login and saved hero verified for session '+i);
   if(i===0)await page.goto('about:blank'); // one software WebGL world at a time; account storage stays isolated
  }
  const b=pages[1];
  const tap=async(page,predicate)=>{
   for(let n=0;n<80;n++){
    const s=await page.evaluate(()=>window.__glutwacht);const c=s.controls?.find(predicate);
    if(c&&!c.disabled){const [x,y,w,h]=c.rect,v=page.viewportSize();await page.touchscreen.tap((x+w/2)*v.width/s.ui_size[0],(y+h/2)*v.height/s.ui_size[1]);await pause(600);return;}
    await pause(250);
   }
   throw Error('Expected UI control missing: '+predicate.toString());
  };
  // The receiving browser retains the invitation across its real Auth login.
  if((await b.evaluate(()=>__glutwacht.dialog))!=='social')await tap(b,c=>c.text==='FREUNDE');
  await tap(b,c=>c.text==='Einladung ansehen');await tap(b,c=>c.text==='Freundschaft anfragen');
  let a=await social(0,'state');assert.equal(a.incoming.length,1);assert.equal(a.incoming[0].tag,profiles[1].me.tag);
  console.log('Friend request received through real game UI.');
  await social(0,'accept',{tag:profiles[1].me.tag});assert.equal((await social(1,'state')).friends.length,1);
  assert.equal(await b.evaluate(()=>GlutwachtInvite.peek()),'','accepted outgoing request clears pending invitation');
  const clan=await social(0,'create_clan',{name:'QA Jade '+randomUUID().slice(0,8),description:'Temporärer Funktionstest'});
  assert.equal((await social(1,'find_clans',{query:clan.clan.name})).clans[0].id,clan.clan.id);
  await social(0,'invite',{tag:profiles[1].me.tag});await social(1,'join',{clan_id:clan.clan.id});
  assert.equal((await social(0,'state')).members.length,2);
  await social(1,'leave');assert.equal((await social(1,'state')).clan,null);await social(0,'leave');
  console.log('Clan create/find/invite/join/leave verified.');
  let trial=await rank(0,'start');trial=await rank(0,'turn',{match_id:trial.match_id,round:trial.state.round,request_id:randomUUID(),kind:'finish',lane:0});
  let stronger=await rank(1,'start');
  const commands=[['deploy','shield',0],['deploy','siege',0],['deploy','archers',-1],['deploy','archers',1],['deploy','melee',-1],['deploy','melee',1]];
  for(let i=0;i<18&&!stronger.state.done;i++){
   const [kind,unit,lane]=commands[i]||[i===8?'rally':(i===10&&stronger.state.actors[0].hp>0&&stronger.state.actors[0].hp<420?'heal':'advance'),'',i%3-1];
   const cmd={match_id:stronger.match_id,round:stronger.state.round,request_id:randomUUID(),kind,lane,...(unit?{unit}: {})};
   stronger=await rank(1,'turn',cmd);
   if(i===0)assert.deepEqual(await rank(1,'turn',cmd),stronger,'real duplicate network request is idempotent');
  }
  const first=await rank(0,'board'),second=await rank(1,'board');assert.ok(second.own.score>first.own.score&&second.own.rank<first.own.rank);
  console.log('Verified ranking scores: '+first.own.score+', '+second.own.score);
  await b.goto('about:blank');
  for(let i=0;i<2;i++){
   const p=pages[i];await p.goto('http://127.0.0.1:8767/v08/?qa=1');
   await p.waitForFunction(()=>__glutwacht?.mode==='home',null,{timeout:120000});if((await p.evaluate(()=>__glutwacht.dialog))!=='')await tap(p,c=>c.id==='CloseDialog');
   await tap(p,c=>c.id==='Action_menu');await tap(p,c=>c.text==='Rangliste · Jadeprüfung');
   await p.waitForFunction(()=>__glutwacht.dialog==='ranking');await p.screenshot({path:'logs/live/real-ranking-'+i+'.png',timeout:20000});
   await p.goto('about:blank');
  }
  // Logout/re-login cannot combine villages, inventory, upgrades or hero identity.
  await pages[0].goto('http://127.0.0.1:8767/v08/?qa=1');await pages[0].waitForFunction(()=>__glutwacht?.mode==='home',null,{timeout:120000});assert.equal((await pages[0].evaluate(()=>__glutwacht)).hero,'mage');
  assert.deepEqual(errors,[]);
  fs.writeFileSync('logs/live/result.json',JSON.stringify({test:'real Auth + real existing Supabase backend',accounts:2,oldSaveHero:'mage',otherHero:'warrior',friendship:'requested in receiving game UI; accepted through authenticated API',clan:'create/find/invite/join/leave verified',scores:[first.own.score,second.own.score],ranks:[first.own.rank,second.own.rank],viewports:['956x440','844x390'],device:'Chromium emulation, no physical iPhone',errors},null,2));
  console.log('LIVE_TWO_ACCOUNT_ACCEPTANCE_OK');
 }catch(error){
  if(browser)for(const p of browser.contexts().flatMap(c=>c.pages()).filter(p=>p.url()!=='about:blank')){
   console.error('Failure game state',JSON.stringify(await p.evaluate(()=>({game:window.__glutwacht,errors:window.__glutwachtErrors})).catch(()=>null)));
   await p.screenshot({path:'logs/live/failure.png',timeout:12000}).catch(()=>{});
  }
  throw error;
 }finally{
  for(let i=0;i<tokens.length;i++)await raw('/auth/v1/logout?scope=global',tokens[i],{}).catch(()=>{});
  if(browser)await browser.close();server.kill();
 }
})().catch(e=>{let m=String(e.stack||e);for(const u of users)m=m.replaceAll(u.password,'[redacted]');console.error(m);process.exitCode=1;});
