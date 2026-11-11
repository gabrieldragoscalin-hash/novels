"""Select floor 10 through Cheats, fight its boss, and verify victory/gold-key persistence."""
import json,shutil
from pathlib import Path
from playwright.sync_api import sync_playwright
source=Path('tests/browser_smoke.py').read_text()
read_js=source.split('    read_js="""',1)[1].split('"""',1)[0]
with sync_playwright() as p:
 browser=p.chromium.launch(executable_path=shutil.which('chromium'),headless=True,args=['--no-sandbox','--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader'])
 page=browser.new_page(viewport={'width':390,'height':844},has_touch=True,is_mobile=True)
 errors=[]
 page.on('pageerror',lambda e:errors.append(str(e)))
 page.on('console',lambda m:errors.append(m.text) if m.type=='error' else None)
 page.goto('http://127.0.0.1:8765/?seed=9',wait_until='networkidle');page.wait_for_timeout(3500)
 box=page.locator('canvas').bounding_box();scale=box['width']/480;h=box['height']/scale
 def tap(x,y):page.touchscreen.tap(box['x']+x*scale,box['y']+y*scale);page.wait_for_timeout(180)
 def bottom():
  page.mouse.move(250,650);page.mouse.wheel(0,4000);page.wait_for_timeout(250)
 tap(434,h-56);tap(240,434)
 tap(240,984);tap(160,1020) # Select floor 10 from the visible popup.
 bottom();tap(240,343);page.wait_for_timeout(350)
 page.screenshot(path='/tmp/balance-floor-five-start.png')
 tap(390,756);bottom()
 tap(240,h-133) # Teleport to boss.
 page.wait_for_timeout(2200);page.screenshot(path='/tmp/balance-floor-five-spread.png')
 tap(390,756);bottom();tap(240,h-509) # God mode, positioned above current-run controls.
 page.screenshot(path='/tmp/balance-cheats-bottom.png')
 tap(240,76);page.wait_for_timeout(5500);page.screenshot(path='/tmp/balance-floor-five-patterns.png')
 tap(390,756);bottom();tap(240,h-283) # Defeat current enemies, normal rewards.
 for attempt in range(40):
  profile=page.evaluate(read_js)
  if profile and profile['keys']['gold']==2:break
  page.wait_for_timeout(200)
 assert profile and profile['keys']['gold']==2 and profile['highest_floor']==10,profile
 tap(240,76);tap(240,498);tap(240,682)
 page.screenshot(path='/tmp/balance-five-floor-victory.png')
 page.reload(wait_until='networkidle');page.wait_for_timeout(3500)
 profile=page.evaluate(read_js)
 assert profile['keys']['gold']==2 and profile['highest_floor']==10
 assert not errors,errors
 print(json.dumps({'result':'PASS','checks':['floor-10 cheat selector','boss teleports/pattern rendering','floor-10 gold clear reward','floor-10 finish','persistent highest floor and key'],'errors':errors}))
 browser.close()
