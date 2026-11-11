"""Render all six authored plans and verify the canal forces a real mobile crossing."""
import io,json,shutil
from pathlib import Path
from PIL import Image
from playwright.sync_api import sync_playwright
PLANS=[(0,6),(1,1),(2,9),(3,8),(4,2),(5,14)]
with sync_playwright() as p:
 browser=p.chromium.launch(executable_path=shutil.which('chromium'),headless=True,args=['--no-sandbox','--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader'])
 errors=[]
 for layout,seed in PLANS:
  context=browser.new_context(viewport={'width':390,'height':844},has_touch=True,is_mobile=True)
  page=context.new_page()
  page.on('pageerror',lambda e:errors.append(str(e)))
  page.on('console',lambda m:errors.append(m.text) if m.type=='error' else None)
  page.goto(f'http://127.0.0.1:8765/?seed={seed}',wait_until='networkidle');page.wait_for_timeout(3000)
  box=page.locator('canvas').bounding_box();scale=box['width']/480
  def tap(x,y):page.touchscreen.tap(box['x']+x*scale,box['y']+y*scale);page.wait_for_timeout(200)
  def hold(key,ms):page.keyboard.down(key);page.wait_for_timeout(ms);page.keyboard.up(key)
  def position():
   im=Image.open(io.BytesIO(page.screenshot())).convert('RGB');points=[]
   for y in range(120,490):
    for x in range(im.width):
     if all(abs(a-b)<3 for a,b in zip(im.getpixel((x,y)),(57,188,167))):points.append((x,y))
   assert points,'Player marker missing'
   return tuple(sum(pt[i] for pt in points)/len(points)/scale for i in [0,1])
  tap(240,540)
  page.screenshot(path=f'/tmp/architecture-{layout}.png')
  if layout==1:
   hold('a',900);hold('w',1500)
   x,y=position();assert 350<y<375,(x,y,'Player crossed water without bridge')
   for attempt in range(12):
    x,y=position()
    if abs(x-240)<5:break
    hold('d' if x<240 else 'a',min(150,max(15,abs(x-240)/185*1000)))
   hold('w',550)
   x,y=position();assert y<290,(x,y,'Player could not cross bridge')
   page.screenshot(path='/tmp/architecture-bridge-crossed.png')
  assert not errors,errors
  print(f'layout {layout} PASS',flush=True)
  context.close()
 browser.close()
 print(json.dumps({'result':'PASS','checks':['six rendered architectural plans','canal blocks walking','bridge allows crossing'],'errors':errors}))
