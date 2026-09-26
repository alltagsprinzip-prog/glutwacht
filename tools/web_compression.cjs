// Real exported Godot game + Fetch-visible decoded gzip responses. No real accounts.
const {chromium}=require('playwright');
const {spawn}=require('node:child_process');
const assert=require('node:assert/strict');
const cloud=require('./mock_cloud.cjs');
(async()=>{
 const server=spawn('python3',['-m','http.server','8766','--directory','dist'],{stdio:'ignore'});
 let browser;
 try{
  browser=await chromium.launch({headless:true,args:['--use-angle=swiftshader','--enable-unsafe-swiftshader','--disable-dev-shm-usage']});
  for(let pass=0;pass<2;pass++){
   const context=await browser.newContext({viewport:{width:844,height:390},hasTouch:true});
   await cloud.install(context,{compressed:true});
   const page=await context.newPage();const errors=[];
   page.on('pageerror',e=>errors.push(e.message));
   page.on('console',m=>{if(m.type()==='error'&&/err !=|SCRIPT ERROR/.test(m.text()))errors.push(m.text());});
   await page.goto('http://127.0.0.1:8766/v08/?qa=1');
   await page.locator('#gw-email').waitFor({timeout:120000});
   await page.locator('#gw-email').fill('gzip-player@example.test');
   await page.locator('#gw-password').fill('Test-only-password-123');
   await page.locator('#gw-account button[type=submit]').click();
   await page.waitForFunction(()=>window.__glutwacht?.dialog==='tutorial',null,{timeout:60000}).catch(async e=>{
    console.log('Gzip test diagnostic',JSON.stringify({pass,state:await page.evaluate(()=>window.__glutwacht),notice:await page.locator('#gw-notice').textContent(),errors}));throw e;
   });
   await page.waitForFunction(()=>document.getElementById('glutwacht-start-watch').hidden);
   const end=Date.now()+30000;
   while(!cloud.saves.size&&Date.now()<end)await page.waitForTimeout(100);
   assert.ok(cloud.saves.size,'new account uploaded its initial save');
   assert.deepEqual(errors,[],'compressed login, read and save produce no inflate error');
   if(pass===1){
    await page.evaluate(()=>GODOT_CONFIG.onPrintError('ERROR: Condition "err != 0 && err != 1" is true. Returning: FAILED'));
    assert.ok(await page.locator('#glutwacht-start-watch').isHidden(),'handled transport error does not cover account UI');
   }
   await context.close();
  }
  console.log('PASS: gzip login, new save, existing save on another browser context, nonblocking handled error');
 }finally{if(browser)await browser.close();server.kill();}
})().catch(e=>{console.error(e);process.exitCode=1;});
