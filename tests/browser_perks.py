"""Perk reveal regression with an isolated browser profile and local HTTP server.
Requires Playwright, Chromium and tesseract. Optional argument: export directory.
"""
import ast,json,re,shutil,subprocess,time,sys
from pathlib import Path
from functools import partial
from http.server import SimpleHTTPRequestHandler,ThreadingHTTPServer
from threading import Thread
from playwright.sync_api import sync_playwright
source=ast.parse(Path(__file__).with_name('browser_smoke.py').read_text())
readjs=next(ast.literal_eval(n.value) for n in ast.walk(source) if isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='read_js' for t in n.targets))
writejs=next(ast.literal_eval(n.value) for n in ast.walk(source) if isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='write_js' for t in n.targets))
writejs=writejs.replace('d.coins=2000','d.coins=1000000')
caps=json.loads(re.search(r'const PERK_CAPS := (\{.*\})',(Path(__file__).resolve().parents[1]/'scripts/hub.gd').read_text())[1]);caps['starting_hp']=24
levelsjs=writejs.replace('d.perks={starting_upgrade:0,starting_hp:0,dodge:0,boss_damage:0};d.perk_purchases=0;',f'd.perks={json.dumps(caps)};d.perk_purchases={sum(caps.values())};')
class Quiet(SimpleHTTPRequestHandler):
 def log_message(self,*args):pass
server=ThreadingHTTPServer(('127.0.0.1',0),partial(Quiet,directory=sys.argv[1] if len(sys.argv)>1 else str(Path(__file__).resolve().parents[1]/'build/web')));Thread(target=server.serve_forever,daemon=True).start()
base=f'http://127.0.0.1:{server.server_port}/'
def ocr(path,mode='3'):return subprocess.check_output(['tesseract',path,'stdout','--psm',mode],stderr=subprocess.DEVNULL,text=True)
with sync_playwright() as p:
 b=p.chromium.launch(executable_path=shutil.which('chromium'),args=['--no-sandbox','--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader'])
 c=b.new_context(viewport={'width':390,'height':844},device_scale_factor=2,is_mobile=True,has_touch=True)
 page=c.new_page();errors=[]
 page.on('pageerror',lambda e:errors.append(str(e)));page.on('console',lambda m:errors.append(m.text) if m.type=='error' else None)
 page.goto(base);page.wait_for_function("window.__dungeonReady === 'hub'",timeout=120000);page.wait_for_timeout(1200)
 page.route('**/__fixture.html',lambda r:r.fulfill(body='<html></html>',content_type='text/html'))
 def fixture(script):
  page.goto(base+'__fixture.html');page.evaluate(script);page.goto(base);page.wait_for_function("window.__dungeonReady === 'hub'",timeout=120000);page.wait_for_timeout(400)
 def saved_when(predicate):
  for _ in range(50):
   d=page.evaluate(readjs)
   if d and predicate(d):return d
   page.wait_for_timeout(200)
  raise AssertionError(d)
 def snap(name):page.screenshot(path='/tmp/perks-'+name+'.png')
 fixture(writejs)
 page.touchscreen.tap(273,798);page.wait_for_timeout(300);snap('locked')
 assert ocr('/tmp/perks-locked.png','11').lower().count('locked')==12,ocr('/tmp/perks-locked.png')
 started=time.monotonic()
 page.touchscreen.tap(195,737);page.wait_for_timeout(50);snap('unlock-back')
 page.touchscreen.tap(195,737) # Overlay must block repeated purchases.
 page.wait_for_timeout(max(0,(started+0.55-time.monotonic())*1000));snap('unlock-flip')
 page.wait_for_timeout(max(0,(started+1.5-time.monotonic())*1000));snap('unlock-front')
 page.wait_for_timeout(max(0,(started+3.8-time.monotonic())*1000));snap('unlocked-page')
 d=saved_when(lambda d:d['perk_purchases']==1)
 assert d['perks']['starting_upgrade']==1 and d['coins']==999750,d
 page.touchscreen.tap(73,146);page.wait_for_timeout(400);snap('touch-preview')
 assert 'choice' in ocr('/tmp/perks-touch-preview.png'),ocr('/tmp/perks-touch-preview.png')
 fixture(levelsjs)
 page.touchscreen.tap(273,798);page.wait_for_timeout(300);snap('high-ranks')
 price=250+sum(caps.values())*50
 started=time.monotonic()
 page.touchscreen.tap(195,737);page.wait_for_timeout(50);snap('merge-pair')
 page.wait_for_timeout(max(0,(started+1.95-time.monotonic())*1000));snap('merge-result')
 assert 'Starting HP +25' in ocr('/tmp/perks-merge-result.png'),ocr('/tmp/perks-merge-result.png')
 page.wait_for_timeout(max(0,(started+4.5-time.monotonic())*1000))
 d=saved_when(lambda d:d['perks']['starting_hp']==25)
 assert d['coins']==1000000-price and d['perk_purchases']==sum(caps.values())+1,d
 # Desktop layout and hover after the touch suppression period.
 page.set_viewport_size({'width':480,'height':800});page.wait_for_timeout(500)
 page.mouse.move(221,148);page.wait_for_timeout(400);snap('desktop-hover')
 assert 'Starting HP +25' in ocr('/tmp/perks-desktop-hover.png'),ocr('/tmp/perks-desktop-hover.png')
 page.mouse.move(475,70);page.wait_for_timeout(400);snap('maxed')
 assert 'All blessings fully empowered' in ocr('/tmp/perks-maxed.png'),ocr('/tmp/perks-maxed.png')
 assert not errors,errors
 print('PASS: twelve locked cards, touch preview, unlock flip, guarded purchase, 24+1 star merge, saved current effects, capped Obtain and desktop hover',flush=True)
 b.close()
server.shutdown()
