/* Exercise the exported game through actual browser touch events, never mutate game state. */
const {chromium}=require('playwright');
const {spawn}=require('node:child_process');
const fs=require('node:fs');
const assert=require('node:assert/strict');
(async()=>{
 fs.mkdirSync('logs/browser',{recursive:true});
 const server=spawn('python3',['-m','http.server','8765','--directory','dist'],{stdio:'ignore'});
 let browser;
 try {
  browser=await chromium.launch({headless:true,args:['--use-angle=swiftshader','--enable-unsafe-swiftshader','--disable-dev-shm-usage']});
  const context=await browser.newContext({viewport:{width:1280,height:720},hasTouch:true});
  const page=await context.newPage();
  page.setDefaultTimeout(45000);
  await page.route('**/favicon.ico',route=>route.fulfill({status:204,body:''}));
  const errors=[];page.on('pageerror',e=>errors.push(e.message));
  page.on('console',m=>{if(m.type()==='error')errors.push(m.text());});
  await page.goto('http://127.0.0.1:8765/v08/?qa=1',{timeout:60000});
  const state=()=>page.evaluate(()=>window.__glutwacht);
  const wait=async(fn,timeout=45000)=>page.waitForFunction(fn,null,{timeout});
  const tap=async(x,y)=>{await page.touchscreen.tap(x,y);await page.waitForTimeout(400);};
  await wait(()=>window.__glutwacht?.dialog==='tutorial',120000);
  await page.screenshot({path:'logs/browser/tutorial.png'});
  await tap(640,555);
  await wait(()=>window.__glutwacht?.dialog==='heroes');
  await tap(260,583);
  await wait(()=>window.__glutwacht?.dialog==='tutorial');
  await tap(640,555);
  await tap(780,660);
  await wait(()=>window.__glutwacht?.jobs>=1 && window.__glutwacht.dialog==='');
  await tap(600,167);await wait(()=>window.__glutwacht?.dialog==='tutorial');
  await tap(640,555);await wait(()=>window.__glutwacht?.dialog==='building');
  await page.screenshot({path:'logs/browser/upgrade.png'});
  await tap(960,615);await tap(1135,85);
  await wait(()=>window.__glutwacht?.dialog==='');
  await tap(600,167);await wait(()=>window.__glutwacht?.dialog==='tutorial');
  await tap(640,555);await wait(()=>window.__glutwacht?.dialog==='training');
  await tap(980,306);await tap(1025,129);
  await wait(()=>window.__glutwacht?.hall===2);
  await wait(()=>window.__glutwacht?.mode==='home' && window.__glutwacht.dialog==='');
  assert.equal((await state()).hero,'warrior');
  const start=await state();
  const cdp=await context.newCDPSession(page);
  await cdp.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[{x:145,y:502,id:4}]});
  await page.waitForFunction(p=>Math.hypot(window.__glutwacht.hero_x-p.hero_x,window.__glutwacht.hero_z-p.hero_z)>1,start,{timeout:30000});
  await cdp.send('Input.dispatchTouchEvent',{type:'touchMove',touchPoints:[{x:300,y:502,id:4}]});
  await page.waitForTimeout(500);
  await cdp.send('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]});
  await page.waitForTimeout(1200);
  const moved=await state();
  console.log('Joystick observations',JSON.stringify({start,moved}));
  assert.ok(Math.hypot(moved.hero_x-start.hero_x,moved.hero_z-start.hero_z)>1,'joystick moves hero');
  await page.screenshot({path:'logs/browser/home.png'});
  for(const [x,y,name,closeX] of [[313,654,'catalog',1104],[1188,654,'shop',1025]]){
   await tap(x,y);await wait(new Function(`return window.__glutwacht?.dialog===${JSON.stringify(name)}`));
   await tap(closeX,name==='catalog'?107:129);
   await wait(()=>window.__glutwacht?.dialog==='');
  }
  await page.reload();
  await wait(()=>window.__glutwacht?.mode==='home' && window.__glutwacht.dialog==='',120000);
  assert.equal((await state()).hero,'warrior','hero selection survives browser reload');
  assert.equal((await state()).gold,start.gold,'resources survive reload');
  await tap(100,654);await wait(()=>window.__glutwacht?.mode==='scout');
  await tap(1170,653);await wait(()=>window.__glutwacht?.mode==='raid');
  for(let i=0;i<5;i++){
   const before=await state();
   assert.ok(before.deployment_points.length,'legal visible deployment point');
   const [x,y]=before.deployment_points[0];await tap(x,y);
   await wait(new Function(`return window.__glutwacht.reserve.melee===${before.reserve.melee-1}`));
  }
  await page.screenshot({path:'logs/browser/raid.png'});
  console.log('Browser deployment verified',JSON.stringify(await state()));
  // Let the actual simulation reach defeat/victory/timeout without forcing a result.
  await wait(()=>window.__glutwacht?.dialog==='result',240000);
  await page.screenshot({path:'logs/browser/result.png'});
  await tap(640,574);await wait(()=>window.__glutwacht?.mode==='home' && window.__glutwacht.dialog==='');
  const afterRaid=await state();
  await page.goto('http://127.0.0.1:8765/v08final/');
  await wait(()=>window.__glutwacht?.mode==='home' && window.__glutwacht.dialog==='',120000);
  assert.equal((await state()).hero,afterRaid.hero,'old bookmarked URL retains the hero');
  assert.equal((await state()).gold,afterRaid.gold,'old bookmarked URL retains resources');
  fs.writeFileSync('logs/browser/result.json' ,JSON.stringify({state:await state(),errors},null,2));
  assert.deepEqual(errors,[],'browser has no runtime errors');
  console.log('WEB_SMOKE_OK: WebGL boot, touch joystick, dialogs, persistent hero/resources, five single deployments, full raid, return home');
 } catch(error) {
  if(browser){
   const page=browser.contexts()[0]?.pages()[0];
   if(page){
    await page.screenshot({path:'logs/browser/failure.png',timeout:15000}).catch(()=>{});
    const state=await page.evaluate(()=>({state:window.__glutwacht,errors:window.__glutwachtErrors,canvas:{width:document.querySelector('canvas')?.width,height:document.querySelector('canvas')?.height}})).catch(()=>null);
    fs.writeFileSync('logs/browser/failure.json',JSON.stringify(state,null,2));
    console.error('Browser state at failure',JSON.stringify(state));
   }
  }
  throw error;
 } finally {if(browser)await browser.close();server.kill();}
})().catch(e=>{console.error(e);process.exitCode=1;});
