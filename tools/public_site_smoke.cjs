/* Verify the published package and ordinary touch input in an isolated art village. */
const {chromium}=require('playwright');
const fs=require('node:fs');
const {createHash}=require('node:crypto');
const assert=require('node:assert/strict');
const origin='https://glutwacht-spieltest.mg-automobile24.chatgpt.site';
const expected='fa12f83bf759';
(async()=>{
 fs.mkdirSync('logs/public-site',{recursive:true});
 let browser,page,game;
 const errors=[];
 try{
  const manifestResponse=await fetch(origin+'/build.json',{cache:'no-store'});
  assert.ok(manifestResponse.ok);
  const manifest=await manifestResponse.json();
  assert.deepEqual(manifest,{build:expected,version:'0.17'});
  const packageResponse=await fetch(origin+'/v08/index.pck?build='+expected,{cache:'no-store'});
  assert.ok(packageResponse.ok);
  const packageHash=createHash('sha256').update(Buffer.from(await packageResponse.arrayBuffer())).digest('hex');
  assert.equal(packageHash.slice(0,12),expected,'published game bytes match the tested export');
  browser=await chromium.launch({headless:true,args:['--use-angle=swiftshader','--enable-unsafe-swiftshader','--disable-dev-shm-usage']});
  const context=await browser.newContext({viewport:{width:956,height:440},hasTouch:true,isMobile:true,deviceScaleFactor:1});
  page=await context.newPage();page.on('pageerror',e=>errors.push(e.message));
  await page.goto(origin+'/?atelier=1&qa=1',{waitUntil:'domcontentloaded',timeout:60000});
  const iframe=page.locator('iframe#game');
  await iframe.waitFor({timeout:60000});
  game=await (await iframe.elementHandle()).contentFrame();
  await game.waitForFunction(()=>window.__glutwacht?.version==='Glutwacht 0.17'&&window.__glutwacht.mode==='home',null,{timeout:180000});
  assert.ok(game.url().includes('build='+expected));
  assert.ok(game.url().includes('atelier=1'),'preview flag survives root and iframe redirects');
  const tap=async predicate=>{
   const state=await game.evaluate(()=>window.__glutwacht);
   const control=state.controls.find(predicate);
   assert.ok(control&&!control.disabled,'expected enabled on-screen control');
   const box=await iframe.boundingBox();const [x,y,w,h]=control.rect;
   await page.touchscreen.tap(box.x+(x+w/2)*box.width/state.ui_size[0],box.y+(y+h/2)*box.height/state.ui_size[1]);
  };
  await page.screenshot({path:'logs/public-site/live-village-956.png'});
  await tap(c=>c.id==='HelpDock');
  await game.waitForFunction(()=>window.__glutwacht.dialog==='help');
  await page.screenshot({path:'logs/public-site/live-help.png'});
  await tap(c=>c.id==='CloseDialog');
  await game.waitForFunction(()=>window.__glutwacht.dialog==='');
  await tap(c=>c.id==='Action_attack');
  await game.waitForFunction(()=>window.__glutwacht.mode==='scout');
  await page.screenshot({path:'logs/public-site/live-scout.png'});
  await tap(c=>c.text==='Zurück');
  await game.waitForFunction(()=>window.__glutwacht.mode==='home');
  await page.setViewportSize({width:844,height:390});
  await game.waitForTimeout(1000);
  await tap(c=>c.id==='Action_menu');
  await game.waitForFunction(()=>window.__glutwacht.dialog==='menu');
  await page.screenshot({path:'logs/public-site/live-menu-844.png'});
  assert.deepEqual(await game.evaluate(()=>window.__glutwachtErrors),[]);
  assert.equal(await game.evaluate(()=>localStorage.getItem('glutwacht.auth.v1')),null,'isolated preview never signs in');
  assert.deepEqual(errors,[]);
  fs.writeFileSync('logs/public-site/result.json',JSON.stringify({url:origin,version:manifest.version,build:expected,packageHash,gameUrl:game.url(),viewports:['956x440','844x390'],checks:['root redirect','matching deployed PCK','real WebGL startup','touch help','opponent preview','touch menu after resize'],device:'Chromium software-WebGL emulation, no physical iPhone',errors},null,2));
  console.log('PUBLIC_SITE_017_OK');
 }catch(error){
  if(game)console.error('Published game state',JSON.stringify(await game.evaluate(()=>({game:window.__glutwacht,errors:window.__glutwachtErrors,body:document.body.innerText})).catch(()=>null)));
  if(page)await page.screenshot({path:'logs/public-site/failure.png',timeout:15000}).catch(()=>{});
  throw error;
 }finally{if(browser)await browser.close();}
})().catch(error=>{console.error(error);process.exitCode=1;});
