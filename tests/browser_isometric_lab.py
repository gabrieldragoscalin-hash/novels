"""Render and exercise the actual 3D camera prototype in the web export."""
import argparse, ast, json, shutil, threading
from pathlib import Path
from functools import partial
from http.server import ThreadingHTTPServer, SimpleHTTPRequestHandler
from playwright.sync_api import sync_playwright
parser=argparse.ArgumentParser(); parser.add_argument('--directory',default='build/web');parser.add_argument('--views',default='phone,compact,desktop');args=parser.parse_args()
class Quiet(SimpleHTTPRequestHandler):
 def log_message(self,*args):pass
server=ThreadingHTTPServer(('127.0.0.1',0),partial(Quiet,directory=args.directory));threading.Thread(target=server.serve_forever,daemon=True).start()
base=f'http://127.0.0.1:{server.server_port}/'
source=ast.parse(Path('tests/browser_smoke.py').read_text())
readjs=next(ast.literal_eval(n.value) for n in ast.walk(source) if isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='read_js' for t in n.targets))
out=Path('build/isometric-checks');out.mkdir(parents=True,exist_ok=True)
try:
 with sync_playwright() as p:
  browser=p.chromium.launch(executable_path=shutil.which('chromium'),args=['--no-sandbox','--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader'])
  for name,width,height in [('phone',390,844),('compact',390,640),('desktop',1100,900)]:
   if name not in args.views.split(','):continue
   context=browser.new_context(viewport={'width':width,'height':height},has_touch=True,is_mobile=name!='desktop');page=context.new_page();errors=[]
   page.on('pageerror',lambda e:errors.append(str(e)));page.on('console',lambda m:errors.append(m.text) if m.type=='error' else None)
   page.goto(base+'?iso_lab=1&iso_probe=1',wait_until='domcontentloaded');page.wait_for_function("window.__dungeonReady==='iso-lab' && window.__isoSnapshot",timeout=120000);page.wait_for_timeout(2000)
   box=page.locator('canvas').bounding_box();scale=min(box['width']/480,box['height']/800);offset=(box['width']/scale-480)/2;h=box['height']/scale
   def pt(x,y):return {'x':box['x']+(offset+x)*scale,'y':box['y']+y*scale}
   def tap(x,y):page.touchscreen.tap(**pt(x,y));page.wait_for_timeout(450)
   def state():return page.evaluate('window.__isoSnapshot')
   def snap(tag):page.screenshot(path=str(out/f'{name}-{tag}.png'))
   before=None
   for _ in range(30):
    before=page.evaluate(readjs)
    if before:break
    page.wait_for_timeout(200)
   assert before
   snap('follow');assert state()['orthographic'] and state()['alive']==3
   print(name,'render snapshot',json.dumps(state()),flush=True)
   tap(70,h-128);page.wait_for_function('window.__isoSnapshot.overview');snap('overview')
   tap(183,h-128);page.wait_for_function('window.__isoSnapshot.low_angle');snap('lower-angle')
   tap(296,h-128);page.wait_for_function("window.__isoSnapshot.weapon==='spear'");snap('spear')
   tap(409,h-128);page.wait_for_function('!window.__isoSnapshot.shadows');snap('simple-light')
   tap(70,h-128);page.wait_for_function('!window.__isoSnapshot.overview')
   if name=='phone':
    client=context.new_cdp_session(page);initial=state()
    first={**pt(160,460),'id':7};moved={**pt(220,460),'id':7};second={**pt(89,h-80),'id':8}
    client.send('Input.dispatchTouchEvent',{'type':'touchStart','touchPoints':[first]})
    client.send('Input.dispatchTouchEvent',{'type':'touchMove','touchPoints':[moved]})
    page.wait_for_timeout(250)
    client.send('Input.dispatchTouchEvent',{'type':'touchStart','touchPoints':[moved,second]})
    page.wait_for_timeout(450);client.send('Input.dispatchTouchEvent',{'type':'touchEnd','touchPoints':[]});page.wait_for_timeout(400)
    after=state();assert sum((a-b)**2 for a,b in zip(initial['player'],after['player']))>0.5,(initial,after)
    assert after['attack_cycle']>initial['attack_cycle'],'Second-finger attack did not trigger'
    assert after['pointer']==-1
    snap('move-and-attack')
   tap(240,h-80);tap(390,h-80);snap('reset')
   tap(425,28);page.wait_for_function("window.__dungeonReady==='hub'",timeout=30000)
   assert page.evaluate("new URLSearchParams(location.search).get('iso_lab')") is None
   saved=page.evaluate(readjs)
   for field in ['coins','gems','keys','parts','inventory','perks','highest_floor']:assert saved[field]==before[field],field
   assert not errors,errors
   print(name,'PASS: actual 3D rendering, orthographic/angle/overview controls, modular weapons, lighting, multi-touch and account isolation',flush=True)
   context.close()
  browser.close()
finally:server.shutdown()
