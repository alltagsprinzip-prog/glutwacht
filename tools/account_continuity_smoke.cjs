const {chromium}=require('playwright');
const {spawn}=require('node:child_process');
const fs=require('node:fs'),assert=require('node:assert/strict'),cloud=require('./mock_cloud.cjs');
(async()=>{
 const server=spawn('python3',['-m','http.server','8767','--directory','dist'],{stdio:'ignore'});let browser;
 try{
  browser=await chromium.launch({headless:true,args:['--use-angle=swiftshader','--enable-unsafe-swiftshader','--disable-dev-shm-usage']});
  const a=await browser.newContext({viewport:{width:750,height:422},hasTouch:true});await cloud.install(a);
  const id='00000000-0000-4000-8000-000000000015';cloud.users.set('legacy@example.test',id);
  cloud.saves.set(id,{revision:4,snapshot:JSON.parse(fs.readFileSync('tests3d/fixtures/v014-played-village.json'))});
  const page=await a.newPage();const errors=[];page.on('pageerror',e=>errors.push(e.message));
  const url='http://127.0.0.1:8767/v08/?qa=1';
  const wait=(fn)=>page.waitForFunction(fn,null,{timeout:120000});
  await page.goto(url);await wait(()=>window.__glutwacht?.mode==='login');
  await page.locator('#gw-email').fill('legacy@example.test');await page.locator('#gw-password').fill('Test-only-password-123');await page.locator('button[type=submit]').click();
  await wait(()=>window.__glutwacht?.mode==='home'&&window.__glutwacht.dialog==='');
  assert.equal(await page.evaluate(()=>window.__glutwacht.gold),321);console.log('Existing account loaded');
  await page.goto('about:blank');
  const b=await browser.newContext({viewport:{width:750,height:422},hasTouch:true});await cloud.install(b);const friend=await b.newPage();
  await friend.goto(url);await friend.waitForFunction(()=>window.__glutwacht?.mode==='login',null,{timeout:120000});
  await friend.locator('#gw-email').fill('friend@example.test');await friend.locator('#gw-password').fill('Test-only-password-123');await friend.locator('#gw-register').click();
  await friend.waitForFunction(()=>window.__glutwacht?.dialog==='tutorial',null,{timeout:120000});
  assert.equal(await friend.evaluate(()=>window.__glutwacht.gold),160);assert.equal(await friend.evaluate(()=>window.__glutwacht.hero_id),'');
  for(let i=0;i<100&&cloud.saves.size!==2;i++)await friend.waitForTimeout(100);
  assert.equal(cloud.saves.size,2);await b.close();console.log('Separate account owns its fresh village');
  await page.goto(url);await wait(()=>window.__glutwacht?.mode==='home'&&window.__glutwacht.dialog==='');
  console.log('Returned to original account');
  const tap=async(test)=>{const p=await page.evaluate(src=>{const s=window.__glutwacht,b=s.controls.find(new Function('b','return '+src));if(!b)throw Error(src);return [(b.rect[0]+b.rect[2]/2)*innerWidth/s.ui_size[0],(b.rect[1]+b.rect[3]/2)*innerHeight/s.ui_size[1]]},test);await page.touchscreen.tap(...p);await page.waitForTimeout(400)};
  await tap("b.id==='Action_menu'");await wait(()=>window.__glutwacht.dialog==='menu');
  console.log('Direct menu logout available');
  await page.waitForFunction(id=>{const j=JSON.parse(localStorage.getItem('glutwacht.save-journal.v1.'+id)||'{}'),m=JSON.parse(j.metadata||'{}');return m.dirty===false&&Object.keys(m.pending||{}).length===0},id,{timeout:120000});
  console.log("Cloud is clean");await tap("b.id==='MenuLogout'");await wait(()=>window.__glutwacht?.mode==='login');await page.reload();await wait(()=>window.__glutwacht?.mode==='login');
  await page.locator('#gw-email').fill('legacy@example.test');await page.locator('#gw-password').fill('Test-only-password-123');await page.locator('button[type=submit]').click();
  await wait(()=>window.__glutwacht?.mode==='home'&&window.__glutwacht.dialog==='');
  assert.equal(await page.evaluate(()=>window.__glutwacht.gold),321);assert.equal(await page.evaluate(()=>window.__glutwacht.hero),'mage');assert.deepEqual(errors,[]);
  console.log('ACCOUNT_CONTINUITY_OK: two isolated accounts, existing village, logout/reload/login, resources and hero preserved');
 }finally{if(browser)await browser.close();server.kill()}
})().catch(e=>{console.error(e);process.exitCode=1});
