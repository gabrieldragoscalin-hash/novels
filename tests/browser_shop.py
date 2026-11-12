"""Mobile shop regression with isolated profile and a local HTTP server.
Requires Playwright, Chromium and tesseract. Optional argument: export directory.
"""
import ast,csv,io,shutil,subprocess,sys
from pathlib import Path
from playwright.sync_api import sync_playwright
source=ast.parse(Path(__file__).with_name('browser_smoke.py').read_text())
readjs=next(ast.literal_eval(n.value) for n in ast.walk(source) if isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='read_js' for t in n.targets))
writejs=next(ast.literal_eval(n.value) for n in ast.walk(source) if isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='write_js' for t in n.targets))
writejs=writejs.replace('d.gems=1000','d.gems=10000').replace('copper:1,silver:1,gold:1','copper:0,silver:10,gold:9')
from http.server import SimpleHTTPRequestHandler,ThreadingHTTPServer
from functools import partial
from threading import Thread
class QuietHandler(SimpleHTTPRequestHandler):
 def log_message(self,*args):pass
server=ThreadingHTTPServer(('127.0.0.1',0),partial(QuietHandler,directory=sys.argv[1] if len(sys.argv)>1 else str(Path(__file__).resolve().parents[1]/'build/web')))
Thread(target=server.serve_forever,daemon=True).start()
base=f'http://127.0.0.1:{server.server_port}/' 
def text(path):return subprocess.check_output(['tesseract',path,'stdout'],stderr=subprocess.DEVNULL,text=True)
def word_center(path,word):
 for mode in ['3','6']:
  data=subprocess.check_output(['tesseract',path,'stdout','--psm',mode,'tsv'],stderr=subprocess.DEVNULL,text=True)
  for r in csv.DictReader(io.StringIO(data),delimiter='\t'):
   if word in r['text']:return float(r['left'])+float(r['width'])/2,float(r['top'])+float(r['height'])/2
 raise AssertionError((word,text(path)))
with sync_playwright() as p:
 b=p.chromium.launch(executable_path=shutil.which('chromium'),args=['--no-sandbox','--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader'])
 c=b.new_context(viewport={'width':390,'height':844},device_scale_factor=2,is_mobile=True,has_touch=True)
 page=c.new_page();errors=[]
 page.on('pageerror',lambda e:errors.append(str(e)))
 page.on('console',lambda m:errors.append(m.text) if m.type=='error' else None)
 page.goto(base);page.wait_for_function("window.__dungeonReady === 'hub'",timeout=120000);page.wait_for_timeout(1200)
 page.route('**/__fixture.html',lambda r:r.fulfill(body='<html></html>',content_type='text/html'))
 page.goto(base+'__fixture.html');page.evaluate(writejs)
 page.goto(base);page.wait_for_function("window.__dungeonReady === 'hub'",timeout=120000);page.wait_for_timeout(600)
 page.touchscreen.tap(40,790);page.wait_for_timeout(400);page.screenshot(path='/tmp/shop-mobile-top.png')
 # Drag across the chest area; this must not purchase anything.
 before=page.evaluate(readjs)
 client=c.new_cdp_session(page)
 client.send('Input.dispatchTouchEvent',{'type':'touchStart','touchPoints':[{'x':180,'y':650,'id':0}]})
 for y in range(630,340,-20):
  client.send('Input.dispatchTouchEvent',{'type':'touchMove','touchPoints':[{'x':180,'y':y,'id':0}]});page.wait_for_timeout(40)
 client.send('Input.dispatchTouchEvent',{'type':'touchEnd','touchPoints':[]});page.wait_for_timeout(700)
 after=page.evaluate(readjs);assert after['keys']==before['keys'] and after['gems']==before['gems'] and after['inventory']==before['inventory']
 page.screenshot(path='/tmp/shop-mobile-chests.png');print('Chest panels captured',flush=True)
 def saved_when(predicate):
  for _ in range(50):
   saved=page.evaluate(readjs)
   if saved and predicate(saved):return saved
   page.wait_for_timeout(200)
  raise AssertionError(('Profile did not reach expected state',saved))
 # Gold ten-opening uses gems and leaves all nine keys untouched.
 page.touchscreen.tap(*(v/2 for v in word_center('/tmp/shop-mobile-chests.png','2700')));page.wait_for_timeout(1800)
 after=saved_when(lambda d:d['gems']==7300 and len(d['inventory'])==14)
 assert after['gems']==7300 and after['keys']['gold']==9 and len(after['inventory'])==14,after
 page.screenshot(path='/tmp/shop-mobile-rewards.png')
 # Go back to the chests and use Silver's ten keys, leaving gems unchanged.
 page.mouse.move(180,250);page.mouse.wheel(0,-250);page.wait_for_timeout(600)
 page.mouse.wheel(0,80);page.wait_for_timeout(300)
 page.screenshot(path='/tmp/shop-mobile-return.png')
 print('Checking Silver ten-key button',flush=True)
 point=tuple(v/2 for v in word_center('/tmp/shop-mobile-return.png','keys'));print('silver tap',point,flush=True)
 page.touchscreen.tap(*point);page.wait_for_timeout(1800)
 page.screenshot(path='/tmp/shop-after-silver-tap.png')
 after=saved_when(lambda d:d['keys']['silver']==0 and len(d['inventory'])==24)
 assert after['keys']['silver']==0 and after['gems']==7300 and len(after['inventory'])==24,after
 page.screenshot(path='/tmp/shop-mobile-silver-rewards.png')
 print('PASS: actual touch swiping is safe; gold ten-gem and silver ten-key purchases saved all twenty rewards with correct balances; no errors:',errors,flush=True)
 assert not errors
 b.close()
server.shutdown()
