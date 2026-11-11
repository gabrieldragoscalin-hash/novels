"""Full-reset confirmation: cancel preserves grants, confirm persists a fresh profile."""
import json,shutil
from pathlib import Path
from playwright.sync_api import sync_playwright
source=Path('tests/browser_smoke.py').read_text();read_js=source.split('    read_js="""',1)[1].split('"""',1)[0]
with sync_playwright() as p:
 browser=p.chromium.launch(executable_path=shutil.which('chromium'),headless=True,args=['--no-sandbox','--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader'])
 page=browser.new_page(viewport={'width':390,'height':844},has_touch=True,is_mobile=True);errors=[]
 page.on('pageerror',lambda e:errors.append(str(e)))
 page.on('console',lambda m:errors.append(m.text) if m.type=='error' else None)
 page.goto('http://127.0.0.1:8765/?seed=9',wait_until='networkidle');page.wait_for_timeout(3500)
 box=page.locator('canvas').bounding_box();scale=box['width']/480;h=box['height']/scale
 def tap(x,y):page.touchscreen.tap(box['x']+x*scale,box['y']+y*scale);page.wait_for_timeout(220)
 def saved(predicate):
  for _ in range(40):
   value=page.evaluate(read_js)
   if value and predicate(value):return value
   page.wait_for_timeout(200)
  raise AssertionError(value)
 tap(434,h-56);tap(240,434);tap(240,240)
 saved(lambda d:d['coins']==10000)
 page.mouse.move(250,650);page.mouse.wheel(0,4000);page.wait_for_timeout(300)
 tap(240,h-44);page.screenshot(path='/tmp/reset-confirmation.png')
 tap(150,h/2+65);page.wait_for_timeout(200)
 assert page.evaluate(read_js)['coins']==10000
 tap(240,h-44);tap(330,h/2+65)
 saved(lambda d:d['coins']==0 and d['highest_floor']==0 and len(d['inventory'])==1)
 page.screenshot(path='/tmp/reset-fresh-profile.png')
 page.reload(wait_until='networkidle');page.wait_for_timeout(3500)
 assert page.evaluate(read_js)['coins']==0
 assert not errors,errors
 print(json.dumps({'result':'PASS','checks':['reset confirmation','cancel preserves progress','confirm clears profile','reload persistence'],'errors':errors}))
 browser.close()
