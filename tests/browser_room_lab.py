"""Exercise the isolated route sandbox in the real exported browser game."""
import argparse, ast, json, shutil, threading
from pathlib import Path
from functools import partial
from http.server import ThreadingHTTPServer, SimpleHTTPRequestHandler
from playwright.sync_api import sync_playwright
parser=argparse.ArgumentParser(); parser.add_argument('--directory',default='build/web'); args=parser.parse_args()
class Quiet(SimpleHTTPRequestHandler):
 def log_message(self,*args): pass
server=ThreadingHTTPServer(('127.0.0.1',0),partial(Quiet,directory=args.directory))
threading.Thread(target=server.serve_forever,daemon=True).start()
base=f'http://127.0.0.1:{server.server_port}/'
source=ast.parse(Path('tests/browser_smoke.py').read_text())
readjs=next(ast.literal_eval(n.value) for n in ast.walk(source) if isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='read_js' for t in n.targets))
out=Path('build/room-lab-checks'); out.mkdir(parents=True,exist_ok=True)
try:
 with sync_playwright() as p:
  browser=p.chromium.launch(executable_path=shutil.which('chromium'),args=['--no-sandbox','--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader'])
  for name,width,height in [('phone',390,844),('compact',390,640),('desktop',1100,900)]:
   context=browser.new_context(viewport={'width':width,'height':height},has_touch=True,is_mobile=name!='desktop')
   page=context.new_page(); errors=[]
   page.on('pageerror',lambda e: errors.append(str(e)))
   page.on('console',lambda m: errors.append(m.text) if m.type=='error' else None)
   page.goto(base+'?room_lab=1&lab_probe=1',wait_until='domcontentloaded')
   page.wait_for_function("window.__dungeonReady === 'room-lab' && window.__roomLabSnapshot",timeout=120000)
   box=page.locator('canvas').bounding_box(); scale=min(box['width']/480,box['height']/800); offset=(box['width']/scale-480)/2; logical_h=box['height']/scale
   def pt(x,y): return {'x':box['x']+(offset+x)*scale,'y':box['y']+y*scale}
   def tap(x,y): page.touchscreen.tap(**pt(x,y)); page.wait_for_timeout(300)
   def state(): return page.evaluate('window.__roomLabSnapshot')
   def snap(tag): page.screenshot(path=str(out/f'{name}-{tag}.png'))
   before=None
   for _ in range(30):
    before=page.evaluate(readjs)
    if before: break
    page.wait_for_timeout(200)
   assert before, 'Initial account save did not synchronize' 
   snap('play'); assert state()['total']==24
   tap(70,logical_h-115)
   assert state()['overview']
   for index in range(3):
    assert state()['layout']==index
    snap(f'layout-{index}-map')
    tap(380,113)
   tap(70,logical_h-115); assert not state()['overview']
   # Two independently placed floating-stick drags, including release over the HUD.
   if name=='phone':
    tap(85,logical_h-70) # Invincibility makes input tests independent of damage RNG.
    client=context.new_cdp_session(page)
    def drag(start,end,milliseconds):
     client.send('Input.dispatchTouchEvent',{'type':'touchStart','touchPoints':[{**pt(*start),'id':7}]})
     client.send('Input.dispatchTouchEvent',{'type':'touchMove','touchPoints':[{**pt(*end),'id':7}]})
     page.wait_for_timeout(milliseconds)
     client.send('Input.dispatchTouchEvent',{'type':'touchEnd','touchPoints':[]})
     page.wait_for_timeout(300)
    initial=state()
    drag((180,400),(100,400),1050)
    moved=state(); assert moved['player'][0]<initial['player'][0]-80,(initial,moved)
    assert moved['player'][0]>=515,'Player crossed the court edge into void'
    drag((245,600),(245,515),550)
    moved2=state(); assert moved2['player'][1]<moved['player'][1]-50
    assert abs(moved2['camera'][0]-initial['camera'][0])>40
    assert moved2['pointer']==-1
    snap('moved')
   tap(412,logical_h-115) # Reset, including all temporary upgrades.
   tap(240,logical_h-70); assert state()['total']==36
   snap('crowded')
   tap(390,logical_h-70); page.wait_for_timeout(1500)
   offered=state()['offered']; assert len(offered)==3 and 'coins' not in offered and len(set(offered))==3
   snap('three-upgrades'); chosen=offered[2]
   tap(384,360); page.wait_for_timeout(350)
   assert state()['ranks'][chosen]==1
   tap(425,28); page.wait_for_function("window.__dungeonReady === 'hub'",timeout=30000)
   assert page.evaluate("new URLSearchParams(location.search).get('room_lab')") is None
   after=page.evaluate(readjs)
   for field in ['coins','gems','keys','parts','inventory','perks','highest_floor']:
    assert before[field]==after[field],(field,before[field],after[field])
   assert not errors,errors
   print(name, 'PASS: layouts, 24/36 enemies, three upgrade choices, hub return and unchanged account',flush=True)
   context.close()
  browser.close()
finally: server.shutdown()
