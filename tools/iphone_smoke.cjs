/* iPhone landscape interaction on the exported build; test accounts only. */
const {chromium,devices}=require('playwright');
const {spawn}=require('node:child_process');
const fs=require('node:fs');const assert=require('node:assert/strict');const cloud=require('./mock_cloud.cjs');
(async()=>{
 fs.mkdirSync('logs/iphone',{recursive:true});
 const server=spawn('python3',['-m','http.server','8766','--directory','dist'],{stdio:'ignore'});let browser;
 try{
  browser=await chromium.launch({headless:true,args:['--use-angle=swiftshader','--enable-unsafe-swiftshader','--disable-dev-shm-usage']});
  const context=await browser.newContext({...devices['iPhone 13 landscape'],defaultBrowserType:undefined,deviceScaleFactor:1});await cloud.install(context);
  const email='legacy-iphone@example.test',id='00000000-0000-4000-8000-000000000015';cloud.users.set(email,id);
  const legacy=JSON.parse(fs.readFileSync('tests3d/fixtures/v014-played-village.json','utf8'));cloud.saves.set(id,{revision:4,snapshot:legacy});
  const page=await context.newPage();const errors=[];page.on('pageerror',e=>errors.push(e.message));page.on('console',m=>{if(m.type()==='error'&&/SCRIPT ERROR|Parse Error|^ERROR:/.test(m.text()))errors.push(m.text())});
  await page.route('**/favicon.ico',r=>r.fulfill({status:204,body:''}));
  await page.goto('http://127.0.0.1:8766/v08/?qa=1');
  const wait=(fn,timeout=120000)=>page.waitForFunction(fn,null,{timeout});const state=()=>page.evaluate(()=>window.__glutwacht);
  await wait(()=>window.__glutwacht?.mode==='login');
  await page.locator('#gw-email').fill(email);await page.locator('#gw-password').fill('Test-only-password-123');await page.locator('#gw-account button[type=submit]').click();
  await wait(()=>window.__glutwacht?.mode==='home'&&window.__glutwacht.dialog==='');
  assert.equal((await state()).hero,'mage');assert.equal((await state()).gold,321);
  const control=async(test)=>{const s=await state();const b=s.controls.find(test);assert.ok(b,'visible control exists');const [x,y,w,h]=b.rect;const v=page.viewportSize();return [(x+w/2)*v.width/s.ui_size[0],(y+h/2)*v.height/s.ui_size[1]]};
  const tap=async(test)=>{await page.touchscreen.tap(...await control(test));await page.waitForTimeout(450)};
  await page.screenshot({path:'logs/iphone/existing-village.png'});
  await tap(b=>b.text==='ALLES SAMMELN');await tap(b=>b.text==='?');await wait(()=>window.__glutwacht.dialog==='help');await page.screenshot({path:'logs/iphone/help.png'});await tap(b=>b.id==='CloseDialog');
  await tap(b=>b.id==='Action_build');await wait(()=>window.__glutwacht.dialog==='catalog');await tap(b=>b.id==='BuildInfo_hero_hall');await wait(()=>window.__glutwacht.dialog==='build_info');await page.screenshot({path:'logs/iphone/build-info.png'});await tap(b=>b.id==='CloseDialog');
  await tap(b=>b.id==='Action_menu');await tap(b=>b.text==='Grafik & Ton');await wait(()=>window.__glutwacht.dialog==='settings');
  await tap(b=>b.text==='Sparsam');await tap(b=>b.id==='Setting_brightness');await tap(b=>b.id==='Setting_music');await tap(b=>b.id==='Setting_effects');
  await page.waitForTimeout(1500);const settings=(await state()).settings;assert.equal(settings.quality,0);await page.screenshot({path:'logs/iphone/settings.png'});await tap(b=>b.id==='CloseDialog');
  await page.reload();await wait(()=>window.__glutwacht?.mode==='home'&&window.__glutwacht.dialog==='');assert.deepEqual((await state()).settings,settings,'settings persist across reload');assert.equal((await state()).hero,'mage');
  await tap(b=>b.id==='Action_attack');await wait(()=>window.__glutwacht.mode==='scout');await tap(b=>b.id==='Action_attack');await wait(()=>window.__glutwacht.mode==='raid');
  const ground=async()=>{const s=await state();assert.ok(s.deployment_points.length);const v=page.viewportSize();return [s.deployment_points[0][0]*v.width/s.ui_size[0],s.deployment_points[0][1]*v.height/s.ui_size[1]]};
  await page.touchscreen.tap(...await ground());await wait(()=>window.__glutwacht.selected_troop==='');
  await tap(b=>b.id==='Deploy_melee');let n=(await state()).reserve.melee;
  for(let i=0;i<3;i++)await page.touchscreen.tap(...await ground());
  await wait(new Function(`return window.__glutwacht.reserve.melee===${n-3}`));
  const cdp=await context.newCDPSession(page);const [x,y]=await ground();await cdp.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[{x,y,id:0}]});await page.waitForTimeout(1300);await cdp.send('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]});
  await wait(()=>window.__glutwacht.reserve.melee===0);await tap(b=>b.text==='?');await wait(()=>window.__glutwacht.dialog==='help');await tap(b=>b.id==='CloseDialog');
  await page.screenshot({path:'logs/iphone/attack.png'});assert.deepEqual(errors,[]);fs.writeFileSync('logs/iphone/result.json',JSON.stringify({viewport:page.viewportSize(),engine:'Chromium with iPhone landscape emulation; not a physical device',state:await state(),errors},null,2));
  console.log('IPHONE_SMOKE_OK: existing 0.14 account save, collection, building info, help, settings reload, hero and rapid/held troop deployment');
 }catch(e){if(browser){const p=browser.contexts()[0]?.pages()[0];if(p){await p.screenshot({path:'logs/iphone/failure.png'}).catch(()=>{});console.error('IPHONE_STATE',await p.evaluate(()=>window.__glutwacht).catch(()=>null))}}throw e}
 finally{if(browser)await browser.close();server.kill()}
})().catch(e=>{console.error(e);process.exitCode=1});
