/* The exported art study, using ordinary touch input only. */
const {chromium}=require('playwright');
const {spawn}=require('node:child_process');
const fs=require('node:fs');
const assert=require('node:assert/strict');
(async()=>{
 fs.mkdirSync('logs/art',{recursive:true});
 const server=spawn('python3',['-m','http.server','8766','--directory','dist'],{stdio:'ignore'});
 let browser;
 try{
  browser=await chromium.launch({headless:true,args:['--use-angle=swiftshader','--enable-unsafe-swiftshader','--disable-dev-shm-usage']});
  const page=await browser.newPage({viewport:{width:1280,height:720},hasTouch:true});
  const errors=[];page.on('pageerror',e=>errors.push(e.message));
  await page.goto('http://127.0.0.1:8766/v08/index.html?atelier=1&qa=1');
  await page.waitForFunction(()=>window.__glutwacht?.hero==='warrior'&&window.__glutwacht.dialog==='',null,{timeout:120000});
  const start=await page.evaluate(()=>window.__glutwacht);
  assert.equal(start.wood,1100);assert.equal(start.mode,'home');
  await page.screenshot({path:'logs/art/atelier-browser.png'});
  const cdp=await page.context().newCDPSession(page);
  await cdp.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[{x:145,y:502,id:4}]});
  await page.waitForFunction(p=>Math.hypot(window.__glutwacht.hero_x-p.hero_x,window.__glutwacht.hero_z-p.hero_z)>.5,start,{timeout:30000});
  await cdp.send('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]});
  await page.touchscreen.tap(505,645);
  await page.waitForFunction(()=>window.__glutwacht.dialog==='upgrades');
  await page.touchscreen.tap(1025,129);
  await page.waitForFunction(()=>window.__glutwacht.dialog==='');
  await page.setViewportSize({width:932,height:430});
  await page.waitForTimeout(1500);
  await page.screenshot({path:'logs/art/atelier-browser-mobile.png'});
  await page.reload();
  await page.waitForFunction(()=>window.__glutwacht?.hero==='warrior'&&window.__glutwacht.dialog==='',null,{timeout:120000});
  assert.equal(await page.evaluate(()=>window.__glutwacht.wood),1100);
  assert.equal(await page.evaluate(()=>localStorage.getItem('glutwacht.auth.v1')),null);
  assert.deepEqual(errors,[]);
  console.log('ART_WEB_OK: real WebGL, touch movement, upgrade menu, mobile resize, isolated reload');
 }finally{if(browser)await browser.close();server.kill('SIGTERM');}
})().catch(e=>{console.error(e);process.exitCode=1;});
