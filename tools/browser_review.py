#!/usr/bin/env python3
"""Real Chromium/WebGL smoke test of exported game, through mouse/touch only.
Runs in CI with no access to user browser data. Import is explicit and exercises
our normal file chooser and confirmation rather than a writable debug API.
"""
import functools, http.server, json, os, pathlib, threading, time, sys
from playwright.sync_api import sync_playwright
root=pathlib.Path(sys.argv[1]).resolve()
out=pathlib.Path('logs/browser');out.mkdir(parents=True,exist_ok=True)
class Quiet(http.server.SimpleHTTPRequestHandler):
    def log_message(self,*args): pass
server=http.server.ThreadingHTTPServer(('127.0.0.1',8765),functools.partial(Quiet,directory=str(root)))
threading.Thread(target=server.serve_forever,daemon=True).start()
checks=[];errors=[]
def ok(value,label):
    if not value: raise AssertionError(label)
    checks.append(label);print('BROWSER_PASS:',label,flush=True)
try:
 with sync_playwright() as p:
  browser=p.chromium.launch(channel='chrome',headless=True,args=['--enable-unsafe-swiftshader','--use-angle=swiftshader','--disable-dev-shm-usage'])
  ctx=browser.new_context(viewport={'width':1280,'height':720},has_touch=True)
  page=ctx.new_page();page.on('pageerror',lambda e:errors.append(str(e)))
  page.on('console',lambda m:errors.append(m.text) if m.type=='error' and ('SCRIPT ERROR' in m.text or 'Parse Error' in m.text or 'Failed to load script' in m.text) else None)
  page.goto('http://127.0.0.1:8765/hud-review/',wait_until='domcontentloaded')
  page.wait_for_function('window.__glutwacht && window.__glutwacht.dialog === "heroes"',timeout=120000)
  ok(page.evaluate('!!document.createElement("canvas").getContext("webgl2")'),'WebGL2 context available')
  page.screenshot(path=str(out/'01-first-start.png'))
  page.touchscreen.tap(266,582)
  page.wait_for_function('window.__glutwacht && window.__glutwacht.dialog===""',timeout=20000)
  ok(page.evaluate('window.__glutwacht.joystick_visible'),'village joystick visible in browser')
  initial=page.evaluate('window.__glutwacht')
  page.keyboard.down('d');page.wait_for_timeout(1200);page.keyboard.up('d');page.wait_for_timeout(700)
  moved=page.evaluate('window.__glutwacht')
  ok(abs(moved['hero_x']-initial['hero_x'])+abs(moved['hero_z']-initial['hero_z'])>.25,'browser hero movement without activation')
  # A previous played schema-7 save, with actual training and active construction.
  stamp=time.time()
  previous={'version':7,'hero':'warrior','hero_id':'warrior','wood':3000,'stone':2200,'gold':1700,'gems':80,'hall':5,'barracks':3,'smithy':2,'melee':10,'archers':10,'wins':6,'sword':True,'sound':False,'xp':{'warrior':1500,'ninja':0,'shaman':0,'mage':0},'training':{'heroes':{'warrior':{'power':2,'vitality':2,'skill':1}},'troops':{'melee':2,'archers':2}},'structures':[{'uid':'s1','kind':'lumber','level':2,'x':-22.5,'z':15,'rotation':0,'stock':280},{'uid':'s2','kind':'quarry','level':2,'x':22.5,'z':-15,'rotation':0,'stock':280},{'uid':'s3','kind':'camp','level':5,'x':12.5,'z':20,'rotation':0,'stock':0}], 'jobs':[{'uid':'hall','start':stamp,'finish':stamp+300,'target':6,'new':False}], 'next_uid':4,'last_production':stamp,'obstacles':[],'obstacle_jobs':[]}
  fixture=out/'previous-save.json';fixture.write_text(json.dumps(previous))
  page.touchscreen.tap(66,347);page.wait_for_function('window.__glutwacht.dialog === "menu"')
  page.touchscreen.tap(430,580);page.wait_for_function('window.__glutwacht.dialog === "saves"')
  with page.expect_file_chooser() as chooser:page.mouse.click(846,555)
  chooser.value.set_files(str(fixture.resolve()))
  page.wait_for_function('window.__glutwacht.dialog === "import_confirm"')
  page.touchscreen.tap(842,555);page.wait_for_function('window.__glutwacht.dialog === "" && window.__glutwacht.hall === 5')
  ok(page.evaluate('window.__glutwacht.wood === 3000 && window.__glutwacht.jobs === 1'),'explicit import restores previous resources and build timer')
  page.wait_for_timeout(2500);page.reload(wait_until='domcontentloaded')
  page.wait_for_function('window.__glutwacht && window.__glutwacht.dialog === "" && window.__glutwacht.hall === 5',timeout=120000)
  ok(page.evaluate('window.__glutwacht.hero_id === "warrior" && window.__glutwacht.jobs === 1 && window.__glutwacht.wood === 3000'),'IndexedDB retains played save after real browser reload')
  page.screenshot(path=str(out/'02-village.png'))
  # Open and close the five primary actions without any click-through.
  for x,dialog in [(380,'catalog'),(505,'building'),(630,'hero_profile'),(755,'army'),(880,'training')]:
   page.touchscreen.tap(x,654);page.wait_for_function('(d)=>window.__glutwacht.dialog===d',arg=dialog)
   page.touchscreen.tap(1108 if dialog=='catalog' else 1021,132 if dialog!='catalog' else 110)
   page.wait_for_function('window.__glutwacht.dialog===""');page.wait_for_timeout(400)
   ok(True,dialog+' opens and closes with touch')
  page.touchscreen.tap(108,660);page.wait_for_function('window.__glutwacht.mode === "scout"')
  page.screenshot(path=str(out/'03-scout.png'))
  page.touchscreen.tap(1160,650);page.wait_for_function('window.__glutwacht.mode === "raid"')
  page.wait_for_function('window.__glutwacht.deployment_points.length > 0')
  for key,y in [('melee',247),('archers',350)]:
   page.touchscreen.tap(74,y);page.wait_for_function('(k)=>window.__glutwacht.selected_troop===k',arg=key)
   for i in range(10):
    state=page.evaluate('window.__glutwacht');before=state['reserve'][key]
    if state['result']:raise AssertionError('raid finished before deployment checks')
    point=state['deployment_points'][0];page.touchscreen.tap(point[0],point[1])
    page.wait_for_function('([k,n])=>window.__glutwacht.reserve[k]===n',arg=[key,before-1],timeout=8000)
    ok(True,f'one {key} per touch {i+1}')
  page.screenshot(path=str(out/'04-raid.png'))
  page.touchscreen.tap(805,663);page.wait_for_function('window.__glutwacht.dialog === "result"')
  page.screenshot(path=str(out/'05-result.png'))
  page.touchscreen.tap(640,572);page.wait_for_function('window.__glutwacht.mode === "home"')
  ok(not errors,'no browser script errors')
  ctx.close();browser.close()
finally:
 server.shutdown()
 (out/'result.json').write_text(json.dumps({'checks':checks,'errors':errors},indent=2,ensure_ascii=False))
print('BROWSER_REVIEW_OK',len(checks),flush=True)
