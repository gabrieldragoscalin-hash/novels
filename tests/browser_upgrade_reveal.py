"""Mobile upgrade-card regression. Requires Playwright, Chromium and tesseract.
Uses an isolated profile and the public cheat controls. Optional export-directory argument.
"""
import ast,csv,io,shutil,subprocess,time,sys
from pathlib import Path
from functools import partial
from threading import Thread
from http.server import SimpleHTTPRequestHandler,ThreadingHTTPServer
from playwright.sync_api import sync_playwright
source=ast.parse(Path(__file__).with_name('browser_smoke.py').read_text())
readjs=next(ast.literal_eval(n.value) for n in ast.walk(source) if isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='read_js' for t in n.targets))
class Quiet(SimpleHTTPRequestHandler):
 def log_message(self,*args):pass
server=ThreadingHTTPServer(('127.0.0.1',0),partial(Quiet,directory=sys.argv[1] if len(sys.argv)>1 else str(Path(__file__).resolve().parents[1]/'build/web')));Thread(target=server.serve_forever,daemon=True).start()
base=f'http://127.0.0.1:{server.server_port}/'
def text(path):return subprocess.check_output(['tesseract',path,'stdout','--psm','11'],stderr=subprocess.DEVNULL,text=True)
def word(path,needle):
 for mode in ['11','6']:
  data=subprocess.check_output(['tesseract',path,'stdout','--psm',mode,'tsv'],stderr=subprocess.DEVNULL,text=True)
  for r in csv.DictReader(io.StringIO(data),delimiter='\t'):
   if needle in r['text'].lower():return (float(r['left'])+float(r['width'])/2)/2,(float(r['top'])+float(r['height'])/2)/2
 return None
with sync_playwright() as p:
 b=p.chromium.launch(executable_path=shutil.which('chromium'),args=['--no-sandbox','--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader'])
 c=b.new_context(viewport={'width':390,'height':844},device_scale_factor=2,is_mobile=True,has_touch=True)
 page=c.new_page();errors=[];page.on('pageerror',lambda e:errors.append(str(e)));page.on('console',lambda m:errors.append(m.text) if m.type=='error' else None)
 page.goto(base+'?seed=9');page.wait_for_function("window.__dungeonReady === 'hub'",timeout=120000);page.wait_for_timeout(500)
 scale=390/480
 def tap(x,y):page.touchscreen.tap(x*scale,y*scale);page.wait_for_timeout(250)
 tap(300,500);page.wait_for_timeout(400);page.screenshot(path='/tmp/upgrades-room.png')
 tap(390,757)
 for _ in range(10):
  page.screenshot(path='/tmp/upgrades-cheats.png');pos=word('/tmp/upgrades-cheats.png','level-up')
  if pos:break
  page.mouse.move(190,400);page.mouse.wheel(0,350);page.wait_for_timeout(250)
 assert pos,text('/tmp/upgrades-cheats.png')
 page.touchscreen.tap(*pos);page.wait_for_timeout(200)
 # Close menu, then keep a finger held over a disabled card during the reveal.
 page.touchscreen.tap(195,60)
 client=c.new_cdp_session(page)
 client.send('Input.dispatchTouchEvent',{'type':'touchStart','touchPoints':[{'x':96*scale,'y':360*scale,'id':0}]})
 page.wait_for_timeout(650);page.screenshot(path='/tmp/upgrades-rolling.png')
 page.wait_for_timeout(1600)
 client.send('Input.dispatchTouchEvent',{'type':'touchEnd','touchPoints':[]});page.wait_for_timeout(250)
 page.screenshot(path='/tmp/upgrades-ready.png')
 t=text('/tmp/upgrades-ready.png');print('Ready-card screenshot captured',flush=True)
 assert 'COINS' not in t and 'paused' in t,t
 # Select the third upgrade; combat resumes without awarding currency.
 tap(384,360);page.wait_for_timeout(700)
 for _ in range(40):
  d=page.evaluate(readjs)
  if d and d['coins']==0:break
  page.wait_for_timeout(200)
 assert d['coins']==0,d
 page.screenshot(path='/tmp/upgrades-resumed.png')
 assert 'taking shape' not in text('/tmp/upgrades-resumed.png')
 assert not errors,errors
 print('PASS: mobile rolling cards, held-touch guard, visible dungeon, third upgrade selection, no currency reward and resume',flush=True)
 b.close()
server.shutdown()
