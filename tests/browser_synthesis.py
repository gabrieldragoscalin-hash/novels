"""Quick synthesis via touch, including Rare bases and persistent cascade results."""
import json,shutil,time
from pathlib import Path
from playwright.sync_api import sync_playwright
source=Path('tests/browser_smoke.py').read_text()
read_js=source.split('    read_js="""',1)[1].split('"""',1)[0]
write_js=source.split('    write_js="""',1)[1].split('"""',1)[0].replace("['bow','bow','bow','bow']","Array(64).fill('bow')")
with sync_playwright() as p:
 browser=p.chromium.launch(executable_path=shutil.which('chromium'),headless=True,args=['--no-sandbox','--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader'])
 page=browser.new_page(viewport={'width':390,'height':844},has_touch=True,is_mobile=True)
 errors=[]
 page.on('pageerror',lambda e:errors.append(str(e)))
 page.on('console',lambda m:errors.append(m.text) if m.type=='error' else None)
 url='http://127.0.0.1:8765/?seed=9'
 page.goto(url,wait_until='networkidle');page.wait_for_timeout(3500)
 for attempt in range(40):
  if page.evaluate(read_js):break
  page.wait_for_timeout(200)
 page.route('**/__fixture.html',lambda route:route.fulfill(status=200,body='<html>fixture</html>',content_type='text/html'))
 page.goto('http://127.0.0.1:8765/__fixture.html');page.evaluate(write_js)
 page.goto(url,wait_until='networkidle');page.wait_for_timeout(3500)
 box=page.locator('canvas').bounding_box();scale=box['width']/480;h=box['height']/scale
 def tap(x,y):page.touchscreen.tap(box['x']+x*scale,box['y']+y*scale);page.wait_for_timeout(200)
 tap(146,h-56);tap(378,121);tap(240,530)
 for attempt in range(40):
  profile=page.evaluate(read_js)
  if len(profile['inventory'])==1:break
  page.wait_for_timeout(200)
 assert len(profile['inventory'])==1 and profile['inventory']['fixture_0']['rarity']==3,profile
 assert profile['equipped']['weapon']=='fixture_0'
 page.screenshot(path='/tmp/quick-synthesis-result.png')
 page.reload(wait_until='networkidle');page.wait_for_timeout(3500)
 assert page.evaluate(read_js)['inventory']['fixture_0']['rarity']==3
 assert not errors,errors
 print(json.dumps({'result':'PASS','checks':['touch quick synthesis','64 common to one epic','equipped base retained','reload persistence'],'errors':errors}))
 browser.close()
