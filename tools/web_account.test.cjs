const {chromium,webkit}=require('playwright');
const fs=require('node:fs');const assert=require('node:assert/strict');
(async()=>{
 fs.mkdirSync('logs/account-browser',{recursive:true});
 for(const [name,engine] of [['chromium',chromium],['webkit',webkit]]){
  const browser=await engine.launch({headless:true});
  try{
   const page=await browser.newPage({viewport:{width:390,height:844},hasTouch:true,isMobile:true});
   await page.setContent('<html><head><meta name="viewport" content="width=device-width,initial-scale=1"></head><body><canvas></canvas></body></html>');
   await page.addScriptTag({content:fs.readFileSync('tools/web_account.js','utf8')});
   await page.evaluate(()=>GlutwachtAccount.show(''));
   await page.locator('#gw-email').tap();
   assert.equal(await page.evaluate(()=>document.activeElement.id),'gw-email');
   await page.keyboard.type('mobile@example.test');
   await page.locator('#gw-password').tap();await page.keyboard.type('Only-a-test-password');
   await page.locator('#gw-account button[type=submit]').tap();
   const result=await page.evaluate(()=>GlutwachtAccount.take());
   assert.deepEqual(JSON.parse(result),{action:'login',email:'mobile@example.test',password:'Only-a-test-password'});
   assert.equal(await page.locator('#gw-password').inputValue(),'');
   assert.equal(await page.evaluate(()=>GlutwachtAccount.take()),null);
   await page.evaluate(()=>GlutwachtAccount.show('Bitte die Bestätigungs-E-Mail öffnen.'));
   await page.setViewportSize({width:844,height:220});
   await page.locator('#gw-email').tap();await page.locator('#gw-email').fill('friend@example.test');
   await page.locator('#gw-password').fill('Second-test-password');
   await page.locator('#gw-register').tap();
   assert.equal(JSON.parse(await page.evaluate(()=>GlutwachtAccount.take())).action,'register');
   await page.evaluate(()=>GlutwachtAccount.show(''));
   await page.locator('#gw-recover').tap();
   assert.equal(JSON.parse(await page.evaluate(()=>GlutwachtAccount.take())).action,'recover');
   await page.evaluate(()=>GlutwachtAccount.show('Dein Fortschritt bleibt in deinem Konto.'));
   await page.setViewportSize({width:390,height:844});await page.screenshot({path:`logs/account-browser/${name}-portrait.png`});
   await page.setViewportSize({width:844,height:390});await page.screenshot({path:`logs/account-browser/${name}-landscape.png`});
   await page.evaluate(()=>GlutwachtAccount.hide());assert.ok(await page.locator('#gw-account').isHidden());
   console.log(`${name}: native input focus, typing, login/register/recovery, one-shot credentials, portrait and reduced-height scrolling OK`);
  }finally{await browser.close();}
 }
})().catch(e=>{console.error(e);process.exitCode=1;});
